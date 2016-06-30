//
//  UtilityViews.swift
//  AdBlockPlus
//
//  Created by William Kent on 6/30/16.
//  Copyright © 2016 William Kent. All rights reserved.
//

import Foundation
import AppKit

class ButtonTableCellView: NSTableCellView {
	@IBOutlet internal var button: NSButton!
}

class AddTextualEntryTableCellView: NSTableCellView {
	var confirmAction: ((AddTextualEntryTableCellView) -> ())?
	var cancelAction: ((AddTextualEntryTableCellView) -> ())?

	override func awakeFromNib() {
		if let textField = textField {
			textField.target = self
			textField.action = #selector(textFieldAction(sender:))
		}
	}

	@objc private func textFieldAction(sender: AnyObject?) {
		confirmAction?(self)
	}

	override func cancelOperation(_ sender: AnyObject?) {
		cancelAction?(self)
	}
}
