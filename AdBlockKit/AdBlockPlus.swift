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
			let teamID = ABPGetApplicationSigningIdentifier() ?? "group"
			return "\(teamID).me.sunsol.AdBlockPlus"
		}
	}

	public override init() {
		guard let defaults = UserDefaults(suiteName: AdBlockPlus.applicationGroup) else {
			fatalError("Could not create NSUserDefaults suite with name '\(AdBlockPlus.applicationGroup)'")
		}
		adBlockPlusDetails = defaults
		super.init()

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

		adBlockPlusDetails.register([
			ABPActivatedDefaultsKey: false,
			ABPEnabledDefaultsKey: false,
			ABPAcceptableAdsEnabledDefaultsKey: true,
			ABPInstalledVersionDefaultsKey: 0,
			ABPDownloadedVersionDefaultsKey: 1,
			ABPFilterListsDefaultsKey: filterLists,
			ABPWhitelistedWebsitesDefaultsKey: []
			])

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
			return "me.sunsol.AdBlockPlus.SafariExtension"
		}
	}

	public var backgroundSessionConfigurationIdentifier: String {
		get {
			return "me.sunsol.AdBlockPlus.BackgroundSession"
		}
	}

	public var enabled: Bool {
		get {
			return adBlockPlusDetails.bool(forKey: ABPEnabledDefaultsKey)
		}

		set {
			adBlockPlusDetails.set(newValue, forKey: ABPEnabledDefaultsKey)
		}
	}

	public var acceptableAdsEnabled: Bool {
		get {
			return adBlockPlusDetails.bool(forKey: ABPAcceptableAdsEnabledDefaultsKey)
		}

		set {
			adBlockPlusDetails.set(newValue, forKey: ABPAcceptableAdsEnabledDefaultsKey)
		}
	}

	public var activated: Bool {
		get {
			return adBlockPlusDetails.bool(forKey: ABPActivatedDefaultsKey)
		}

		set {
			adBlockPlusDetails.set(newValue, forKey: ABPActivatedDefaultsKey)
		}
	}

	public var installedVersion: Int {
		get {
			return adBlockPlusDetails.integer(forKey: ABPInstalledVersionDefaultsKey)
		}

		set {
			adBlockPlusDetails.set(newValue, forKey: ABPInstalledVersionDefaultsKey)
		}
	}

	public var downloadedVersion: Int {
		get {
			return adBlockPlusDetails.integer(forKey: ABPDownloadedVersionDefaultsKey)
		}

		set {
			adBlockPlusDetails.set(newValue, forKey: ABPDownloadedVersionDefaultsKey)
		}
	}

	public var filterLists: [String: [String: AnyObject]] {
		get {
			return adBlockPlusDetails.object(forKey: ABPFilterListsDefaultsKey) as! [String: [String: AnyObject]]
		}

		set {
			adBlockPlusDetails.set(newValue, forKey: ABPFilterListsDefaultsKey)
		}
	}

	public var whitelistedWebsites: [String] {
		get {
			return adBlockPlusDetails.object(forKey: ABPWhitelistedWebsitesDefaultsKey) as! [String]
		}

		set {
			adBlockPlusDetails.set(newValue, forKey: ABPWhitelistedWebsitesDefaultsKey)
		}
	}
}
