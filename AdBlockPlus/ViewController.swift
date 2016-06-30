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
	@IBOutlet private var viewBox: NSBox!
	private var currentViewController: NSViewController?

	override func viewDidLoad() {
		super.viewDidLoad()
		representedObject = AdBlockPlusExtras()

		let storyboard = NSStoryboard(name: "Main", bundle: nil)
		NotificationCenter.default().addObserver(name: ABPMainViewChangedNotification, sender: nil, owner: self) {
			[weak self] note in
			guard let userInfo = note.userInfo else { return }
			guard let viewIdObj = userInfo["view"] else { return }
			let viewId = viewIdObj as! MainWindowView

			if let this = self {
				switch viewId {
				case .Welcome: this.currentViewController = (storyboard.instantiateController(withIdentifier: "ABPWelcomePane") as! NSViewController)
				case .Exceptions: this.currentViewController = (storyboard.instantiateController(withIdentifier: "ABPWhitelistPane") as! NSViewController)
				default: this.currentViewController = nil
				}

				this.currentViewController?.representedObject = this.representedObject
				this.viewBox.contentView = this.currentViewController?.view
			}
		}

		currentViewController = (storyboard.instantiateController(withIdentifier: "ABPWelcomePane") as! NSViewController)
		viewBox.contentView = currentViewController!.view
	}
	
	override var representedObject: AnyObject? {
		didSet {
			// Update the view, if already loaded.
		}
	}
}
