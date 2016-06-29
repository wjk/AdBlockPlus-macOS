//
//  Utilities.swift
//  AdBlockPlus
//
//  Created by William Kent on 6/29/16.
//  Copyright © 2016 William Kent. All rights reserved.
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
		if let holderPtr = objc_getAssociatedObject(owner, &NotificationListenerHolder.Key), holderObj = holderPtr as? NotificationListenerHolder {
			holder = holderObj
		} else {
			holder = NotificationListenerHolder()
			holder.owner = self
			objc_setAssociatedObject(owner, &NotificationListenerHolder.Key, holder, .OBJC_ASSOCIATION_RETAIN)
		}

		let listener = self.addObserver(forName: name, object: sender, queue: OperationQueue.main(), using: handler)
		holder.listeners.append(listener)
	}
}

extension Notification {
	func post() {
		NotificationCenter.default().post(self)
	}

	func post(center: NotificationCenter) {
		center.post(self)
	}
}
