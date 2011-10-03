//
//  MGMMyConnection.m
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

#import "MGMMyConnection.h"
#import "MGMMyResult.h"

@implementation MGMMyConnection
- (id)init {
	if (self = [super init]) {
		timeZone = [[NSTimeZone defaultTimeZone] retain];
		isConnected = NO;
	}
	return self;
}
+ (id)connectionWithHost:(NSString *)theHost port:(int)thePort username:(NSString *)theUsername password:(NSString *)thePassword {
	return [[[self alloc] initWithHost:theHost port:thePort username:theUsername password:thePassword] autorelease];
}
- (id)initWithHost:(NSString *)theHost port:(int)thePort username:(NSString *)theUsername password:(NSString *)thePassword {
	if (self = [self init]) {
		logQuery = NO;
		[self connectWithHost:theHost port:thePort username:theUsername password:thePassword];
		escapeSet = [[NSCharacterSet characterSetWithCharactersInString:@"'\"\\"] retain];
	}
	return self;
}
+ (id)connectionWithSocket:(NSString *)theSocket username:(NSString *)theUsername password:(NSString *)thePassword {
	return [[[self alloc] initWithSocket:theSocket username:theUsername password:thePassword] autorelease];
}
- (id)initWithSocket:(NSString *)theSocket username:(NSString *)theUsername password:(NSString *)thePassword {
	if (self = [self init]) {
		logQuery = NO;
		[self connectWithSocket:theSocket username:theUsername password:thePassword];
		escapeSet = [[NSCharacterSet characterSetWithCharactersInString:@"'\"\\"] retain];
	}
	return self;
}
- (void)dealloc {
	if (isConnected) {
		mysql_close(MySQLConnection);
		MySQLConnection = NULL;
	}
	[timeZone release];
	[super dealloc];
}

- (BOOL)connectWithHost:(NSString *)theHost port:(int)thePort username:(NSString *)theUsername password:(NSString *)thePassword {
	if (isConnected) {
		isConnected = NO;
		mysql_close(MySQLConnection);
		MySQLConnection = NULL;
	}
	if (MySQLConnection==NULL) {
		MySQLConnection = mysql_init(NULL);
	}
	if (MySQLConnection!=NULL) {
		if (thePort==0)
			thePort = 3306;
		if (theHost==nil || [theHost isEqualToString:@""])
			return NO;
		
		const char *username = NULL;
		if (theUsername!=nil || [theUsername isEqualToString:@""])
			username = [theUsername cStringUsingEncoding:NSUTF8StringEncoding];
		const char *password = NULL;
		if (thePassword!=nil || [thePassword isEqualToString:@""])
			password = [thePassword cStringUsingEncoding:NSUTF8StringEncoding];
		
		void *theRet = mysql_real_connect(MySQLConnection, [theHost cStringUsingEncoding:NSUTF8StringEncoding], username, password, NULL, thePort, MYSQL_UNIX_ADDR, CLIENT_COMPRESS);
		isConnected = (theRet==MySQLConnection);
		if (isConnected)
			[self getTimeZone];
	}
	
	return isConnected;
}
- (BOOL)connectWithSocket:(NSString *)theSocket username:(NSString *)theUsername password:(NSString *)thePassword {
	if (isConnected) {
		isConnected = NO;
		mysql_close(MySQLConnection);
		MySQLConnection = NULL;
	}
	if (MySQLConnection==NULL) {
		MySQLConnection = mysql_init(NULL);
	}
	if (MySQLConnection!=NULL) {
		const char *socket = NULL;
		if (theSocket==nil || [theSocket isEqualToString:@""])
			socket = MYSQL_UNIX_ADDR;
		else
			socket = [theSocket cStringUsingEncoding:NSUTF8StringEncoding];
		
		const char *username = NULL;
		if (theUsername!=nil || [theUsername isEqualToString:@""])
			username = [theUsername cStringUsingEncoding:NSUTF8StringEncoding];
		const char *password = NULL;
		if (thePassword!=nil || [thePassword isEqualToString:@""])
			password = [thePassword cStringUsingEncoding:NSUTF8StringEncoding];
		
		void *theRet = mysql_real_connect(MySQLConnection, NULL, username, password, NULL, 0, socket, CLIENT_COMPRESS);
		isConnected = (theRet==MySQLConnection);
		if (isConnected)
			[self getTimeZone];
	}
	
	return isConnected;
}

- (MYSQL *)MySQLConnection {
	return MySQLConnection;
}
- (NSStringEncoding)stringEncodingWithCharSet:(NSString *)theCharSet {
	if ([theCharSet isEqualToString:@"utf8"])
		return NSUTF8StringEncoding;
	if ([theCharSet isEqualToString:@"ucs2"])
		return NSUnicodeStringEncoding;
	if ([theCharSet isEqualToString:@"ascii"])
		return NSASCIIStringEncoding;
	if ([theCharSet isEqualToString:@"latin1"])
		return NSISOLatin1StringEncoding;
	if ([theCharSet isEqualToString:@"macroman"])
		return NSMacOSRomanStringEncoding;
	if ([theCharSet isEqualToString:@"latin2"])
		return NSISOLatin2StringEncoding;
	if ([theCharSet isEqualToString:@"cp1250"])
		return NSWindowsCP1250StringEncoding;
	if ([theCharSet isEqualToString:@"win1250"])
		return NSWindowsCP1250StringEncoding;
	if ([theCharSet isEqualToString:@"cp1257"])
		return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingWindowsBalticRim);
	if ([theCharSet isEqualToString:@"latin5"])
		return NSWindowsCP1254StringEncoding;
	if ([theCharSet isEqualToString:@"greek"])
		return NSWindowsCP1253StringEncoding;
	if ([theCharSet isEqualToString:@"win1251ukr"])
		return NSWindowsCP1251StringEncoding;
	if ([theCharSet isEqualToString:@"cp1251"])
		return NSWindowsCP1251StringEncoding;
	if ([theCharSet isEqualToString:@"koi8_ru"])
		return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingKOI8_R);
	if ([theCharSet isEqualToString:@"koi8_ukr"])
		return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingKOI8_R);
	if ([theCharSet isEqualToString:@"cp1256"])
		return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingWindowsArabic);
	if ([theCharSet isEqualToString:@"hebrew"])
		return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinHebrew);
	if ([theCharSet isEqualToString:@"ujis"])
		return NSJapaneseEUCStringEncoding;
	if ([theCharSet isEqualToString:@"sjis"])
		return NSShiftJISStringEncoding;
	if ([theCharSet isEqualToString:@"big5"])
		return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5);
	if ([theCharSet isEqualToString:@"euc_kr"])
		return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_KR);
	
	return NSISOLatin1StringEncoding;
}

- (BOOL)isConnected {
	return (isConnected ? mysql_ping(MySQLConnection)==0 : NO);
}
- (void)disconnect {
	if (isConnected) {
		mysql_close(MySQLConnection);
		MySQLConnection = NULL;
		isConnected = NO;
	}
}

- (NSString *)errorMessage {
	if (isConnected)
		return [NSString stringWithCString:mysql_error(MySQLConnection) encoding:NSUTF8StringEncoding];
	return nil;
}
- (unsigned int)errorID {
	if (isConnected)
		return mysql_errno(MySQLConnection);
	return 0;
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
				case '0':
					[string appendString:@"\\0"];
					break;
				case '\'':
					[string appendString:@"\\'"];
					break;
				case '"':
					[string appendString:@"\\\""];
					break;
				case '\\':
					[string appendString:@"\\\\"];
					break;
				case '\n':
					[string appendString:@"\\n"];
					break;
				case '\r':
					[string appendString:@"\\r"];
					break;
				default:
					if (character<0x20) {
						[string appendFormat:@"\\u%04x", character];
					} else {
						CFStringAppendCharacters((CFMutableStringRef)string, &character, 1);
					}
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
- (MGMMyResult *)query:(NSString *)format, ... {
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
	if (mysql_query(MySQLConnection, [query cStringUsingEncoding:NSUTF8StringEncoding])!=0)
		return nil;
	return [MGMMyResult resultWithConnection:self];
}

- (my_ulonglong)affectedRows {
	if (isConnected)
		return mysql_affected_rows(MySQLConnection);
	return 0;
}
- (my_ulonglong)insertId {
	if (isConnected)
		return mysql_insert_id(MySQLConnection);
	return 0;
}

- (BOOL)selectDataBase:(NSString *)theDataBase {
	if (theDataBase==nil || [theDataBase isEqualToString:@""])
		return NO;
	
	if (isConnected) {
		if (mysql_select_db(MySQLConnection, [theDataBase cStringUsingEncoding:NSUTF8StringEncoding])!=0)
			return NO;
	}
	return YES;
}
- (MGMMyResult *)dataBases {
	return [self dataBasesLike:nil];
}
- (MGMMyResult *)dataBasesLike:(NSString *)theName {
	MGMMyResult	*theResult = nil;
	const char *name = NULL;
	if (theName!=nil && ![theName isEqualToString:@""])
		name = [theName cStringUsingEncoding:NSUTF8StringEncoding];
	
	MYSQL_RES *result = mysql_list_dbs(MySQLConnection, name);
	if (result!=NULL)
		theResult = [MGMMyResult resultWithConnection:self result:result];
	
	return theResult;
}
- (BOOL)createDataBase:(NSString *)theDataBase {
	if (theDataBase==nil || [theDataBase isEqualToString:@""])
		return NO;
	return ([self query:@"CREATE DATABASE %@", theDataBase]!=nil);
}
- (BOOL)deleteDataBase:(NSString *)theDataBase {
	if (theDataBase==nil || [theDataBase isEqualToString:@""])
		return NO;
	return ([self query:@"DROP DATABASE %@", theDataBase]!=nil);
}
- (MGMMyResult *)tables {
	return [self tablesLike:nil];
}
- (MGMMyResult *)tablesLike:(NSString *)theName {
	MGMMyResult	*theResult = nil;
	const char *name = NULL;
	if (theName!=nil && ![theName isEqualToString:@""])
		name = [theName cStringUsingEncoding:NSUTF8StringEncoding];
	
	MYSQL_RES *result = mysql_list_tables(MySQLConnection, name);
	if (result!=NULL)
		theResult = [MGMMyResult resultWithConnection:self result:result];
	
	return theResult;
}
- (MGMMyResult *)tablesFromDataBase:(NSString *)theDataBase {
	return [self tablesFromDataBase:theDataBase like:nil];
}
- (MGMMyResult *)tablesFromDataBase:(NSString *)theDataBase like:(NSString *)theName {
	MGMMyResult	*theResult = nil;
	
	if (theName==nil || [theName isEqualToString:@""])
		theResult = [self query:@"SHOW TABLES FROM %!", theDataBase];
	else
		theResult = [self query:@"SHOW TABLES FROM %! LIKE %@", theDataBase, theName];
	
	return theResult;
}
- (MGMMyResult *)columnsFromTable:(NSString *)theTable {
	return [self columnsFromTable:theTable like:nil];
}
- (MGMMyResult *)columnsFromTable:(NSString *)theTable like:(NSString *)theName {
	MGMMyResult	*theResult = nil;
	
	if (theName==nil || [theName isEqualToString:@""])
		theResult = [self query:@"SHOW COLUMNS FROM %!", theTable];
	else
		theResult = [self query:@"SHOW COLUMNS FROM %! LIKE %@", theTable, theName];
	
	return theResult;
}

- (NSString *)clientInfo {
	return [NSString stringWithCString:mysql_get_client_info() encoding:NSUTF8StringEncoding];
}
- (NSString *)hostInfo {
	return [NSString stringWithCString:mysql_get_host_info(MySQLConnection) encoding:NSUTF8StringEncoding];
}
- (NSString *)serverInfo {
	if (isConnected)
		return [NSString stringWithCString: mysql_get_server_info(MySQLConnection) encoding:NSUTF8StringEncoding];
	return nil;
}
- (NSNumber *)protoInfo {
	return [NSNumber numberWithUnsignedInt:mysql_get_proto_info(MySQLConnection)];
}
- (NSString *)status {
	return [NSString stringWithCString:mysql_stat(MySQLConnection) encoding:NSUTF8StringEncoding];
}
- (NSNumber *)threadID {
	return [NSNumber numberWithUnsignedLong:mysql_thread_id(MySQLConnection)];
}

- (MGMMyResult *)processes {
	MGMMyResult	*theResult = nil;
	
	MYSQL_RES *result = mysql_list_processes(MySQLConnection);
	if (result!=NULL)
		theResult = [MGMMyResult resultWithConnection:self result:result];
	
	return theResult;
}
- (BOOL)killProcess:(unsigned long)processID {
	int errorCode = mysql_kill(MySQLConnection, processID);
	return (errorCode==0 ? YES : NO);
}

- (NSTimeZone *)timeZone {
	return timeZone;
}
- (void)getTimeZone {
	if ([self isConnected]) {
		MGMMyResult *timeZoneResult = [self query:@"SHOW VARIABLES LIKE '%%time_zone'"];
		NSString *systemTimeZone = nil, *myTimeZone = nil;
		NSArray *row;
		
		while (row = [timeZoneResult nextRowAsArray]) {
			if ([[row objectAtIndex:0] isEqualToString:@"system_time_zone"]) {
				systemTimeZone = [row objectAtIndex:1];
			} else if ([[row objectAtIndex:0] isEqualToString:@"time_zone"]) {
				myTimeZone = [row objectAtIndex:1];
			}
		}
		if (myTimeZone==nil || [myTimeZone isEqualToString:@"SYSTEM"]) {
			if (systemTimeZone==nil) {
				timeZoneResult = [self query:@"SHOW VARIABLES LIKE 'timezone'"];
				row = [timeZoneResult nextRowAsArray];
				if (row!=nil) {
					myTimeZone = [row objectAtIndex:1];
				}
			} else {
				myTimeZone = systemTimeZone;
			}
		}
		if (myTimeZone!=nil) {
			if (timeZone!=nil) {
				[timeZone release];
				timeZone = nil;
			}
			timeZone = [[NSTimeZone timeZoneWithName:myTimeZone] retain];
		}
	}
}
@end
