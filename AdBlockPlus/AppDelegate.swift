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
import SafariServices

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationDidFinishLaunching(_ notification: Notification) {
		NSError.setUserInfoValueProvider(forDomain: SFContentBlockerErrorDomain) {
			(error, userInfoKey) -> AnyObject? in
			assert(error.domain == SFContentBlockerErrorDomain, "Unexpected error domain in user info callback")
			switch userInfoKey {
			case NSLocalizedDescriptionKey:
				switch error.code {
				case SFContentBlockerErrorCode.noExtensionFound.rawValue:
					return localize("Could not update the Safari extension because it has not been registered.", "Localizable")
				case SFContentBlockerErrorCode.noAttachmentFound.rawValue:
					return localize("Could not update the Safari extension because it could not find its rules file.", "Localizable")
				case SFContentBlockerErrorCode.loadingInterrupted.rawValue:
					return localize("An error occurred while loading the Safari extension.", "Localizable")
				default:
					return nil
				}
			case NSLocalizedRecoverySuggestionErrorKey:
				return localize("Please try again later.", "Localizable")
			default:
				return nil
			}
		}
	}
	
	func applicationWillTerminate(_ notification: Notification) {
		// Insert code here to tear down your application
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
}

func localize(_ key: String, _ table: String) -> String {
	return Bundle(for: AppDelegate.self).localizedString(forKey: key, value: nil, table: table)
}
