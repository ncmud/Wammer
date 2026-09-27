//
//  SSStringCoder.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 12/8/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SSStringEncoding;

@interface SSStringCoder : NSObject

// All available string encodings; an array of SSStringEncoding.
+ (NSArray *) availableStringEncodings;

/**
 * Given a localized name, return the matching SSStringEncoding, or the default encoding when no
 * encoding has that name (including the retired "ASCII" preference value).
 */
+ (SSStringEncoding *) encodingFromLocalizedEncodingName:(NSString *)name;

/**
 * UTF-8, used when no preference is saved or the saved name no longer matches an encoding.
 */
+ (SSStringEncoding *) defaultStringEncoding;

/**
 * Read our preference key in NSUserDefaults and return an SSStringEncoding object.
 */
@property (nonatomic, readonly, copy) SSStringEncoding *currentStringEncoding;

#pragma mark - User Commands

/**
 *  Return a data representation of multiple user commands.
 *
 *  @param commands commands to encode
 *
 *  @return encoded command data
 */
- (NSData *) dataForUserCommands:(NSArray *)commands;

#pragma mark - Raw Encode/Decode

/**
 * Decode a block of data using the current encoding preference.
 */
- (NSString *) stringByDecodingDataWithCurrentEncoding:(NSData *)data;

/**
 * Decode data using an arbitrary encoding.
 */
- (NSString *) stringByDecodingData:(NSData *)data withEncoding:(SSStringEncoding *)encoding;

/**
 * Encode a string using the current encoding preference.
 */
- (NSData *) dataByEncodingStringWithCurrentEncoding:(NSString *)str;

/**
 * Encode data using an arbitrary encoding.
 */
- (NSData *) dataByEncodingString:(NSString *)str withEncoding:(SSStringEncoding *)encoding;

@end

@interface SSStringEncoding : NSObject <NSCopying>

typedef NS_ENUM(NSUInteger, kStringEncodingType) {
    kStringEncodingTypeNSStringEncoding,
    kStringEncodingTypeCFStringEncoding,
};

@property (nonatomic, copy, readonly) NSString * localizedName;
@property (nonatomic, assign, readonly) NSUInteger encoding;
@property (nonatomic, assign, readonly) kStringEncodingType encodingType;

/**
 * YES for UTF-8, the only encoding Wammer reports to servers as UTF-8 capable.
 */
@property (nonatomic, readonly) BOOL isUTF8;

- (instancetype) initWithName:(NSString *)name
                     encoding:(NSUInteger)encoding
                         type:(kStringEncodingType)type;

+ (NSComparator) encodingComparator;

@end
