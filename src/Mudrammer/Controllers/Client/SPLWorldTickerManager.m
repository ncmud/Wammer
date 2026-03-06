//
//  SPLWorldTickerManager.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 7/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SPLWorldTickerManager.h"
#import "WorldStoreBridge.h"
#import "SPLTimerManager.h"

@interface SPLWorldTickerData : NSObject

@property (nonatomic, copy) NSString *worldIdentifier;
@property (nonatomic, strong) NSMutableArray *tickerTimerNames;
@property (nonatomic, assign) NSUInteger identifierPrefix;
@property (nonatomic, copy) SPLTickerFireBlock tickerBlock;
@property (nonatomic, weak) SPLTimerManager *timerManager;

- (NSString *)timerNameForTickerIdentifier:(NSString *)tickerIdentifier;
- (void)enableTickerBridge:(MUDTickerBridge *)ticker;
- (void)disableTickerBridge:(MUDTickerBridge *)ticker;

@end

@interface SPLWorldTickerManager ()

@property (nonatomic, strong) NSMutableDictionary *tickerDataMap;
@property (nonatomic, assign) NSUInteger lastIdentifier;
@property (nonatomic, strong) SPLTimerManager *timerManager;

@end

@implementation SPLWorldTickerManager

- (instancetype)initWithTimerManager:(SPLTimerManager *)timerManager {
    if ((self = [super init])) {
        _tickerDataMap = [NSMutableDictionary new];

        _lastIdentifier = 0;
        _timerManager = timerManager;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(worldStoreDidChange:)
                                                     name:WorldStoreBridge.didChangeNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Observing Tickers

- (NSUInteger)enableAndObserveTickersForWorldIdentifier:(NSString *)worldIdentifier
                                            tickerBlock:(SPLTickerFireBlock)tickerBlock {

    self.lastIdentifier++;

    DLog(@"starting tickers %@", @(self.lastIdentifier));

    SPLWorldTickerData *data = [SPLWorldTickerData new];
    data.worldIdentifier = worldIdentifier;
    data.tickerTimerNames = [NSMutableArray new];
    data.tickerBlock = tickerBlock;
    data.identifierPrefix = self.lastIdentifier;
    data.timerManager = self.timerManager;

    NSArray<MUDTickerBridge *> *tickers = [WorldStoreBridge tickersForWorldIdentifier:worldIdentifier];

    for (MUDTickerBridge *ticker in tickers) {
        if (!ticker.isEnabled) {
            continue;
        }

        [data enableTickerBridge:ticker];
    }

        self.tickerDataMap[@(self.lastIdentifier)] = data;

    return self.lastIdentifier;
}

- (void)disableTickersForIdentifier:(NSUInteger)identifier {
    DLog(@"Stopping tickers %@", @(identifier));
    SPLWorldTickerData *data = self.tickerDataMap[@(identifier)];

    for (NSString *timerName in data.tickerTimerNames) {
        [self.timerManager cancelRepeatingTimerWithName:timerName];
    }

    [self.tickerDataMap removeObjectForKey:@(identifier)];
}

#pragma mark - WorldStore Change Notification

- (void)worldStoreDidChange:(NSNotification *)notification {
    // Re-sync all active ticker sets with current world data
    NSArray *allKeys = [self.tickerDataMap allKeys];

    for (NSNumber *key in allKeys) {
        SPLWorldTickerData *data = self.tickerDataMap[key];
        if (!data) continue;

        NSArray<MUDTickerBridge *> *currentTickers = [WorldStoreBridge tickersForWorldIdentifier:data.worldIdentifier];

        // Build set of current ticker identifiers
        NSMutableSet *currentIds = [NSMutableSet set];
        NSMutableDictionary *tickersByIdentifier = [NSMutableDictionary dictionary];
        for (MUDTickerBridge *t in currentTickers) {
            [currentIds addObject:t.identifier];
            tickersByIdentifier[t.identifier] = t;
        }

        // Build set of previously-active ticker identifiers
        NSMutableSet *previousIds = [NSMutableSet set];
        for (NSString *timerName in [data.tickerTimerNames copy]) {
            // Timer names are prefix-tickerId
            NSRange dashRange = [timerName rangeOfString:@"-"];
            if (dashRange.location != NSNotFound && NSMaxRange(dashRange) < timerName.length) {
                NSString *tickerId = [timerName substringFromIndex:NSMaxRange(dashRange)];
                [previousIds addObject:tickerId];
            }
        }

        // Disable removed/disabled tickers
        for (NSString *timerName in [data.tickerTimerNames copy]) {
            NSRange dashRange = [timerName rangeOfString:@"-"];
            if (dashRange.location == NSNotFound) continue;
            NSString *tickerId = [timerName substringFromIndex:NSMaxRange(dashRange)];

            MUDTickerBridge *ticker = tickersByIdentifier[tickerId];
            if (!ticker || !ticker.isEnabled) {
                [data.timerManager cancelRepeatingTimerWithName:timerName];
                [data.tickerTimerNames removeObject:timerName];
            } else {
                // Check interval change
                NSTimeInterval currentInterval = [data.timerManager intervalForTimerWithName:timerName];
                if ((int64_t)currentInterval != ticker.interval) {
                    [data.timerManager cancelRepeatingTimerWithName:timerName];
                    [data.tickerTimerNames removeObject:timerName];
                    [data enableTickerBridge:ticker];
                }
            }
        }

        // Enable new tickers
        for (MUDTickerBridge *ticker in currentTickers) {
            if (!ticker.isEnabled) continue;
            NSString *timerName = [data timerNameForTickerIdentifier:ticker.identifier];
            if (![data.tickerTimerNames containsObject:timerName]) {
                [data enableTickerBridge:ticker];
            }
        }
    }
}

@end

@implementation SPLWorldTickerData

- (NSString *)timerNameForTickerIdentifier:(NSString *)tickerIdentifier {
    return [NSString stringWithFormat:@"%@-%@", @(self.identifierPrefix), tickerIdentifier];
}

- (void)enableTickerBridge:(MUDTickerBridge *)ticker {
    NSString *tickerIdentifier = ticker.identifier;
    NSString *timerName = [self timerNameForTickerIdentifier:tickerIdentifier];
    NSString *worldId = [self.worldIdentifier copy];

    if (![self.tickerTimerNames containsObject:timerName]) {
        [self.tickerTimerNames addObject:timerName];
    }

    @weakify(self);
    SPLTimerManager *manager = self.timerManager;
    [manager scheduleRepeatingTimerWithName:timerName
                                   interval:(NSTimeInterval)ticker.interval
                                      block:^{
                                          @strongify(self);
                                          if (self.tickerBlock) {
                                              self.tickerBlock(tickerIdentifier, worldId);
                                          }
                                      }];
}

- (void)disableTickerBridge:(MUDTickerBridge *)ticker {
    NSString *timerName = [self timerNameForTickerIdentifier:ticker.identifier];

    SPLTimerManager *manager = self.timerManager;
    [manager cancelRepeatingTimerWithName:timerName];
    [self.tickerTimerNames removeObject:timerName];
}

@end
