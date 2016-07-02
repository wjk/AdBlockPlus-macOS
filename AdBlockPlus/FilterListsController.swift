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

class FilterListsController: NSViewController {
	private var model: AdBlockPlusExtras? {
		get {
			if let representedObject = representedObject {
				return (representedObject as! AdBlockPlusExtras)
			} else {
				return nil
			}
		}
	}

	@IBOutlet private var progressIndicator: NSProgressIndicator!
	@IBOutlet private var updateButton: NSButton!

	@IBAction private func updateFilterLists(sender: AnyObject?) {
		if let model = model {
			progressIndicator.isHidden = false
			progressIndicator.startAnimation(nil)
			updateButton.isEnabled = false

			model.updateFilterLists(userTriggered: true) {
				[weak self] in
				if let this = self {
					this.progressIndicator.stopAnimation(nil)
					this.progressIndicator.isHidden = true
					this.updateButton.isEnabled = true
				}
			}

			model.displayErrorDialogIfNeeded()
		} else {
			NSBeep()
		}
	}
}
