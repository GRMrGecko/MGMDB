//
//  MGMMyConnection.h
//  MGMDB
//
//  Created by Mr. Gecko on 1/20/10.
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
#import <MGMDB/mysql.h>

@class MGMMyResult;

@interface MGMMyConnection : NSObject {
	MYSQL *MySQLConnection;
	BOOL isConnected;
	NSTimeZone *timeZone;
	NSCharacterSet *escapeSet;
	BOOL logQuery;
}
+ (id)connectionWithHost:(NSString *)theHost port:(int)thePort username:(NSString *)theUsername password:(NSString *)thePassword;
- (id)initWithHost:(NSString *)theHost port:(int)thePort username:(NSString *)theUsername password:(NSString *)thePassword;
+ (id)connectionWithSocket:(NSString *)theSocket username:(NSString *)theUsername password:(NSString *)thePassword;
- (id)initWithSocket:(NSString *)theSocket username:(NSString *)theUsername password:(NSString *)thePassword;

- (BOOL)connectWithHost:(NSString *)theHost port:(int)thePort username:(NSString *)theUsername password:(NSString *)thePassword;
- (BOOL)connectWithSocket:(NSString *)theSocket username:(NSString *)theUsername password:(NSString *)thePassword;

- (MYSQL *)MySQLConnection;
- (NSStringEncoding)stringEncodingWithCharSet:(NSString *)theCharSet;

- (BOOL)isConnected;
- (void)disconnect;
- (NSString *)errorMessage;
- (unsigned int)errorID;

- (NSString *)escapeData:(NSData *)theData;
- (NSString *)escapeString:(NSString *)theString;
- (NSString *)quoteObject:(id)theObject;
- (NSString *)quoteChar:(const char *)theChar;

- (MGMMyResult *)query:(NSString *)format, ...;
- (my_ulonglong)affectedRows;
- (my_ulonglong)insertId;
- (BOOL)selectDataBase:(NSString *)theDataBase;
- (MGMMyResult *)dataBases;
- (MGMMyResult *)dataBasesLike:(NSString *)theName;
- (BOOL)createDataBase:(NSString *)theDataBase;
- (BOOL)deleteDataBase:(NSString *)theDataBase;
- (MGMMyResult *)tables;
- (MGMMyResult *)tablesLike:(NSString *)theName;
- (MGMMyResult *)tablesFromDataBase:(NSString *)theDataBase;
- (MGMMyResult *)tablesFromDataBase:(NSString *)theDataBase like:(NSString *)theName;
- (MGMMyResult *)columnsFromTable:(NSString *)theTable;
- (MGMMyResult *)columnsFromTable:(NSString *)theTable like:(NSString *)theName;

- (NSString *)clientInfo;
- (NSString *)hostInfo;
- (NSString *)serverInfo;
- (NSNumber *)protoInfo;
- (NSString *)status;
- (NSNumber *)threadID;

- (MGMMyResult *)processes;
- (BOOL)killProcess:(unsigned long)processID;

- (NSTimeZone *)timeZone;
- (void)getTimeZone;
@end
