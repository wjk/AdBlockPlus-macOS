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

#import "AdBlockKit.h"

asl_object_t ABPLogFileOpen(NSURL *logFileURL) {
	static NSMutableDictionary *fileHandles = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		fileHandles = [NSMutableDictionary dictionary];
	});

	NSNumber *fdNumber = fileHandles[logFileURL];
	if (fdNumber == nil) {
		NSError *error;
		BOOL success = [[NSFileManager defaultManager] createDirectoryAtURL:[logFileURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
		NSCAssert(success, @"Could not create directory for log file URL '%@': %@", logFileURL, error);
		[[NSData data] writeToURL:logFileURL atomically:YES];

		NSCAssert(logFileURL.isFileURL, @"%s() only supports file URLs", __FUNCTION__);
		int fd = open(logFileURL.fileSystemRepresentation, O_WRONLY | O_APPEND | O_CREAT, 0644);
		NSCAssert(fd != -1, @"Could not open URL '%@' (error = %d)", logFileURL, errno);

		fdNumber = @(fd);
		fileHandles[logFileURL] = fdNumber;
	}

	asl_object_t aslhandle = asl_open(NULL, "me.sunsol.AdBlockPlus", 0);
	asl_add_log_file(aslhandle, fdNumber.intValue);
	NSCAssert(aslhandle != NULL, @"Could not open ASL handle!");
	return aslhandle;
}

void ABPLogWithHandle(asl_object_t aslhandle, ABPLogLevel level, NSString *message) {
	asl_log(aslhandle, NULL, level, "%s", message.UTF8String);
}

void ABPLog(NSURL *logFileURL, ABPLogLevel level, NSString *message) {
	asl_object_t aslhandle = ABPLogFileOpen(logFileURL);
	ABPLogWithHandle(aslhandle, level, message);
	asl_release(aslhandle);
}
