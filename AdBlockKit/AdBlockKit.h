//
//  AdBlockKit.h
//  AdBlockKit
//
//  Created by William Kent on 6/29/16.
//  Copyright © 2016 William Kent. All rights reserved.
//

@import Foundation;
@import asl;

extern double AdBlockKitVersionNumber;
extern const unsigned char AdBlockKitVersionString[];

extern NSString *_Nullable ABPGetApplicationSigningIdentifier(void);

#pragma mark Logging

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ABPLogLevel) {
	ABPLogLevelEmergency = 0,
	ABPLogLevelAlert = 1,
	ABPLogLevelCritical = 2,
	ABPLogLevelError = 3,
	ABPLogLevelWarning = 4,
	ABPLogLevelNotice = 5,
	ABPLogLevelInfo = 6,
	ABPLogLevelDebug = 7
};

extern asl_object_t ABPLogOpenFile(NSURL *logFileURL);
extern void ABPLog(NSURL *logFileURL, ABPLogLevel level, NSString *message);
extern void ABPLogWithHandle(asl_object_t aslhandle, ABPLogLevel level, NSString *message);
NS_ASSUME_NONNULL_END
