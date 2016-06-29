//
//  ViewController.swift
//  AdBlockPlus
//
//  Created by William Kent on 6/14/16.
//  Copyright © 2016 William Kent. All rights reserved.
//

import Cocoa

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
	
	override func viewDidAppear() {
		super.viewDidAppear()

		if let window = view.window {
			window.title = localize("AdBlockPlus Settings", "Localizable")
			window.titleVisibility = .hidden
		}
	}
	
	override var representedObject: AnyObject? {
		didSet {
			// Update the view, if already loaded.
		}
	}
}
