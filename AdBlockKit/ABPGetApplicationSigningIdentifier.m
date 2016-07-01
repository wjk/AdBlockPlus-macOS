//
//  ABPGetApplicationSigningIdentifier.m
//  AdBlockPlus
//
//  Created by William Kent on 6/29/16.
//  Copyright © 2016 William Kent. All rights reserved.
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
