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
