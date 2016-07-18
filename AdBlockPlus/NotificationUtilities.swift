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
import ObjectiveC

func NotificationName(_ name: String) -> Notification.Name {
	return Notification.Name(name)
}

extension NotificationCenter {
	private class NotificationListenerHolder {
		static var Key = 0

		deinit {
			if let owner = owner {
				for listener in listeners {
					owner.removeObserver(listener)
				}
			}
		}

		weak var owner: NotificationCenter?
		var listeners: [AnyObject] = []
	}

	func addObserver(name: Notification.Name?, sender: AnyObject?, owner: AnyObject, handler: (Notification) -> Void) {
		let holder: NotificationListenerHolder
		if let holderPtr = objc_getAssociatedObject(owner, &NotificationListenerHolder.Key), let holderObj = holderPtr as? NotificationListenerHolder {
			holder = holderObj
		} else {
			holder = NotificationListenerHolder()
			holder.owner = self
			objc_setAssociatedObject(owner, &NotificationListenerHolder.Key, holder, .OBJC_ASSOCIATION_RETAIN)
		}

		let listener = self.addObserver(forName: name, object: sender, queue: OperationQueue.main, using: handler)
		holder.listeners.append(listener)
	}
}

extension Notification {
	func post() {
		NotificationCenter.default.post(self)
	}

	func post(center: NotificationCenter) {
		center.post(self)
	}
}
