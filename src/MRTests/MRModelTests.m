//
//  MRModelTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/14/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

// Core Data model tests have been replaced by MUDModelTests.swift
// which tests the Swift Codable models directly.

#import "MRTestHelpers.h"
#import "MUDModels.h"
#import "WorldStoreBridge.h"

@interface MRModelTests : XCTestCase

@end

@implementation MRModelTests
{
    MUDWorld *world;
    MUDGag *gag;
    MUDTrigger *trigger;
    NSString *worldIdentifier;
}

- (void)setUp {
    [super setUp];

    world = [[MUDWorld alloc] init];
    world.name = @"Test";

    gag = [[MUDGag alloc] init];
    gag.gag = @"Test";
    world.gags = [world.gags arrayByAddingObject:gag];

    trigger = [[MUDTrigger alloc] init];
    trigger.trigger = @"Test";
    world.triggers = [world.triggers arrayByAddingObject:trigger];

    [WorldStoreBridge addMUDWorld:world];
    worldIdentifier = world.identifier;
}

- (void)tearDown {
    [super tearDown];

    if (worldIdentifier) {
        [WorldStoreBridge removeWorldWithIdentifier:worldIdentifier];
    }
}

#pragma mark - Gags

- (void)testGagMatchesLine {
    gag.gag = @"World";
    gag.gagType = MUDGagTypeStartOfLine;

    EXP_expect([gag matchesLine:@"Hello World"]).to.beFalsy();

    gag.gagType = MUDGagTypeLineContains;

    EXP_expect([gag matchesLine:@"Hello World"]).to.beTruthy();

    gag.gag = @"World";
    gag.gagType = MUDGagTypeStartOfLine;

    EXP_expect([gag matchesLine:@"Hello World"]).to.beFalsy();
    EXP_expect([gag matchesLine:@"World"]).to.beTruthy();

    gag.gagType = MUDGagTypeLineEquals;

    EXP_expect([gag matchesLine:@"World"]).to.beTruthy();
    EXP_expect([gag matchesLine:@"Hello World"]).to.beFalsy();
    EXP_expect([gag matchesLine:@"World World"]).to.beFalsy();
}

#pragma mark - Triggers

- (void)testTriggerMatchesLine {
    trigger.trigger = @"World";

    EXP_expect([trigger matchesLine:@"Hello World"]).to.beTruthy();

    trigger.trigger = @"World";

    EXP_expect([trigger matchesLine:@"Hello World"]).to.beTruthy();
    EXP_expect([trigger matchesLine:@"World"]).to.beTruthy();
}

@end
