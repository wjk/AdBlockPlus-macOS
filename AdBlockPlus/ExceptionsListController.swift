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

class ExceptionsListController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
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

	private var _addingWhitelistedWebsite = false
	@objc @IBAction private func addWhitelistedWebsite(sender: AnyObject?) {
		_addingWhitelistedWebsite = true
		whitelistTableView.reloadData()
	}

	@objc @IBAction private func removeWhitelistedWebsite(sender: AnyObject?) {
		guard let sender = sender as? NSButton else { return }
		let index = sender.tag
		model?.whitelistedWebsites.remove(at: index)
		whitelistTableView.reloadData()
	}

	private func confirmAddWhitelistedWebsite(sender: AddTextualEntryTableCellView) {
		if let text = sender.textField?.stringValue {
			// Attempt to extract the hostname from the URL, if possible.
			if let url = URL(string: text), let host = url.host {
				model?.whitelistedWebsites.append(host)
			} else {
				let pathElements = text.components(separatedBy: "/")

				var components = URLComponents()
				components.host = pathElements[0]
				components.scheme = "http"

				if let url = components.url, let host = url.host {
					model?.whitelistedWebsites.append(host)
				} else {
					NSBeep()
				}
			}
		} else {
			NSBeep()
		}

		_addingWhitelistedWebsite = false
		whitelistTableView.reloadData()
	}

	private func cancelAddWhitelistedWebsite(sender: AddTextualEntryTableCellView) {
		_addingWhitelistedWebsite = false
		whitelistTableView.reloadData()
	}

	// MARK: NSTableViewDataSource / NSTableViewDelegate

	func numberOfRows(in tableView: NSTableView) -> Int {
		let whitelistCount = model?.whitelistedWebsites.count ?? 0
		return whitelistCount + 1 // for "Add Website" button
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		guard let model = model else { fatalError("Must have a model object") }
		guard let tableColumn = tableColumn else { return nil }

		switch tableColumn.identifier {
		case "ABPNameColumn":
			if row >= model.whitelistedWebsites.count {
				if _addingWhitelistedWebsite {
					let cell = tableView.make(withIdentifier: "ABPEnterWebsiteCell", owner: self) as! AddTextualEntryTableCellView
					cell.textField?.stringValue = ""
					cell.cancelAction = {
						[weak self] sender in
						self?.cancelAddWhitelistedWebsite(sender: sender)
					}
					cell.confirmAction = {
						[weak self] sender in
						self?.confirmAddWhitelistedWebsite(sender: sender)
					}

					view.window?.perform(#selector(NSWindow.makeFirstResponder(_:)), with: cell.textField, afterDelay: 0.0)
					return cell
				}

				let cell = tableView.make(withIdentifier: "ABPAddWebsiteCell", owner: self) as! ButtonTableCellView
				cell.button.target = self
				cell.button.action = #selector(addWhitelistedWebsite(sender:))
				cell.button.controlSize = NSControlSize.small
				return cell
			} else {
				let cell = tableView.make(withIdentifier: "ABPWebsiteNameCell", owner: self) as! NSTableCellView
				cell.textField?.stringValue = model.whitelistedWebsites[row]
				return cell
			}
		case "ABPRemoveButtonColumn":
			if row < model.whitelistedWebsites.count {
				let cell = tableView.make(withIdentifier: "ABPRemoveWebsiteCell", owner: self) as! ButtonTableCellView
				cell.button.target = self
				cell.button.action = #selector(removeWhitelistedWebsite(sender:))
				cell.button.tag = row
				cell.button.controlSize = NSControlSize.small
				return cell
			} else {
				// There is no Remove button for the Add Website row.
				return nil
			}
		default:
			NSLog("Unexpected NSTableColumn identifier '\(tableColumn.identifier)'")
			return nil
		}
	}

	func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
		return false
	}
}
