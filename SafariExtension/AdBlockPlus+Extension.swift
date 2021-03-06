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

private func _createLogFileURL() -> URL {
	let libraryURL = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
	return libraryURL.appendingPathComponents(["Logs", "AdBlockPlusSafariExtension.log"])
}
internal let ABPLogFileURL = _createLogFileURL()

// MARK:

internal extension URL {
	func appendingPathComponents(_ components: [String]) -> URL {
		var retval = self
		for elem in components {
			retval = retval.appendingPathComponent(elem)
		}
		return retval
	}
}

extension AdBlockPlus {
	private static func mergeFilterLists(from input: URL, withWhitelist whitelist: [String], to output: URL) throws {
		let inputData = try Data(contentsOf: input)
		let array: NSMutableArray = try JSONSerialization.jsonObject(with: inputData, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSMutableArray

		for website in whitelist {
			NSLog("AdBlockPlus Safari Extension: Merging whitelist entry for domain '\(website)'")
			let whitelistingRule = [
				"trigger": [ "url-filter": ".*", "if-domain": [website] ],
				"action": [ "type": "ignore-previous-rules" ]
			]
			array.add(whitelistingRule)
		}

		let outputData = try JSONSerialization.data(withJSONObject: array)
		try outputData.write(to: output)
	}

	var activeFilterListURL: URL {
		get {
			let fileManager = FileManager()
			let filename: String

			if !enabled {
				guard let url = Bundle(for: ContentBlockerRequestHandler.self).url(forResource: "empty", withExtension: "json", subdirectory: "Filter Lists") else {
					fatalError("Could not retrieve empty.json file")
				}
				return url
			} else if acceptableAdsEnabled {
				filename = "easylist+exceptionrules_content_blocker"
			} else {
				filename = "easylist_content_blocker"
			}

			for (_, filterList) in filterLists {
				if let filterListFilename = filterList["filename"] as? String, filename == filterListFilename {
					if let downloaded = filterList["downloaded"] as? Bool, !downloaded {
						break
					}

					guard var url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AdBlockPlus.applicationGroup) else {
						fatalError("Could not resolve application group identifier to container URL")
					}
					url = url.appendingPathComponents(["Library", "AdBlockPlus Filter Lists", filename])
					url = url.appendingPathExtension("json")

					assert(url.isFileURL, "Filter list URL '\(url)' points to a non-local resource, this is not supported")
					do {
						let reachable = try url.checkResourceIsReachable()
						if !reachable { break }
						return url
					} catch {
						break
					}
				}
			}

			guard let url = Bundle(for: ContentBlockerRequestHandler.self).url(forResource: filename, withExtension: "json", subdirectory: "Filter Lists") else {
				fatalError("Fallback filter list '\(filename).json' not found")
			}
			return url
		}
	}

	var activeFilterListURLWithWhitelistedWebsites: URL {
		get {
			if !enabled {
				guard let url = Bundle(for: ContentBlockerRequestHandler.self).url(forResource: "empty", withExtension: "json", subdirectory: "Filter Lists") else {
					fatalError("Could not retrieve empty.json file")
				}
				return url
			}

			let original = activeFilterListURL
			let filename = original.lastPathComponent
			if filename == "empty.json" {
				return original
			}

			let fileManager = FileManager()
			guard var copy = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AdBlockPlus.applicationGroup) else {
				fatalError("Could not resolve application group identifier to container URL")
			}
			copy = copy.appendingPathComponents(["Library", "AdBlockPlus Filter Lists"])
			copy = copy.appendingPathComponent("ww-\(filename)")

			do {
				try AdBlockPlus.mergeFilterLists(from: original, withWhitelist: whitelistedWebsites, to: copy)
				return copy
			} catch {
				return original
			}
		}
	}
}
