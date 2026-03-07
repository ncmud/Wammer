//
//  MRTimerTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/23/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "MRTestHelpers.h"
#import "SPLTimerManager.h"
#import "SPLWorldTickerManager.h"
#import "Wammer-Swift.h"

@interface MRTimerTests : XCTestCase

@end

@implementation MRTimerTests
{
    SPLWorldTickerManager *tickerManager;
    SPLTimerManager *timerManager;
    NSString *timerName;
    NSString *worldIdentifier;
}

- (void)setUp {
    [super setUp];

    timerManager = [SPLTimerManager new];
    timerName = @"TimerTest";
    tickerManager = [[SPLWorldTickerManager alloc] initWithTimerManager:timerManager];

    // Create a world with a ticker in WorldStore
    [WorldStoreBridge addWorldWithHostname:@"ticker-test.org" name:@"TickerTest" port:23];
    NSArray<MUDWorldBridge *> *worlds = [WorldStoreBridge allWorlds];
    for (MUDWorldBridge *w in worlds) {
        if ([w.hostname isEqualToString:@"ticker-test.org"]) {
            worldIdentifier = w.identifier;
            break;
        }
    }

    // Add a ticker to the world
    [WorldStoreBridge addTickerToWorldIdentifier:worldIdentifier commands:@"hi" interval:1 isEnabled:YES];
}

- (void)tearDown {
    [super tearDown];
    [timerManager cancelRepeatingTimerWithName:timerName];
    timerManager = nil;
    tickerManager = nil;

    if (worldIdentifier) {
        [WorldStoreBridge removeWorldWithIdentifier:worldIdentifier];
        worldIdentifier = nil;
    }
}

#pragma mark - Timers

- (void)testSchedulesTimer {
    XCTestExpectation *timerExp = [self expectationWithDescription:@"Timer"];
    __block NSUInteger count = 0;

    [timerManager scheduleRepeatingTimerWithName:timerName interval:1 block:^{
        count++;
    }];

    expect([timerManager intervalForTimerWithName:timerName]).to.equal(1);
    expect([timerManager isTickerEnabledWithIdentifier:timerName]).to.beTruthy();

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        expect(count).to.beGreaterThanOrEqualTo(3);
        [timerExp fulfill];
    });

    [self waitForExpectationsWithTimeout:5 handler:nil];

    [timerManager cancelRepeatingTimerWithName:timerName];
}

- (void)testCancelsTimer {
    XCTestExpectation *cancelExp = [self expectationWithDescription:@"CancelTimer"];

    [timerManager scheduleRepeatingTimerWithName:timerName
                                        interval:1
                                           block:^{
                                               XCTFail(@"Timer called!");
                                           }];

    expect([timerManager isTickerEnabledWithIdentifier:timerName]).to.beTruthy();

    [timerManager cancelRepeatingTimerWithName:timerName];

    expect([timerManager isTickerEnabledWithIdentifier:timerName]).to.beFalsy();

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [cancelExp fulfill];
    });

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#pragma mark - Tickers

- (void)testEnablingTickerSchedulesTimer {
    XCTestExpectation *tickerExp = [self expectationWithDescription:@"TickerFire"];

    NSArray<MUDTickerBridge *> *tickers = [WorldStoreBridge tickersForWorldIdentifier:worldIdentifier];

    expect(tickers.count).to.beGreaterThan(0);

    NSUInteger identifier = [tickerManager enableAndObserveTickersForWorldIdentifier:worldIdentifier
     tickerBlock:^(NSString *tickerId, NSString *worldId) {
         [tickerExp fulfill];
     }];

    expect(identifier).to.beGreaterThan(0);

    [self waitForExpectationsWithTimeout:2 handler:nil];

    [tickerManager disableTickersForIdentifier:identifier];
}

- (void)testDisablingTickersDoesNotCallTimer {
    XCTestExpectation *tickerExp = [self expectationWithDescription:@"TickerNotFire"];

    NSArray<MUDTickerBridge *> *tickers = [WorldStoreBridge tickersForWorldIdentifier:worldIdentifier];

    expect(tickers.count).to.beGreaterThan(0);

    NSUInteger identifier = [tickerManager enableAndObserveTickersForWorldIdentifier:worldIdentifier
                                                                         tickerBlock:^(NSString *tickerId, NSString *worldId) {
                                                                             XCTFail(@"Called ticker!");
                                                                         }];

    expect(identifier).to.beGreaterThan(0);

    [tickerManager disableTickersForIdentifier:identifier];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tickerExp fulfill];
    });

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
