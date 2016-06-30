//
//  ViewController.swift
//  AdBlockPlus
//
//  Created by William Kent on 6/14/16.
//  Copyright © 2016 William Kent. All rights reserved.
//

import Cocoa

// This notification is observed by the main window controller. It will create an NSAlert
// object from the NSError object kept within the notification's userInfo dictionary
// (key = "error") and display it as it sees fit.
internal let ABPDisplayErrorNotification = NotificationName("ABPDisplayErrorNotification")
private var ABPMainViewChangedNotification = NotificationName("ABPMainViewChangedNotification")

private enum MainWindowView: Int {
	case Welcome = 0
	case FilterLists = 1
	case Exceptions = 2
}

class WindowController: NSWindowController {
	@IBOutlet private var mainViewSelector: NSSegmentedControl!
	@IBAction private func changeMainView(sender: AnyObject?) {
		let segment = mainViewSelector.selectedSegment
		let viewId = MainWindowView(rawValue: segment)!
		let note = Notification(name: ABPMainViewChangedNotification, object: self, userInfo: [ "view": viewId ])
		note.post()
	}

	override func windowDidLoad() {
		super.windowDidLoad()
		window?.title = localize("AdBlockPlus Settings", "Localizable")
		window?.titleVisibility = .hidden

		NotificationCenter.default().addObserver(name: ABPDisplayErrorNotification, sender: nil, owner: self) {
			[weak self] note in
			guard let userInfo = note.userInfo else { return }
			let error = userInfo["error"] as! NSError
			let alert = NSAlert(error: error)

			if let window = self?.window {
				alert.beginSheetModal(for: window, completionHandler: nil)
			} else {
				alert.runModal()
			}
		}
	}
}

class ViewController: NSViewController {
	private var notificationListeners: [AnyObject] = []

	override func viewDidLoad() {
		super.viewDidLoad()

		NotificationCenter.default().addObserver(name: ABPMainViewChangedNotification, sender: nil, owner: self) {
			note in
			// ...
		}
	}
	
	override var representedObject: AnyObject? {
		didSet {
			// Update the view, if already loaded.
		}
	}
}
