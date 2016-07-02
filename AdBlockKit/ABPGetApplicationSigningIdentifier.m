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

@import Foundation;
@import Security;

static void SafeCFRelease_CFDictionaryRef(CFDictionaryRef *cf) {
	if (*cf != NULL) CFRelease(*cf);
}

static void SafeCFRelease_SecCodeRef(SecCodeRef *cf) {
	if (*cf != NULL) CFRelease(*cf);
}

#define AutoCFReleased(type) __attribute__((cleanup(SafeCFRelease_##type))) type

NSString *ABPGetApplicationSigningIdentifier(void) {
	static NSString *teamID = NULL;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		AutoCFReleased(SecCodeRef) processCodeObject = NULL;
		OSStatus status = SecCodeCopySelf(kSecCSDefaultFlags, &processCodeObject);
		NSCAssert(status == noErr, @"SecCodeCopySelf returned status %d", status);
		NSCAssert(processCodeObject, @"SecCodeCopySelf returned success, but gave NULL SecCodeRef");

		AutoCFReleased(CFDictionaryRef) codeAttributes = NULL;
		status = SecCodeCopySigningInformation(processCodeObject, kSecCSSigningInformation, &codeAttributes);
		NSCAssert(status == noErr, @"SecCodeCopySigningInformation returned status %d", status);
		NSCAssert(codeAttributes != NULL, @"SecCodeCopySigningInformation returned success, but gave NULL attributes dictionary");

		CFStringRef teamIDCF = CFDictionaryGetValue(codeAttributes, kSecCodeInfoTeamIdentifier);
		teamID = (__bridge NSString *)teamIDCF;
	});

	return teamID;
}
