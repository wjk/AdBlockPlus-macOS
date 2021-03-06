//
// This file is part of Adblock Plus <https://adblockplus.org/>,
// Copyright (C) 2006-2016 Eyeo GmbH
//
// Adblock Plus is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License version 3 as
// published by the Free Software Foundation.
//
// Adblock Plus is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Adblock Plus.  If not, see <http://www.gnu.org/licenses/>.
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

// MARK: -

private let ABPNeedsDisplayErrorDialogDefaultsKey = "ABPNeedsDisplayErrorDialog"
class AdBlockPlusExtras: AdBlockPlus, URLSessionDownloadDelegate, FileManagerDelegate {
	override init() {
		super.init()

		let configuration = URLSessionConfiguration.background(withIdentifier: self.backgroundSessionConfigurationIdentifier)
		backgroundSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
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

					if let listDict = this.filterLists[filterListName], let ident = listDict["taskIdentifier"] , (ident as! Int) == task.taskIdentifier {
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
			let values = valuesArray(dict: filterLists) as NSArray

			if let updatingObj = values.value(forKeyPath: "@sum.updating"), let updating = updatingObj as? NSNumber {
				return updating.intValue > 0
			} else {
				return false
			}
		}
	}

	@objc var lastUpdate: Date? {
		get {
			let values = valuesArray(dict: filterLists) as NSArray
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
			if let sumObj = values.value(forKeyPath: "@sum.lastUpdateFailed"), let sum = sumObj as? NSNumber {
				return sum.intValue > 0
			} else {
				return false
			}
		}
	}

	override var enabled: Bool {
		didSet {
			reloadContentBlocker {
				(error) in
				if let error = error {
					NSLog("Could not reload content blocker extension: '\(error)'")
				}
			}
		}
	}

	private var _filterListUpdateCallback: (() -> ())?
	override var filterLists: [String : [String : Any]] {
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
				reloadContentBlocker(completion: {
					[weak self] (error) in
					if let error = error {
						var note = Notification(name: ABPDisplayErrorNotification)
						note.userInfo = [ "error": error ]
						note.post()
					} else {
						if let callback = self?._filterListUpdateCallback {
							callback()
						}
						self?._filterListUpdateCallback = nil
					}
				})
			}

			if hasAnyLastUpdateFailed != anyLastUpdateFailed {
				needsDisplayError = anyLastUpdateFailed
				displayErrorDialogIfNeeded()
			}
		}
	}

	override var whitelistedWebsites: [String] {
		didSet {
			reloadContentBlocker(completion: {
				(error) in
				if let error = error {
					var note = Notification(name: ABPDisplayErrorNotification)
					note.userInfo = [ "error": error ]
					note.post()
				}
			})
		}
	}

	// Don't remove these seemingly pointless property definitions;
	// they prevent the Swift compiler from causing linker errors.

	override var adBlockPlusDetails: UserDefaults {
		get {
			return super.adBlockPlusDetails
		}
	}

	override var installedVersion: Int {
		get {
			return super.installedVersion
		}

		set {
			super.installedVersion = newValue
		}
	}

	override var downloadedVersion: Int {
		get {
			return super.downloadedVersion
		}

		set {
			super.downloadedVersion = newValue
		}
	}

	override var acceptableAdsEnabled: Bool {
		get {
			return super.acceptableAdsEnabled
		}

		set {
			super.acceptableAdsEnabled = newValue
		}
	}

	override var activated: Bool {
		get {
			return super.activated
		}

		set {
			super.activated = newValue
		}
	}

	// MARK: Methods

	func reloadContentBlocker(completion: ((NSError?) -> ())?) {
		reloading = true

		SFContentBlockerManager.reloadContentBlocker(withIdentifier: contentBlockerIdentifier) {
			[weak self] (error) in
			self?.reloading = false
			self?.checkActivatedFlag()
			completion?(error as NSError?)
		}
	}

	func checkActivatedFlag() {
		let flag = adBlockPlusDetails.bool(forKey: ABPActivatedDefaultsKey)
		if activated != flag {
			activated = flag
		}
	}

	func updateFilterLists(userTriggered: Bool, completion: (() -> ())? = nil) {
		guard let backgroundSession = self.backgroundSession else {
			if userTriggered {
				needsDisplayError = true
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

		_filterListUpdateCallback = completion
		self.filterLists = filterLists
	}

	func displayErrorDialogIfNeeded() {
		if !needsDisplayError {
			return
		}

		// Do not show the message if the update was automatically triggered.
		let values = valuesArray(dict: filterLists) as NSArray
		if let sum = values.value(forKey: "@sum.userTriggered") as? NSNumber , sum.intValue == 0 {
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

	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		guard let filterListName = task.originalRequest?.url?.absoluteString else { return }
		guard var filterList = self.filterLists[filterListName] else { return }

		if let taskIdObj = filterList["taskIdentifier"], let taskId = taskIdObj as? Int , taskId == task.taskIdentifier {
			if let updatingObj = filterList["updating"], let updating = updatingObj	as? Bool , updating {
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

		if let taskIdObj = filterList["taskIdentifier"], let taskId = taskIdObj as? Int , taskId == downloadTask.taskIdentifier {
			if let response = downloadTask.response as? HTTPURLResponse {
				if response.statusCode < 200 || response.statusCode > 300 {
					let desc = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
					NSLog("Remote server returned HTTP \(response.statusCode) \(desc)")
					return
				}

				let fileManager = FileManager()
				fileManager.delegate = self

				do {
					guard var destination = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AdBlockPlus.applicationGroup) else { return }
					destination.appendPathComponent("Library")
					destination.appendPathComponent("AdBlockPlus Filter Lists")
					destination.appendPathComponent(filterList["filename"] as! String)
					
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

	func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, movingItemAt srcURL: URL, to dstURL: URL) -> Bool {
		let error = error as NSError
		if error.code == NSFileWriteFileExistsError {
			return true
		} else {
			return false
		}
	}
}
