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
import AdBlockKit

@objc(ABPContentBlockerRequestHandler)
class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
		let abp = AdBlockPlus()
		abp.activated = true

		let downloadedVersion = abp.downloadedVersion
		let url = abp.activeFilterListURLWithWhitelistedWebsites

		guard let attachment = NSItemProvider(contentsOf: url) else {
			fatalError("Could not create NSItemProvider for URL '\(url)'")
		}

		let extensionItem = NSExtensionItem()
		extensionItem.attachments = [attachment]
		context.completeRequest(returningItems: [extensionItem]) {
			(expired) in
			if !expired {
				abp.installedVersion = max(abp.installedVersion, downloadedVersion)
			}
		}
    }
}
