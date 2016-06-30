//
//  AdBlockPlusExtras.swift
//  AdBlockPlus
//
//  Created by William Kent on 6/29/16.
//  Copyright © 2016 William Kent. All rights reserved.
//

import Foundation
import AdBlockKit
import SafariServices

private func keysArray<K: Hashable,V>(dict: [K: V]) -> [K] {
	var keys: [K] = []
	for (key, _) in dict { keys.append(key) }
	return keys
}

private func valuesArray<K: Hashable, V>(dict: [K: V]) -> [V] {
	var values: [V] = []
	for (_, val) in dict { values.append(val) }
	return values
}

// Due to an Xcode bug, adding a "-" here results in two separators being added
// to the navigation menu. Please keep this line as it is. Radar 27095772.
// MARK:

private let ABPNeedsDisplayErrorDialogDefaultsKey = "ABPNeedsDisplayErrorDialog"
class AdBlockPlusExtras: AdBlockPlus, URLSessionDownloadDelegate, FileManagerDelegate {
	override init() {
		super.init()

		let configuration = URLSessionConfiguration.background(withIdentifier: self.backgroundSessionConfigurationIdentifier)
		backgroundSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main())
		needsDisplayError = adBlockPlusDetails.bool(forKey: ABPNeedsDisplayErrorDialogDefaultsKey)

		backgroundSession?.getAllTasks(completionHandler: {
			[weak self] (tasks) in
			if let this = self {
				var set = Set(keysArray(dict: this.downloadTasks))

				// remove filter lists whose tasks are still running
				for task: URLSessionTask in tasks {
					let filterListName_orig = task.originalRequest?.url?.absoluteString
					guard let filterListName = filterListName_orig else {
						fatalError("Could not extract URL from URLSessionTask '\(task)'")
					}
					set.remove(filterListName)

					if let listDict = this.filterLists[filterListName], ident = listDict["taskIdentifier"] where (ident as! Int) == task.taskIdentifier {
						this.downloadTasks[filterListName] = task
					} else {
						task.cancel()
					}
				}

				// Remove filter lists whose tasks have been planned again
				for (filterListName, _) in this.downloadTasks {
					set.remove(filterListName)
				}

				if set.count > 0 {
					var filterLists = this.filterLists
					for key in set {
						var filterList = filterLists[key]!
						filterList["updating"] = false
						filterLists[key] = filterLists
					}
					this.filterLists = filterLists
				}
			}
		})
	}

	// MARK: Properties

	private weak var backgroundSession: URLSession?
	private var downloadTasks: [String: URLSessionTask] = [:]
	var reloading = false

	private var needsDisplayError = false {
		didSet {
			adBlockPlusDetails.set(needsDisplayError, forKey: ABPNeedsDisplayErrorDialogDefaultsKey)
		}
	}


	@objc var updating: Bool {
		get {
			let values = valuesArray(dict: downloadTasks) as NSArray

			if let updatingObj = values.value(forKeyPath: "@sum.updating"), updating = updatingObj as? NSNumber {
				return updating.intValue > 0
			} else {
				return false
			}
		}
	}

	@objc var lastUpdate: Date? {
		get {
			let values = valuesArray(dict: downloadTasks) as NSArray
			if let date = values.value(forKeyPath: "@min.lastUpdate") {
				// This seemingly spurious value silences a Swift compiler warning.
				let date = date as! Date
				return date
			} else {
				return nil
			}
		}
	}

	private var anyLastUpdateFailed: Bool {
		get {
			let values = valuesArray(dict: filterLists) as NSArray
			if let sumObj = values.value(forKeyPath: "@sum.lastUpdateFailed"), sum = sumObj as? NSNumber {
				return sum.intValue > 0
			} else {
				return false
			}
		}
	}

	override var filterLists: [String : [String : AnyObject]] {
		get {
			return super.filterLists
		}

		set {
			let wasUpdating = self.updating
			let hasAnyLastUpdateFailed = self.anyLastUpdateFailed

			willChangeValue(forKey: "lastUpdate")
			willChangeValue(forKey: "updating")
			super.filterLists = newValue
			didChangeValue(forKey: "lastUpdate")
			didChangeValue(forKey: "updating")

			let updating = self.updating
			let anyLastUpdateFailed = self.anyLastUpdateFailed

			if installedVersion < downloadedVersion && wasUpdating && !updating {
				// Force the content blocker to reload the newer version of the filter lists
				reloadContentBlocker(completion: nil)
			}

			if hasAnyLastUpdateFailed != anyLastUpdateFailed {
				needsDisplayError = anyLastUpdateFailed
				displayErrorDialogIfNeeded()
			}
		}
	}

	override var whitelistedWebsites: [String] {
		didSet {
			reloadContentBlocker(completion: nil)
		}
	}

	// MARK: Methods

	func reloadContentBlocker(completion: ((NSError?) -> ())?) {
		reloading = true

		SFContentBlockerManager.reloadContentBlocker(withIdentifier: contentBlockerIdentifier) {
			[weak self] (error) in
			self?.reloading = false
			self?.checkActivatedFlag()
			completion?(error)
		}
	}

	func checkActivatedFlag() {
		let flag = adBlockPlusDetails.bool(forKey: ABPActivatedDefaultsKey)
		if activated != flag {
			activated = flag
		}
	}

	func updateFilterLists(userTriggered: Bool) {
		guard let backgroundSession = self.backgroundSession else {
			if userTriggered {
				// TODO: Present error here.
			}

			return
		}

		var filterLists = self.filterLists
		for (filterListName, _) in filterLists {
			let URL = Foundation.URL(string: filterListName)!
			let task = backgroundSession.downloadTask(with: URL)

			var filterList = filterLists[filterListName] ?? [:]
			filterList["updating"] = true
			filterList["taskIdentifier"] = task.taskIdentifier
			filterList["userTriggered"] = userTriggered
			filterList["lastUpdateFailed"] = false
			filterLists[filterListName] = filterList

			downloadTasks[filterListName]?.cancel()
			downloadTasks[filterListName] = task
			task.resume()
		}
		self.filterLists = filterLists
	}

	func displayErrorDialogIfNeeded() {
		if !needsDisplayError {
			return
		}

		// Do not show the message if the update was automatically triggered.
		let values = valuesArray(dict: filterLists) as NSArray
		if let sum = values.value(forKey: "@sum.userTriggered") as? NSNumber where sum.intValue == 0 {
			return
		}

		let errorInfo = [
			NSLocalizedDescriptionKey: localize("Failed to update filter lists.", "Localizable"),
			NSLocalizedRecoverySuggestionErrorKey: localize("Please try again later.", "Localizable")
		]

		var note = Notification(name: ABPDisplayErrorNotification)
		note.userInfo = [ "error": NSError(domain: "ABPApplicationErrorDomain", code: 1, userInfo: errorInfo) ]
		note.post()
		needsDisplayError = false
	}

	// MARK: URLSessionDownloadDelegate

	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: NSError?) {
		guard let filterListName = task.originalRequest?.url?.absoluteString else { return }
		guard var filterList = self.filterLists[filterListName] else { return }

		if let taskIdObj = filterList["taskIdentifier"], taskId = taskIdObj as? Int where taskId == task.taskIdentifier {
			if let updatingObj = filterList["updating"], updating = updatingObj	as? Bool where updating {
				filterList["updating"] = false
				filterList["lastUpdateFailed"] = true
				filterList.removeValue(forKey: "taskIdentifier")

				var filterLists = self.filterLists
				filterLists[filterListName] = filterList
				self.filterLists = filterLists

				downloadTasks.removeValue(forKey: filterListName)
			}
		}
	}

	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		guard let filterListName = downloadTask.originalRequest?.url?.absoluteString else { return }
		guard var filterList = self.filterLists[filterListName] else { return }

		if let taskIdObj = filterList["taskIdentifier"], taskId = taskIdObj as? Int where taskId == downloadTask.taskIdentifier {
			if let response = downloadTask.response as? HTTPURLResponse {
				if response.statusCode < 200 || response.statusCode > 300 {
					let desc = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
					NSLog("Remote server returned HTTP \(response.statusCode) \(desc)")
					return
				}

				let fileManager = FileManager()
				fileManager.delegate = self

				do {
					guard var destination = fileManager.containerURLForSecurityApplicationGroupIdentifier(AdBlockPlus.applicationGroup) else { return }
					try destination.appendPathComponent(filterList["filename"] as! String)
					
					try fileManager.moveItem(at: location, to: destination)
				} catch {
					NSLog("Could not move downloaded file: \(error)")
				}

				filterList["lastUpdate"] = Date()
				filterList["downloaded"] = true
				filterList["updating"] = false
				filterList["lastUpdateFailed"] = false
				filterList.removeValue(forKey: "taskIdentifier")

				downloadedVersion += 1

				var filterLists = self.filterLists
				filterLists[filterListName] = filterList
				self.filterLists = filterLists
			} else {
				// This error occurs in rare cases. The error message is meaningless to the ordinary user.
				NSLog("Downloading has failed: \(downloadTask.error)")
				return
			}
		}
	}

	// MARK: FileManagerDelegate

	func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: NSError, movingItemAt srcURL: URL, to dstURL: URL) -> Bool {
		if error.code == NSFileWriteFileExistsError {
			return true
		} else {
			return false
		}
	}
}
