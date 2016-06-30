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
import AppKit

class ExceptionsListController: NSViewController {
	private var model: AdBlockPlusExtras? {
		get {
			if let obj = representedObject {
				return (obj as! AdBlockPlusExtras)
			} else {
				return nil
			}
		}
	}

	override func viewDidLoad() {
		_viewLoaded = true
		reloadView()
	}

	private func reloadView() {
		guard let model = model else {
			return
		}

		acceptableAdsCheckbox.state = model.acceptableAdsEnabled ? NSOnState : NSOffState
	}

	private var _viewLoaded = false
	override var representedObject: AnyObject? {
		didSet {
			if _viewLoaded {
				reloadView()
			}
		}
	}

	// MARK: IBOutlets
	@IBOutlet private var acceptableAdsCheckbox: NSButton!
	@IBOutlet private var whitelistTableView: NSTableView!

	// MARK: IBActions

	@IBAction private func toggleAcceptableAdsCheckbox(sender: AnyObject?) {
		model?.acceptableAdsEnabled = (acceptableAdsCheckbox.state == NSOnState)
	}
}
