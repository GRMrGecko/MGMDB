//
//  MGMMyResult.m
//  MGMDB
//
//  Created by Mr. Gecko on 2/13/10.
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

#import "MGMMyResult.h"
#import "MGMMyConnection.h"

@implementation MGMMyResult
+ (id)resultWithConnection:(MGMMyConnection *)theConnection {
	return [[[self alloc] initWithConnection:theConnection] autorelease];
}
- (id)initWithConnection:(MGMMyConnection *)theConnection {
	if (self = [super init]) {
		connection = [theConnection retain];
		result = mysql_store_result([connection MySQLConnection]);
		if (result==NULL) {
			[self release];
			self = nil;
		} else {
			columnCount = [self columnCount];
			columnNames = [[self columnNames] retain];
		}
	}
	return self;
}
+ (id)resultWithConnection:(MGMMyConnection *)theConnection result:(MYSQL_RES *)theResult {
	return [[[self alloc] initWithConnection:theConnection result:theResult] autorelease];
}
- (id)initWithConnection:(MGMMyConnection *)theConnection result:(MYSQL_RES *)theResult {
	if (self = [super init]) {
		connection = [theConnection retain];
		result = theResult;
		if (result==NULL) {
			[self release];
			self = nil;
		} else {
			columnCount = [self columnCount];
			columnNames = [[self columnNames] retain];
		}
	}
	return self;
}
- (void)dealloc {
	mysql_free_result(result);
	[columnNames release];
	[connection release];
	[super dealloc];
}

- (my_ulonglong)rowCount {
	if (result!=NULL)
		return mysql_num_rows(result);
	return 0;
}
- (unsigned int)columnCount {
	if (result!=NULL)
		return mysql_num_fields(result);
	return 0;
}
- (NSArray *)columnNames {
	columnCount = [self columnCount];
	NSMutableArray *names = nil;
	if (result!=NULL) {
		names = [NSMutableArray array];
		MYSQL_FIELD *columns = mysql_fetch_fields(result);    
		for (int i=0; i<columnCount; i++) {
			NSString *name = [NSString stringWithCString:columns[i].name encoding:NSUTF8StringEncoding];
			if (![name isEqualToString:@""])
				[names addObject:name];
			else
				[names addObject:[[NSNumber numberWithInt:i] stringValue]];
		}
	}
	return names;
}

- (id)objectAtColumn:(struct st_mysql_field)theColumn bytes:(char *)theBytes length:(unsigned long)theLength {
	id object = nil;
	switch (theColumn.type) {
		case FIELD_TYPE_TINY:
		case FIELD_TYPE_SHORT:
		case FIELD_TYPE_INT24:
		case FIELD_TYPE_LONG:
			if (theColumn.flags & UNSIGNED_FLAG)
				object = [NSNumber numberWithUnsignedLong:strtoul(theBytes, NULL, 0)];
			else
				object = [NSNumber numberWithLong:strtol(theBytes, NULL, 0)];
			break;
		case FIELD_TYPE_LONGLONG:
			if (theColumn.flags & UNSIGNED_FLAG)
				object = [NSNumber numberWithUnsignedLongLong:strtoull(theBytes, NULL, 0)];
			else
				object = [NSNumber numberWithLongLong:strtoll(theBytes, NULL, 0)];
			break;
		case FIELD_TYPE_DECIMAL:
			object = [NSDecimalNumber decimalNumberWithString:[NSString stringWithCString:theBytes encoding:NSUTF8StringEncoding]];
			break;
		case FIELD_TYPE_FLOAT:
			object = [NSNumber numberWithFloat:atof(theBytes)];
			break;
		case FIELD_TYPE_DOUBLE:
			object = [NSNumber numberWithDouble:atof(theBytes)];
			break;
		case FIELD_TYPE_TIMESTAMP:
		case FIELD_TYPE_DATETIME: {
			NSDateFormatter *formatter = [NSDateFormatter new];
			[formatter setDateFormat:@"yyy-MM-dd HH:mm:ss"];
			[formatter setTimeZone:[connection timeZone]];
			object = [formatter dateFromString:[NSString stringWithCString:theBytes encoding:NSUTF8StringEncoding]];
			[formatter release];
			break;
		}
		case FIELD_TYPE_DATE: {
			NSDateFormatter *formatter = [NSDateFormatter new];
			[formatter setDateFormat:@"yyy-MM-dd"];
			[formatter setTimeZone:[connection timeZone]];
			object = [formatter dateFromString:[NSString stringWithCString:theBytes encoding:NSUTF8StringEncoding]];
			[formatter release];
			break;
		}
		case FIELD_TYPE_TIME: {
			NSDateFormatter *formatter = [NSDateFormatter new];
			[formatter setDateFormat:@"HH:mm:ss"];
			[formatter setTimeZone:[connection timeZone]];
			object = [formatter dateFromString:[NSString stringWithCString:theBytes encoding:NSUTF8StringEncoding]];
			[formatter release];
			break;
		}
		case FIELD_TYPE_YEAR: {
			NSDateFormatter *formatter = [NSDateFormatter new];
			[formatter setDateFormat:@"yyy"];
			[formatter setTimeZone:[connection timeZone]];
			object = [formatter dateFromString:[NSString stringWithCString:theBytes encoding:NSUTF8StringEncoding]];
			[formatter release];
			break;
		}
		case FIELD_TYPE_SET:
		case FIELD_TYPE_ENUM:
		case FIELD_TYPE_VAR_STRING:
		case FIELD_TYPE_STRING:
			object = [NSString stringWithCString:theBytes encoding:NSUTF8StringEncoding];
			break;
		case FIELD_TYPE_NEWDATE:
		case FIELD_TYPE_TINY_BLOB:
		case FIELD_TYPE_BLOB:
		case FIELD_TYPE_MEDIUM_BLOB:
		case FIELD_TYPE_LONG_BLOB:
			if (theColumn.flags & BINARY_FLAG)
				object = [NSData dataWithBytes:theBytes length:theLength];
			else
				object = [NSString stringWithCString:theBytes encoding:NSUTF8StringEncoding];
			break;
		case FIELD_TYPE_NULL:
			object = nil;
			break;
		default:
			object = [NSData dataWithBytes:theBytes length:theLength];
			NSLog(@"Unknown Type %d for Column %s", theColumn.type, theColumn.name);
			break;
	}
	
	if (object==nil) {
		object = [NSNull null];
	}
	return object;
}

- (NSArray *)nextRowAsArray {
	NSMutableArray *rowArray = nil;
	
	if (result!=NULL) {
		rowArray = [NSMutableArray array];
		MYSQL_ROW row = mysql_fetch_row(result);
		if (row==NULL)
			return nil;
		unsigned long *lengths = mysql_fetch_lengths(result);
		MYSQL_FIELD *columns = mysql_fetch_fields(result);
		for (int i=0; i<columnCount; i++) {
			id rowObject;
			if (row[i]==NULL) {
				rowObject = [NSNull null];
			} else {
				char *rowBytes = calloc(sizeof(char),lengths[i]+1);
				memcpy(rowBytes, row[i], lengths[i]);
				rowBytes[lengths[i]] = '\0';
				rowObject = [self objectAtColumn:columns[i] bytes:rowBytes length:lengths[i]];
				free(rowBytes);
			}
			[rowArray addObject:rowObject];
		}
	}
	
	return rowArray;
}
- (NSDictionary *)nextRow {
	NSMutableDictionary *rowDictionary = nil;
	
	if (result!=NULL) {
		rowDictionary = [NSMutableDictionary dictionary];
		MYSQL_ROW row = mysql_fetch_row(result);
		if (row==NULL)
			return nil;
		unsigned long *lengths = mysql_fetch_lengths(result);
		MYSQL_FIELD *columns = mysql_fetch_fields(result);
		for (int i=0; i<columnCount; i++) {
			id rowObject;
			if (row[i]==NULL) {
				rowObject = [NSNull null];
			} else {
				char *rowBytes = calloc(sizeof(char),lengths[i]+1);
				memcpy(rowBytes, row[i], lengths[i]);
				rowBytes[lengths[i]] = '\0';
				rowObject = [self objectAtColumn:columns[i] bytes:rowBytes length:lengths[i]];
				free(rowBytes);
			}
			[rowDictionary setObject:rowObject forKey:[columnNames objectAtIndex:i]];
		}
	}
	
	return rowDictionary;
}

- (void)seekToRow:(my_ulonglong)theRow {
	theRow = (theRow>[self rowCount] ? [self rowCount]-1 : theRow);
	mysql_data_seek(result, theRow);
}
@end
