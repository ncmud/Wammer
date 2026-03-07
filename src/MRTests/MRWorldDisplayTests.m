//
//  MRWorldDisplayTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/25/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "MRTestHelpers.h"
#import "SSWorldDisplayController.h"
#import "SSClientContainer.h"
#import "Wammer-Swift.h"

@interface MRWorldDisplayTests : XCTestCase

@end

@implementation MRWorldDisplayTests
{
    SSWorldDisplayController *worldController;
    NSString *mudWorldIdentifier;
}

- (void)setUp {
    [super setUp];
    worldController = [SSWorldDisplayController new];

    [WorldStoreBridge addWorldWithHostname:@"nanvaent.org" name:@"" port:23];
    NSArray<MUDWorldBridge *> *worlds = [WorldStoreBridge allWorlds];
    for (MUDWorldBridge *w in worlds) {
        if ([w.hostname isEqualToString:@"nanvaent.org"] && w.port == 23) {
            mudWorldIdentifier = w.identifier;
            break;
        }
    }
}

- (void)tearDown {
    [super tearDown];

    if (mudWorldIdentifier) {
        [WorldStoreBridge removeWorldWithIdentifier:mudWorldIdentifier];
    }

    worldController = nil;
}

- (void)testAddsSingleWorld {
    expect(worldController.numberOfClients).to.equal(0);

    [worldController addClientWithWorld:mudWorldIdentifier];

    expect(worldController.numberOfClients).to.equal(1);
    expect(worldController.selectedIndex).to.equal(0);

    [worldController selectNextWorld];

    expect(worldController.selectedIndex).to.equal(0);
}

- (void)testRemovesSingleWorld {
    [worldController addClientWithWorld:mudWorldIdentifier];

    expect(worldController.numberOfClients).to.equal(1);
    expect(worldController.selectedIndex).to.equal(0);

    [worldController removeClientAtIndex:0];

    expect(worldController.selectedIndex).to.equal(0);
    expect(worldController.numberOfClients).to.equal(0);
}

- (void)testClientIndexAccess {
    [worldController addClientWithWorld:mudWorldIdentifier];

    SSClientViewController *client = worldController.currentVisibleClient;

    expect([client isKindOfClass:[SSClientViewController class]]).to.beTruthy();
    expect([worldController clientAtIndex:0]).to.equal(client);
    expect([worldController indexOfClient:client]).to.equal(0);
}

@end
