//
//  WorldStoreBridge.h
//  Wammer
//
//  Hand-written header matching the @objc classes in WorldStoreBridge.swift.
//  This avoids the Wammer-Swift.h header generation issue.
//

@import Foundation;
@import UIKit;

#import "MUDModels.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - MUDWorldBridge

@interface MUDWorldBridge : NSObject

@property (nonatomic, readonly, copy) NSString *identifier;
@property (nonatomic, readonly, copy) NSString *hostname;
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly) int16_t port;
@property (nonatomic, readonly) BOOL isDefault;
@property (nonatomic, readonly) BOOL isSecure;
@property (nonatomic, readonly, copy, nullable) NSString *connectCommand;

@end

#pragma mark - MUDTickerBridge

@interface MUDTickerBridge : NSObject

@property (nonatomic, readonly, copy) NSString *identifier;
@property (nonatomic, readonly) BOOL isEnabled;
@property (nonatomic, readonly) int64_t interval;
@property (nonatomic, readonly, copy) NSString *commands;
@property (nonatomic, readonly, copy, nullable) NSString *soundFileName;

@end

#pragma mark - MUDTriggerResultBridge

@interface MUDTriggerResultBridge : NSObject

@property (nonatomic, readonly, nullable) NSArray<NSString *> *commands;
@property (nonatomic, readonly, nullable) NSDictionary<NSNumber *, UIColor *> *lineColors;
@property (nonatomic, readonly, copy, nullable) NSString *soundName;

@end

#pragma mark - WorldStoreBridge

@interface WorldStoreBridge : NSObject

@property (class, nonatomic, readonly) NSNotificationName didChangeNotification;

+ (NSArray<MUDWorldBridge *> *)allWorlds;
+ (nullable MUDWorldBridge *)worldForIdentifier:(NSString *)identifier;
+ (void)addWorldWithHostname:(NSString *)hostname name:(NSString *)name port:(int16_t)port;
+ (NSString *)addEmptyWorld;
+ (void)removeWorldWithIdentifier:(NSString *)identifier;

+ (nullable MUDWorld *)mudWorldForIdentifier:(NSString *)identifier;
+ (void)updateMUDWorld:(MUDWorld *)world;
+ (void)addMUDWorld:(MUDWorld *)world;

+ (void)setDefaultWorldWithIdentifier:(NSString *)identifier;
+ (nullable NSString *)defaultWorldIdentifier;
+ (nullable NSString *)worldDescriptionForIdentifier:(NSString *)identifier;

+ (void)addTickerToWorldIdentifier:(NSString *)identifier commands:(NSString *)commands interval:(int64_t)interval isEnabled:(BOOL)isEnabled;

// Ticker access
+ (NSArray<MUDTickerBridge *> *)tickersForWorldIdentifier:(NSString *)identifier;
+ (nullable MUDTickerBridge *)tickerForIdentifier:(NSString *)tickerIdentifier worldIdentifier:(NSString *)worldIdentifier;

// Record editing
+ (void)addTrigger:(MUDTrigger *)trigger toWorldIdentifier:(NSString *)identifier;
+ (void)addAlias:(MUDAlias *)alias toWorldIdentifier:(NSString *)identifier;
+ (void)addGag:(MUDGag *)gag toWorldIdentifier:(NSString *)identifier;
+ (void)removeTriggerWithIdentifier:(NSString *)triggerIdentifier fromWorldIdentifier:(NSString *)worldIdentifier;
+ (void)removeAliasWithIdentifier:(NSString *)aliasIdentifier fromWorldIdentifier:(NSString *)worldIdentifier;
+ (void)removeGagWithIdentifier:(NSString *)gagIdentifier fromWorldIdentifier:(NSString *)worldIdentifier;
+ (void)removeTickerWithIdentifier:(NSString *)tickerIdentifier fromWorldIdentifier:(NSString *)worldIdentifier;

// Alias / Gag / Trigger matching
+ (nullable NSArray<NSString *> *)commandsIfMatchingAliasForIdentifier:(NSString *)identifier input:(NSString *)input;
+ (NSIndexSet *)filteredIndexesByMatchingGagsForIdentifier:(NSString *)identifier lines:(NSArray<NSString *> *)lines;
+ (nullable MUDTriggerResultBridge *)runTriggersForIdentifier:(NSString *)identifier lines:(NSArray<NSString *> *)lines;

@end

NS_ASSUME_NONNULL_END
