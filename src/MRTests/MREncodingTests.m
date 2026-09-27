//
//  MREncodingTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/26/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "MRTestHelpers.h"
#import "SSStringCoder.h"

@interface MREncodingTests : XCTestCase

@end

@implementation MREncodingTests
{
    SSStringCoder *sut;
    SSStringEncoding *utf8Coding;
    NSString *testStr;
    NSData *testData;
}

- (void)setUp {
    [super setUp];
    sut = [SSStringCoder new];
    utf8Coding = [SSStringCoder defaultStringEncoding];
    testStr = @"Hello World";
    testData = [testStr dataUsingEncoding:NSASCIIStringEncoding];
}

- (void)tearDown {
    [super tearDown];
    sut = nil;
}

- (void)testHasDefaultEncodings {
    expect([SSStringCoder availableStringEncodings].count).to.beGreaterThan(0);
    expect(utf8Coding.isUTF8).to.beTruthy();
}

- (void)testDefaultsToUTF8 {
    expect(sut.currentStringEncoding).to.equal(utf8Coding);
}

- (void)testRetiredASCIIPreferenceResolvesToUTF8 {
    expect([SSStringCoder encodingFromLocalizedEncodingName:@"ASCII"]).to.equal(utf8Coding);
}

- (void)testUnknownEncodingNameResolvesToUTF8 {
    expect([SSStringCoder encodingFromLocalizedEncodingName:@"Not An Encoding"]).to.equal(utf8Coding);
}

- (void)testDecodesUTF8BoxDrawing {
    NSString *frame = @"\u2554\u2550\u2557 \u2022 \u2014";
    NSData *data = [frame dataUsingEncoding:NSUTF8StringEncoding];
    expect([sut stringByDecodingData:data withEncoding:utf8Coding]).to.equal(frame);
}

- (void)testDecodesASCIIString {
    expect([sut stringByDecodingDataWithCurrentEncoding:testData]).to.equal(testStr);
}

- (void)testEncodesASCIIString {
    expect([sut dataByEncodingStringWithCurrentEncoding:testStr]).to.equal(testData);
}

- (void)testUserCommandData {
    NSData *data = [@"Hello\r\nHi\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    expect([sut dataForUserCommands:@[ @"Hello", @"Hi" ]]).to.equal(data);
}

@end
