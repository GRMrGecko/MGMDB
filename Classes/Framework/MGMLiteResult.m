//
//  MGMLiteResult.m
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

#import "MGMLiteResult.h"
#import "MGMLiteConnection.h"

@implementation MGMLiteResult
+ (id)resultWithConnection:(MGMLiteConnection *)theConnection result:(sqlite3_stmt *)theResult {
	return [[[self alloc] initWithConnection:theConnection result:theResult] autorelease];
}
- (id)initWithConnection:(MGMLiteConnection *)theConnection result:(sqlite3_stmt *)theResult {
	if (self = [super init]) {
		connection = [theConnection retain];
		result = theResult;
		if (result==NULL) {
			[self release];
			self = nil;
		} else {
			columnCount = [self columnCount];
			columnNames = [[self columnNames] retain];
			int status = [self step];
			if (status==SQLITE_ROW) {
				[self reset];
			} else if (status==SQLITE_DONE) {
				[self release];
				self = nil;
			}
		}
	}
	return self;
}
- (void)dealloc {
	if (connection!=nil)
		[connection release];
	if (result!=NULL)
		sqlite3_finalize(result);
	if (columnNames!=nil)
		[columnNames release];
	[super dealloc];
}

- (int)dataCount {
	if (result!=NULL)
		return sqlite3_data_count(result);
	return 0;
}
- (int)columnCount {
	if (result!=NULL)
		return sqlite3_column_count(result);
	return 0;
}
- (NSString *)columnName:(int)theColumn {
	NSString *name = [NSString stringWithCString:sqlite3_column_name(result, theColumn) encoding:NSUTF8StringEncoding];
	if (name!=NULL && ![name isEqualToString:@""])
		return name;
	return [[NSNumber numberWithInt:theColumn] stringValue];
}
- (NSArray *)columnNames {
	columnCount = [self columnCount];
	NSMutableArray *names = nil;
	if (result!=NULL) {
		names = [NSMutableArray array];
		for (int i=0; i<columnCount; i++) {
			[names addObject:[self columnName:i]];
		}
	}
	return names;
}

- (NSNumber *)integerAtColumn:(int)theColumn {
	return [NSNumber numberWithLongLong:sqlite3_column_int64(result, theColumn)];
}
- (NSNumber *)doubleAtColumn:(int)theColumn {
	return [NSNumber numberWithDouble:sqlite3_column_double(result, theColumn)];
}
- (NSString *)stringAtColumn:(int)theColumn {
	const char *text = (const char *)sqlite3_column_text(result, theColumn);
	if (text!=NULL)
		return [NSString stringWithUTF8String:text];
	return nil;
}
- (NSData *)dataAtColumn:(int)theColumn {
	const void *bytes = sqlite3_column_blob(result, theColumn);
	int length = sqlite3_column_bytes(result, theColumn);
	if (bytes!=NULL && length!=0)
		return [NSData dataWithBytes:bytes length:length];
	return nil;
}
- (id)objectAtColumn:(int)theColumn {
	int type = sqlite3_column_type(result, theColumn);
	id object = nil;
	switch (type) {
		case SQLITE_INTEGER:
			object = [self integerAtColumn:theColumn];
			break;
		case SQLITE_FLOAT:
			object = [self doubleAtColumn:theColumn];
			break;
		case SQLITE_TEXT:
			object = [self stringAtColumn:theColumn];
			break;
		case SQLITE_BLOB:
			object = [self dataAtColumn:theColumn];
			break;
		case SQLITE_NULL:
			object = [NSNull null];
			break;
	}
	
	if (object==nil) {
		object = [NSNull null];
	}
	return object;
}

- (NSArray *)nextRowAsArray {
	int status = [self step];
	if (status==SQLITE_ROW) {
		int dataCount = [self dataCount];
		if (dataCount>=1) {
			NSMutableArray *rowArray = [NSMutableArray array];
			for (int i=0;  i<dataCount; i++) {
				id object = [self objectAtColumn:i];
				[rowArray addObject:object];
			}
			return rowArray;
		}
	}
	return nil;
}
- (NSDictionary *)nextRow {
	int status = [self step];
	if (status==SQLITE_ROW) {
		int dataCount = [self dataCount];
		if (dataCount>=1) {
			NSMutableDictionary *rowDictionary = [NSMutableDictionary dictionary];
			for (int i=0;  i<dataCount; i++) {
				id object = [self objectAtColumn:i];
				[rowDictionary setObject:object forKey:[self columnName:i]];
			}
			return rowDictionary;
		}
	}
	return nil;
}
- (int)step {
	int status = SQLITE_BUSY;
	while (status==SQLITE_BUSY) {
		status = sqlite3_step(result);
	}
	return status;
}
- (int)reset {
	return sqlite3_reset(result);
}
@end