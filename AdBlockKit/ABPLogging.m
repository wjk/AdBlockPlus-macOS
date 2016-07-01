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

	NSFileHandle *handle = fileHandles[logFileURL];
	if (handle == nil) {
		NSError *error;
		handle = [NSFileHandle fileHandleForWritingToURL:logFileURL error:&error];
		NSCAssert(handle != nil, @"Could not create NSFileHandle for URL '%@': %@", logFileURL, error);
		fileHandles[logFileURL] = handle;
	}

	asl_object_t aslhandle = asl_open(NULL, "me.sunsol.AdBlockPlus", 0);
	asl_add_log_file(aslhandle, handle.fileDescriptor);
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
