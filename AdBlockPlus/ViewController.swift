//
//  ViewController.swift
//  AdBlockPlus
//
//  Created by William Kent on 6/14/16.
//  Copyright © 2016 William Kent. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewDidAppear() {
		super.viewDidAppear()
		view.window?.titleVisibility = .hidden
	}
	
	override var representedObject: AnyObject? {
		didSet {
			// Update the view, if already loaded.
		}
	}
}
