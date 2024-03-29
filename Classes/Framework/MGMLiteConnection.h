//
//  MGMLiteConnection.h
//  MGMDB
//
//  Created by Mr. Gecko on 8/13/10.
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

#import <Cocoa/Cocoa.h>
#import <MGMDB/sqlite3.h>

#define MGMLiteDebug 0

@class MGMLiteResult;

@interface MGMLiteConnection : NSObject {
	sqlite3 *SQLiteConnection;
	NSString *path;
	BOOL isConnected;
	NSCharacterSet *escapeSet;
	BOOL logQuery;
}
+ (id)memoryConnection;
+ (id)connectionWithPath:(NSString *)thePath;
- (id)initWithPath:(NSString *)thePath;

- (sqlite3 *)SQLiteConnection;
- (NSString *)path;

- (NSString *)errorMessage;
- (int)errorID;

- (NSString *)escapeData:(NSData *)theData;
- (NSString *)escapeString:(NSString *)theString;
- (NSString *)quoteObject:(id)theObject;
- (NSString *)quoteChar:(const char *)theChar;

- (BOOL)logQuery;
- (void)setLogQuery:(BOOL)shouldLogQuery;
- (MGMLiteResult *)query:(NSString *)format, ...;
- (MGMLiteResult *)tables;
- (MGMLiteResult *)tablesLike:(NSString *)theName;
- (MGMLiteResult *)columnsFromTable:(NSString *)theTable;
- (int)affectedRows;
- (long long int)insertId;
@end