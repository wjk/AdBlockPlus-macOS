//
//  ABPGetApplicationSigningIdentifier.m
//  AdBlockPlus
//
//  Created by William Kent on 6/29/16.
//  Copyright © 2016 William Kent. All rights reserved.
//

@import Foundation;
@import Security;

static void SafeCFRelease(CFTypeRef cf) {
	if (cf != NULL) CFRelease(cf);
}

#define AutoCFRelease __attribute__((cleanup(SafeCFRelease)))

NSString *ABPGetApplicationSigningIdentifier(void) {
	AutoCFRelease SecCodeRef processCodeObject = NULL;
	OSStatus status = SecCodeCopySelf(kSecCSDefaultFlags, &processCodeObject);
	NSCAssert(status == noErr, @"SecCodeCopySelf returned status %d", status);
	NSCAssert(processCodeObject, @"SecCodeCopySelf returned success, but gave NULL SecCodeRef");

	AutoCFRelease CFDictionaryRef codeAttributes = NULL;
	status = SecCodeCopySigningInformation(processCodeObject, kSecCSSigningInformation, &codeAttributes);
	NSCAssert(status == noErr, @"SecCodeCopySigningInformation returned status %d", status);
	NSCAssert(codeAttributes != NULL, @"SecCodeCopySigningInformation returned success, but gave NULL attributes dictionary");

	CFStringRef teamID = CFDictionaryGetValue(codeAttributes, kSecCodeInfoTeamIdentifier);
	NSCAssert(teamID != NULL, @"Could not retrieve Team Identifier");
	return (__bridge_transfer NSString *)teamID;
}
