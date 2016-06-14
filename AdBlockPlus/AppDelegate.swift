//
//  AppDelegate.swift
//  AdBlockPlus
//
//  Created by William Kent on 6/14/16.
//  Copyright © 2016 William Kent. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationDidFinishLaunching(_ notification: Notification) {
		// Insert code here to initialize your application
	}
	
	func applicationWillTerminate(_ notification: Notification) {
		// Insert code here to tear down your application
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
}

func localize(_ key: String, _ table: String) -> String {
	return Bundle.main().localizedString(forKey: key, value: nil, table: table)
}
