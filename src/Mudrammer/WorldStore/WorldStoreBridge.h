//
//  WorldStoreBridge.h
//  Wammer
//
//  ObjC-visible interface for WorldStore Swift types.
//  Hand-written header matching the @objc classes in WorldStoreBridge.swift.
//  This avoids the Wammer-Swift.h header generation issue.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - MUDWorldBridge

/// Opaque reference to a MUDWorld instance, bridged from Swift.
@interface MUDWorldBridge : NSObject

@property (nonatomic, readonly, copy) NSString *identifier;
@property (nonatomic, readonly, copy) NSString *hostname;
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly) int16_t port;
@property (nonatomic, readonly) BOOL isDefault;
@property (nonatomic, readonly) BOOL isSecure;
@property (nonatomic, readonly, copy, nullable) NSString *connectCommand;

@end

#pragma mark - WorldStoreBridge

@interface WorldStoreBridge : NSObject

@property (class, nonatomic, readonly) NSNotificationName didChangeNotification;

+ (NSArray<MUDWorldBridge *> *)allWorlds;
+ (nullable MUDWorldBridge *)worldForIdentifier:(NSString *)identifier;
+ (void)addWorldWithHostname:(NSString *)hostname name:(NSString *)name port:(int16_t)port;
+ (NSString *)addEmptyWorld;
+ (void)removeWorldWithIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
