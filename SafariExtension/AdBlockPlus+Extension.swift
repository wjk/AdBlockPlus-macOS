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

extension AdBlockPlus {
	private static func mergeFilterLists(from input: URL, withWhitelist whitelist: [String], to output: URL) throws {
		let inputData = try Data(contentsOf: input)
		var array: [AnyObject] = try JSONSerialization.jsonObject(with: inputData) as! [AnyObject]

		for website in whitelist {
			let whitelistingRule = [
				"trigger": [ "url-filter": ".*", "if-domain": [website] ],
				"action": [ "type": "ignore-previous-rules" ]
			]
			array.append(whitelistingRule)
		}

		let outputData = try JSONSerialization.data(withJSONObject: array)
		try outputData.write(to: output)
	}
}
