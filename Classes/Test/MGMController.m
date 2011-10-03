//
//  MGMController.m
//  MGMDB
//
//  Created by Mr. Gecko on 2/12/10.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). http://mrgeckosmedia.com/
//
//  Permission to use, copy, modify, and/or distribute this software for any purpose
//  with or without fee is hereby granted, provided that the above copyright notice
//  and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
//  REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT,
//  OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
//  DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
//  ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

#import "MGMController.h"
#import "MGMDB.h"
#import <AddressBook/AddressBook.h>

@implementation MGMController
- (void)awakeFromNib {
	[self debug:@"Connecting to MySQL.\n"];
	MGMMyConnection *myConnection = [MGMMyConnection connectionWithHost:@"127.0.0.1" port:0 username:@"test" password:@"test"];
	if ([myConnection isConnected]) {
		[self debug:@"Connected... Selecting test database.\n"];
		if ([myConnection selectDataBase:@"test"]) {
			[self debug:@"Successful... Adding row to test table.\n"];
			[myConnection query:@"INSERT INTO `test` (`name`,`value`) VALUES (%@,%@)", @"test", @"This is a test of the database. If it doesn't work, we'll know after this."];
			if ([myConnection errorID]==noErr) {
				[self debug:@"Successful... Selecting row to see if it returns correct value.\n"];
				MGMMyResult *result = [myConnection query:@"SELECT * FROM `test` WHERE `name`=%@", @"test"];
				if (result!=nil) {
					NSDictionary *data = [result nextRow];
					if (data!=nil)
						[self debug:@"Successful... The value returned was %@\n", data];
					else
						[self debug:@"The result was null, something is wrong here...\n"];
					[myConnection query:@"DELETE FROM `test` WHERE `name`=%@", @"test"];
				} else {
					[self debug:@"Unable to select row: %@\n", [myConnection errorMessage]];
				}
			} else {
				[self debug:@"Unable to add to table: %@\n", [myConnection errorMessage]];
			}
		} else {
			[self debug:@"Unable to select database: %@\n", [myConnection errorMessage]];
		}
	} else {
		[self debug:@"Unable to connect to database: %@\n", [myConnection errorMessage]];
	}
	
	[self debug:@"\n"];
	[self debug:@"Opening SQLite Database.\n"];
	MGMLiteConnection *liteConnection = [MGMLiteConnection connectionWithPath:[@"~/Desktop/MGMTest.db" stringByExpandingTildeInPath]];
	if (liteConnection!=nil) {
		[self debug:@"Successful... Creating test table.\n"];
		[liteConnection query:@"CREATE TABLE `test` (`name` TEXT, `value` TEXT)"];
		if ([liteConnection errorID]==noErr) {
			[self debug:@"Successful... Adding row to test table.\n"];
			[liteConnection query:@"INSERT INTO `test` (`name`,`value`) VALUES (%@,%@)", @"test", @"This is a test of the database. If it doesn't work, we'll know after this."];
			if ([liteConnection errorID]==noErr) {
				[self debug:@"Successful... Selecting row to see if it returns correct value.\n"];
				MGMLiteResult *result = [liteConnection query:@"SELECT * FROM `test` WHERE `name`=%@", @"test"];
				if (result!=nil) {
					NSDictionary *data = [result nextRow];
					if (data!=nil)
						[self debug:@"Successful... The value returned was %@\n", data];
					else
						[self debug:@"The result was null, something is wrong here...\n"];
				} else {
					[self debug:@"Unable to select row: %@\n", [myConnection errorMessage]];
				}
			} else {
				[self debug:@"Unable to add to table: %@\n", [myConnection errorMessage]];
			}
		} else {
			[self debug:@"Unable to create table: %@\n", [liteConnection errorMessage]];
		}
	} else {
		[self debug:@"Unable to open database.\n"];
	}
	[[NSFileManager defaultManager] removeFileAtPath:[@"~/Desktop/MGMTest.db" stringByExpandingTildeInPath] handler:0];
}
- (void)dealloc {
	[super dealloc];
}

- (void)debug:(NSString *)format, ... {
	va_list ap;
	va_start(ap, format);
	if (format==nil)
		return;
	NSString *info = [[NSString alloc] initWithFormat:format arguments:ap];
	va_end(ap);
	NSLog(@"%@", info);
	[debugLog insertText:info];
	[debugLog display];
	[info release];
}
@end
