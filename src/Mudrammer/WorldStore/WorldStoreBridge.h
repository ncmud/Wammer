//
//  WorldStoreBridge.h
//  Wammer
//
//  Hand-written header matching the @objc classes in WorldStoreBridge.swift.
//  This avoids the Wammer-Swift.h header generation issue.
//

@import Foundation;
@import UIKit;

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

+ (void)setDefaultWorldWithIdentifier:(NSString *)identifier;
+ (nullable NSString *)defaultWorldIdentifier;
+ (nullable NSString *)worldDescriptionForIdentifier:(NSString *)identifier;

// Alias / Gag / Trigger matching
+ (nullable NSArray<NSString *> *)commandsIfMatchingAliasForIdentifier:(NSString *)identifier input:(NSString *)input;
+ (NSIndexSet *)filteredIndexesByMatchingGagsForIdentifier:(NSString *)identifier lines:(NSArray<NSString *> *)lines;
+ (nullable MUDTriggerResultBridge *)runTriggersForIdentifier:(NSString *)identifier lines:(NSArray<NSString *> *)lines;

@end

NS_ASSUME_NONNULL_END
