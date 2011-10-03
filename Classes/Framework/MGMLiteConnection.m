//
//  MGMLiteConnection.m
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

#import "MGMLiteConnection.h"
#import "MGMLiteResult.h"

@implementation MGMLiteConnection
+ (id)memoryConnection {
	return [[[self alloc] initWithPath:@":memory:"] autorelease];
}
+ (id)connectionWithPath:(NSString *)thePath {
	return [[[self alloc] initWithPath:thePath] autorelease];
}
- (id)initWithPath:(NSString *)thePath {
	if (self = [super init]) {
		logQuery = NO;
		path = [thePath copy];
		int result = SQLITE_INTERNAL;
		result = sqlite3_open([path UTF8String], &SQLiteConnection);
		if (result!=SQLITE_OK) {
			[self release];
			self = nil;
		} else {
			escapeSet = [[NSCharacterSet characterSetWithCharactersInString:@"'"] retain];
		}
	}
	return self;
}
- (void)dealloc {
	if (SQLiteConnection!=NULL) {
		int result = sqlite3_close(SQLiteConnection);
		if (result!=SQLITE_OK)
			NSLog(@"Unable to close the SQLite Database %@", path);
	}
	if (path!=nil)
		[path release];
	if (escapeSet!=nil)
		[escapeSet release];
	[super dealloc];
}

- (sqlite3 *)SQLiteConnection {
	return SQLiteConnection;
}
- (NSString *)path {
	return path;
}

- (NSString *)errorMessage {
	return [NSString stringWithCString:sqlite3_errmsg(SQLiteConnection) encoding:NSUTF8StringEncoding];
}
- (int)errorID {
	return sqlite3_errcode(SQLiteConnection);
}

- (NSString *)escapeData:(NSData *)theData {
	static const char hexdigits[] = "0123456789ABCDEF";
	const size_t length = [theData length];
	const char *bytes = [theData bytes];
	char *stringBuffer = (char *)malloc(length * 2 + 1);
	char *hexBuffer = stringBuffer;
	
	for (int i=0; i<length; i++) {
		*hexBuffer++ = hexdigits[(*bytes >> 4) & 0xF];
		*hexBuffer++ = hexdigits[*bytes & 0xF];
		bytes++;
	}
	*hexBuffer = '\0';
	NSString *hex = [NSString stringWithUTF8String:stringBuffer];
	free(stringBuffer);
	return hex;
}
- (NSString *)escapeString:(NSString *)theString {
	if (theString==nil)
		return nil;
	NSRange range = [theString rangeOfCharacterFromSet:escapeSet];
	NSMutableString *string = [NSMutableString string];
	if (range.location==NSNotFound) {
		[string appendString:theString];
	} else {
		unsigned long len = [theString length];
		for (unsigned long i=0; i<len; i++) {
			unichar character = [theString characterAtIndex:i];
			switch (character) {
				case '\'':
					[string appendString:@"''"];
					break;
				default:
					CFStringAppendCharacters((CFMutableStringRef)string, &character, 1);
					break;
			}
		}
	}
	return string;
}
- (NSString *)quoteObject:(id)theObject {
	if (theObject==nil || [theObject isKindOfClass:[NSNull class]])
		return @"NULL";
	
	if ([theObject isKindOfClass:[NSData class]])
		return [NSString stringWithFormat:@"X'%@'", [self escapeData:(NSData *)theObject]];
	if ([theObject isKindOfClass:[NSString class]])
		return [NSString stringWithFormat:@"'%@'", [self escapeString:(NSString *)theObject]];
	if ([theObject isKindOfClass:[NSNumber class]])
		return [NSString stringWithFormat:@"%@", theObject];
	if ([theObject isKindOfClass:[NSCalendarDate class]])
		return [NSString stringWithFormat:@"'%@'", [(NSCalendarDate *)theObject descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S"]];
	
	return [NSString stringWithFormat:@"'%@'", [self escapeString:[theObject description]]];
}
- (NSString *)quoteChar:(const char *)theChar {
	NSString *string = [NSString stringWithUTF8String:theChar];
	return  [self quoteObject:string];
}

- (BOOL)logQuery {
	return logQuery;
}
- (void)setLogQuery:(BOOL)shouldLogQuery {
	logQuery = shouldLogQuery;
}
- (MGMLiteResult *)query:(NSString *)format, ... {
	va_list ap;
	va_start(ap, format);
	if (format==nil)
		return nil;
	NSMutableString *query = [NSMutableString string];
	NSString *currentFormat = format;
	NSRange range = [currentFormat rangeOfString:@"%"];
	while (range.location!=NSNotFound) {
		int offset = 1;
		[query appendString:[currentFormat substringWithRange:NSMakeRange(0, range.location)]];
		unichar character = [currentFormat characterAtIndex:range.location+offset];
		switch (character) {
			case '@':
				[query appendString:[self quoteObject:va_arg(ap, id)]];
				break;
			case '!':
				[query appendString:[va_arg(ap, id) description]];
				break;
			case 's':
				[query appendString:[self quoteChar:va_arg(ap, const char *)]];
				break;
			case '$':
				[query appendFormat:@"%s", va_arg(ap, const char *)];
				break;
			case '%':
				[query appendString:@"%"];
				break;
			case 'd':
			case 'D':
			case 'i':
				[query appendFormat:@"%d", va_arg(ap, int)];
				break;
			case 'u':
			case 'U':
				[query appendFormat:@"%u", va_arg(ap, unsigned int)];
				break;
			case 'h': {
				offset++;
				unichar character = [currentFormat characterAtIndex:range.location+offset];
				if (character=='i')
					[query appendFormat:@"%hi", va_arg(ap, int)];
				else if (character=='u')
					[query appendFormat:@"%hu", va_arg(ap, unsigned int)];
				else goto invalid;
				break;
			}
			case 'q': {
				offset++;
				unichar character = [currentFormat characterAtIndex:range.location+offset];
				if (character=='i')
					[query appendFormat:@"%qi", va_arg(ap, long long)];
				else if (character=='u')
					[query appendFormat:@"%qu", va_arg(ap, unsigned long long)];
				else if (character=='x')
					[query appendFormat:@"%qx", va_arg(ap, unsigned long long)];
				else if (character=='X')
					[query appendFormat:@"%qX", va_arg(ap, unsigned long long)];
				else goto invalid;
				break;
			}
			case 'x':
				[query appendFormat:@"%x", va_arg(ap, unsigned int)];
				break;
			case 'X':
				[query appendFormat:@"%X", va_arg(ap, unsigned int)];
				break;
			case 'o':
			case 'O':
				[query appendFormat:@"%o", va_arg(ap, unsigned int)];
				break;
			case 'f':
				[query appendFormat:@"%f", va_arg(ap, double)];
				break;
			case 'e':
				[query appendFormat:@"%e", va_arg(ap, double)];
				break;
			case 'E':
				[query appendFormat:@"%E", va_arg(ap, double)];
				break;
			case 'g':
				[query appendFormat:@"%g", va_arg(ap, double)];
				break;
			case 'G':
				[query appendFormat:@"%G", va_arg(ap, double)];
				break;
			case 'c':
				[query appendFormat:@"%c", va_arg(ap, unsigned int)];
				break;
			case 'C':
				[query appendFormat:@"%C", va_arg(ap, int)];
				break;
			case 'p':
				[query appendFormat:@"%p", va_arg(ap, void *)];
				break;
			case 'a':
				[query appendFormat:@"%a", va_arg(ap, double)];
				break;
			case 'A':
				[query appendFormat:@"%A", va_arg(ap, double)];
				break;
			case 'F':
				[query appendFormat:@"%F", va_arg(ap, double)];
				break;
			case '.': {
				NSMutableString *format = [NSMutableString stringWithString:@"%."];
				NSCharacterSet *set = [NSCharacterSet decimalDigitCharacterSet];
				offset++;
				unichar character = [currentFormat characterAtIndex:range.location+offset];
				while ([set characterIsMember:character]) {
					CFStringAppendCharacters((CFMutableStringRef)format, &character, 1);
					offset++;
					character = [currentFormat characterAtIndex:range.location+offset];
				}
				if (character=='f')
					CFStringAppendCharacters((CFMutableStringRef)format, &character, 1);
				else goto invalid;
				[query appendFormat:format, va_arg(ap, double)];
				break;
			}
			case '0'...'9': {
				NSMutableString *format = [NSMutableString stringWithString:@"%"];
				NSCharacterSet *set = [NSCharacterSet decimalDigitCharacterSet];
				unichar character = [currentFormat characterAtIndex:range.location+offset];
				while ([set characterIsMember:character]) {
					CFStringAppendCharacters((CFMutableStringRef)format, &character, 1);
					offset++;
					character = [currentFormat characterAtIndex:range.location+offset];
				}
				if (character=='x' || character=='X')
					CFStringAppendCharacters((CFMutableStringRef)format, &character, 1);
				else goto invalid;
				[query appendFormat:format, va_arg(ap, unsigned int)];
				break;
			}
			default:
				goto invalid;
		}
		goto good;
	invalid:
		NSLog(@"Query: Invalid format.");
		return nil;
	good:
		offset++;
		currentFormat = [currentFormat substringWithRange:NSMakeRange(range.location+offset, [currentFormat length]-(range.location+offset))];
		range = [currentFormat rangeOfString:@"%"];
	}
	[query appendString:[currentFormat substringWithRange:NSMakeRange(0, [currentFormat length])]];
	va_end(ap);
	
	query = [[query copy] autorelease];
	
	if (logQuery)
		NSLog(@"Query: %@", query);
	
	if (query==nil || [query isEqualToString:@""])
		return nil;
	sqlite3_stmt *result;
	int status = sqlite3_prepare(SQLiteConnection, [query UTF8String], -1, &result, NULL);
	if (status!=SQLITE_OK)
		return nil;
	return [MGMLiteResult resultWithConnection:self result:result];
}
- (MGMLiteResult *)tables {
	return [self tablesLike:nil];
}
- (MGMLiteResult *)tablesLike:(NSString *)theName {
	MGMLiteResult *theResult = nil;
	
	if (theName==nil || [theName isEqualToString:@""])
		theResult = [self query:@"SELECT name FROM sqlite_master WHERE type='table'"];
	else
		theResult = [self query:@"SELECT name FROM sqlite_master WHERE type='table' AND name LIKE %@", theName];
	
	return theResult;
}
- (MGMLiteResult *)columnsFromTable:(NSString *)theTable {
	return [self query:@"PRAGMA table_info(%@)", theTable];
}

- (int)affectedRows {
	return sqlite3_changes(SQLiteConnection);
}
- (long long int)insertId {
	return sqlite3_last_insert_rowid(SQLiteConnection);
}
@end