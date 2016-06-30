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

public let ABPErrorDomain = "AdBlockPlusErrorDomain"
public let ABPActivatedDefaultsKey = "AdBlockPlusActivated"
private let ABPEnabledDefaultsKey = "AdblockPlusEnabled"
private let ABPAcceptableAdsEnabledDefaultsKey = "AdblockPlusAcceptableAdsEnabled"
private let ABPFilterListsDefaultsKey = "AdblockPlusFilterLists"
private let ABPInstalledVersionDefaultsKey = "AdblockPlusInstalledVersion"
private let ABPDownloadedVersionDefaultsKey = "AdblockPlusDownloadedVersion"
private let ABPWhitelistedWebsitesDefaultsKey = "AdblockPlusWhitelistedWebsites"

private let AdblockPlusSafariExtension = "AdblockPlusSafariExtension"

public class AdBlockPlus: NSObject {
	public static var applicationGroup: String {
		get {
			let teamID = ABPGetApplicationSigningIdentifier()
			return "\(teamID).me.sunsol.AdBlockPlus"
		}
	}

	public override init() {
		guard let path = Bundle(for: AdBlockPlus.self).urlForResource("FilterLists", withExtension: "plist") else {
			fatalError("FilterLists.plist not found")
		}

		// Note: I cannot Swift-ify this variable because NSDictionary(contentsOf:)
		// does not convert to a Swift dictionary type
		let filterLists: NSDictionary
		if let dict = NSDictionary(contentsOf: path) {
			filterLists = dict
		} else {
			filterLists = [:]
		}

		guard let defaults = UserDefaults(suiteName: AdBlockPlus.applicationGroup) else {
			fatalError("Could not create NSUserDefaults suite with name '\(AdBlockPlus.applicationGroup)'")
		}
		adBlockPlusDetails = defaults
		adBlockPlusDetails.register([
			ABPActivatedDefaultsKey: false,
			ABPEnabledDefaultsKey: true,
			ABPAcceptableAdsEnabledDefaultsKey: true,
			ABPInstalledVersionDefaultsKey: 0,
			ABPDownloadedVersionDefaultsKey: 1,
			ABPFilterListsDefaultsKey: filterLists,
			ABPWhitelistedWebsitesDefaultsKey: []
			])

		enabled = adBlockPlusDetails.bool(forKey: ABPEnabledDefaultsKey)
		acceptableAdsEnabled = adBlockPlusDetails.bool(forKey: ABPAcceptableAdsEnabledDefaultsKey)
		activated = adBlockPlusDetails.bool(forKey: ABPActivatedDefaultsKey)
		installedVersion = adBlockPlusDetails.integer(forKey: ABPInstalledVersionDefaultsKey)
		downloadedVersion = adBlockPlusDetails.integer(forKey: ABPDownloadedVersionDefaultsKey)

		guard let filterListsFromDefaults = adBlockPlusDetails.dictionary(forKey: ABPFilterListsDefaultsKey) else {
			fatalError("ABPFilterListsDefaultsKey not found in UserDefaults database")
		}

		self.filterLists = filterListsFromDefaults as! [String: [String: AnyObject]]

		guard let whitelistArray = adBlockPlusDetails.array(forKey: ABPWhitelistedWebsitesDefaultsKey) else {
			fatalError("ABWhitelistedWebsitesDefaultsKey not found in UserDefaults database")
		}

		whitelistedWebsites = whitelistArray as! [String]
	}

	// MARK: Properties

	private(set) public var adBlockPlusDetails: UserDefaults

	public var contentBlockerIdentifier: String {
		get {
			fatalError()
		}
	}

	public var backgroundSessionConfigurationIdentifier: String {
		get {
			return "me.sunsol.AdBlockPlus.BackgroundSession"
		}
	}

	public var enabled = false {
		didSet {
			adBlockPlusDetails.set(enabled, forKey: ABPEnabledDefaultsKey)
		}
	}

	public var acceptableAdsEnabled = false {
		didSet {
			adBlockPlusDetails.set(acceptableAdsEnabled, forKey: ABPAcceptableAdsEnabledDefaultsKey)
		}
	}

	public var activated = false {
		didSet {
			adBlockPlusDetails.set(activated, forKey: ABPActivatedDefaultsKey)
		}
	}

	public var installedVersion = -1 {
		didSet {
			adBlockPlusDetails.set(installedVersion, forKey: ABPInstalledVersionDefaultsKey)
		}
	}

	public var downloadedVersion = -1 {
		didSet {
			adBlockPlusDetails.set(downloadedVersion, forKey: ABPDownloadedVersionDefaultsKey)
		}
	}

	public var filterLists: [String: [String: AnyObject]] = [:] {
		didSet {
			adBlockPlusDetails.set(filterLists, forKey: ABPFilterListsDefaultsKey)
		}
	}

	public var whitelistedWebsites: [String] = [] {
		didSet {
			adBlockPlusDetails.set(whitelistedWebsites, forKey: ABPWhitelistedWebsitesDefaultsKey)
		}
	}
}
