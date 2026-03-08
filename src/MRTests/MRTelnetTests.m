//
//  MRTelnetTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 6/5/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "MRTestHelpers.h"
#import "SPLTelnetLib.h"
#import "SSStringCoder.h"
#import "SSMRConstants.h"
#import "libtelnet.h"

@interface MRTelnetTests : XCTestCase

@end

@implementation MRTelnetTests
{
    SPLTelnetLib *sut;
    OCMockObject *stringCoderMock;
    OCMockObject *telnetDelegateMock;
}

- (void)setUp {
    [super setUp];

    stringCoderMock = OCMClassMock([SSStringCoder class]);
    telnetDelegateMock = OCMProtocolMock(@protocol(SPLTelnetLibDelegate));
    sut = [[SPLTelnetLib alloc] initWithStringCoder:(SSStringCoder *)stringCoderMock];
    sut.delegate = (id <SPLTelnetLibDelegate>)telnetDelegateMock;

    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPrefSimpleTelnetMode];
}

- (void)tearDown {
    sut.delegate = nil;
    sut = nil;

    [super tearDown];
}

- (void)testEchoesTextByDefault {
    expect(sut.shouldEchoText).to.beTruthy();
}

- (void)testConnectingSendsInitialOptions {
    for (NSUInteger i = 0; i < 3; i++) {
        [[telnetDelegateMock expect] telnetLibrary:sut mustSendData:OCMOCK_ANY];
    }

    [sut socketDidConnect];

    [telnetDelegateMock verifyWithDelay:1];
}

- (void)testReceivingDataParsesToString {
    NSString *testStr = @"Hello World";

    [[telnetDelegateMock expect] telnetLibrary:sut shouldPrintString:testStr];
    OCMStub([(SSStringCoder *)stringCoderMock stringByDecodingDataWithCurrentEncoding:OCMOCK_ANY]).andReturn(testStr);

    [sut receivedSocketData:[testStr dataUsingEncoding:NSUTF8StringEncoding]];

    [telnetDelegateMock verifyWithDelay:1];
}

- (void)testSendingCommandsForwardsDataToSocket {
    NSString *testStr = @"Yo Dawg";
    NSData *testData = [testStr dataUsingEncoding:NSASCIIStringEncoding];

    [[telnetDelegateMock expect] telnetLibrary:sut mustSendData:testData];
    OCMStub([(SSStringCoder *)stringCoderMock dataForUserCommands:OCMOCK_ANY]).andReturn(testData);

    [sut sendUserCommands:@[ testStr ]];

    [telnetDelegateMock verifyWithDelay:1];
}

- (void)testNAWSSendsSocketData {
    [[telnetDelegateMock expect] telnetLibrary:sut mustSendData:OCMOCK_ANY];

    [sut sendNAWSWithSize:CGSizeMake(80, 80)];

    [telnetDelegateMock verifyWithDelay:1];
}

- (void)testReceivingEchoCommandChangesEchoStatus {
    expect(sut.shouldEchoText).to.beTruthy();

    [[telnetDelegateMock reject] telnetLibrary:sut shouldPrintString:OCMOCK_ANY];

    unsigned char onBytes[] = { TELNET_IAC, TELNET_WILL, TELNET_TELOPT_ECHO };
    NSData *onData = [NSData dataWithBytes:onBytes length:3];

    [sut receivedSocketData:onData];

    expect(sut.shouldEchoText).to.beFalsy();

    unsigned char offBytes[] = { TELNET_IAC, TELNET_WONT, TELNET_TELOPT_ECHO };
    NSData *offData = [NSData dataWithBytes:offBytes length:3];

    [sut receivedSocketData:offData];

    expect(sut.shouldEchoText).to.beTruthy();
    [telnetDelegateMock verify];
}

- (void)testReceivingTTYPECommandSendsTTYPE {
    unsigned char ttBytes[] = { TELNET_IAC, TELNET_DO, TELNET_TELOPT_TTYPE };
    NSData *ttData = [NSData dataWithBytes:ttBytes length:3];

    [[telnetDelegateMock expect] telnetLibrary:sut mustSendData:OCMOCK_ANY];
    [[telnetDelegateMock reject] telnetLibrary:sut shouldPrintString:OCMOCK_ANY];

    [sut receivedSocketData:ttData];

    [telnetDelegateMock verifyWithDelay:1];
}

#pragma mark - GMCP

#define TELNET_TELOPT_GMCP 201

- (void)testGMCPNegotiationRespondsToWill {
    // Server sends IAC WILL GMCP, client should respond with IAC DO GMCP
    [[telnetDelegateMock expect] telnetLibrary:sut mustSendData:OCMOCK_ANY];
    [[telnetDelegateMock reject] telnetLibrary:sut shouldPrintString:OCMOCK_ANY];

    unsigned char willGMCP[] = { TELNET_IAC, TELNET_WILL, TELNET_TELOPT_GMCP };
    [sut receivedSocketData:[NSData dataWithBytes:willGMCP length:3]];

    [telnetDelegateMock verifyWithDelay:1];
}

- (void)testGMCPSubnegotiationWithJSON {
    // Server sends IAC SB 201 "char.vitals {"hp":50,"maxhp":100}" IAC SE
    NSString *payload = @"char.vitals {\"hp\":50,\"maxhp\":100}";
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];

    NSMutableData *packet = [NSMutableData data];
    unsigned char header[] = { TELNET_IAC, TELNET_SB, TELNET_TELOPT_GMCP };
    unsigned char footer[] = { TELNET_IAC, TELNET_SE };
    [packet appendBytes:header length:3];
    [packet appendData:payloadData];
    [packet appendBytes:footer length:2];

    // Must first negotiate GMCP so libtelnet knows to accept subneg
    unsigned char willGMCP[] = { TELNET_IAC, TELNET_WILL, TELNET_TELOPT_GMCP };
    // Allow the DO response
    [[telnetDelegateMock stub] telnetLibrary:sut mustSendData:OCMOCK_ANY];
    [sut receivedSocketData:[NSData dataWithBytes:willGMCP length:3]];

    [[telnetDelegateMock expect] telnetLibrary:sut
                            receivedGMCPModule:@"char.vitals"
                                          data:[OCMArg checkWithBlock:^BOOL(NSDictionary *data) {
        return [data[@"hp"] intValue] == 50 && [data[@"maxhp"] intValue] == 100;
    }]];

    [sut receivedSocketData:packet];

    [telnetDelegateMock verifyWithDelay:1];
}

- (void)testGMCPSubnegotiationWithoutPayload {
    // Some GMCP modules have no JSON payload (just a module name)
    NSString *payload = @"Core.Goodbye";
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];

    NSMutableData *packet = [NSMutableData data];
    unsigned char header[] = { TELNET_IAC, TELNET_SB, TELNET_TELOPT_GMCP };
    unsigned char footer[] = { TELNET_IAC, TELNET_SE };
    [packet appendBytes:header length:3];
    [packet appendData:payloadData];
    [packet appendBytes:footer length:2];

    unsigned char willGMCP[] = { TELNET_IAC, TELNET_WILL, TELNET_TELOPT_GMCP };
    [[telnetDelegateMock stub] telnetLibrary:sut mustSendData:OCMOCK_ANY];
    [sut receivedSocketData:[NSData dataWithBytes:willGMCP length:3]];

    [[telnetDelegateMock expect] telnetLibrary:sut
                            receivedGMCPModule:@"Core.Goodbye"
                                          data:[OCMArg checkWithBlock:^BOOL(NSDictionary *data) {
        return [data count] == 0;
    }]];

    [sut receivedSocketData:packet];

    [telnetDelegateMock verifyWithDelay:1];
}

- (void)testGMCPSubnegotiationWithInvalidJSON {
    // Invalid JSON should still call delegate with the module name and empty dict
    NSString *payload = @"char.vitals {not valid json}";
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];

    NSMutableData *packet = [NSMutableData data];
    unsigned char header[] = { TELNET_IAC, TELNET_SB, TELNET_TELOPT_GMCP };
    unsigned char footer[] = { TELNET_IAC, TELNET_SE };
    [packet appendBytes:header length:3];
    [packet appendData:payloadData];
    [packet appendBytes:footer length:2];

    unsigned char willGMCP[] = { TELNET_IAC, TELNET_WILL, TELNET_TELOPT_GMCP };
    [[telnetDelegateMock stub] telnetLibrary:sut mustSendData:OCMOCK_ANY];
    [sut receivedSocketData:[NSData dataWithBytes:willGMCP length:3]];

    [[telnetDelegateMock expect] telnetLibrary:sut
                            receivedGMCPModule:@"char.vitals"
                                          data:[OCMArg checkWithBlock:^BOOL(NSDictionary *data) {
        return [data count] == 0;
    }]];

    [sut receivedSocketData:packet];

    [telnetDelegateMock verifyWithDelay:1];
}

- (void)testGMCPDoesNotPrintToTerminal {
    // GMCP data should never appear as printed text
    NSString *payload = @"room.info {\"num\":3001}";
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];

    NSMutableData *packet = [NSMutableData data];
    unsigned char header[] = { TELNET_IAC, TELNET_SB, TELNET_TELOPT_GMCP };
    unsigned char footer[] = { TELNET_IAC, TELNET_SE };
    [packet appendBytes:header length:3];
    [packet appendData:payloadData];
    [packet appendBytes:footer length:2];

    unsigned char willGMCP[] = { TELNET_IAC, TELNET_WILL, TELNET_TELOPT_GMCP };
    [[telnetDelegateMock stub] telnetLibrary:sut mustSendData:OCMOCK_ANY];
    [sut receivedSocketData:[NSData dataWithBytes:willGMCP length:3]];

    [[telnetDelegateMock reject] telnetLibrary:sut shouldPrintString:OCMOCK_ANY];
    [[telnetDelegateMock expect] telnetLibrary:sut
                            receivedGMCPModule:OCMOCK_ANY
                                          data:OCMOCK_ANY];

    [sut receivedSocketData:packet];

    [telnetDelegateMock verifyWithDelay:1];
}

@end
