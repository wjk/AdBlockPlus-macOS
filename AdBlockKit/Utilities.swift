//
//  Utilities.swift
//  AdBlockPlus
//
//  Created by William Kent on 6/29/16.
//  Copyright © 2016 William Kent. All rights reserved.
//

import Foundation

internal extension UserDefaults {
	subscript(key: String) -> AnyObject? {
		get {
			return self.object(forKey: key)
		}

		set {
			self.set(newValue, forKey: key)
		}
	}
}
