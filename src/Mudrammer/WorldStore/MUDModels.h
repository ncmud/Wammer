//
//  MUDModels.h
//  Wammer
//
//  Hand-written ObjC interface declarations matching the @objc Swift classes
//  in Models.swift. These let ObjC code use the Swift model types directly
//  (working around the Wammer-Swift.h header generation issue).
//

@import Foundation;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Enums

typedef NS_ENUM(NSInteger, MUDTriggerType) {
    MUDTriggerTypeStartOfLine = 0,
    MUDTriggerTypeLineContains = 1,
};

typedef NS_ENUM(NSInteger, MUDGagType) {
    MUDGagTypeStartOfLine = 0,
    MUDGagTypeLineContains = 1,
    MUDGagTypeLineEquals = 2,
};

#pragma mark - MUDAlias

@interface MUDAlias : NSObject

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic) BOOL isEnabled;
@property (nonatomic) BOOL isHidden;
@property (nonatomic, strong) NSDate *lastModified;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *commands;
@property (nonatomic, readonly) BOOL canSave;

@end

#pragma mark - MUDTrigger

@interface MUDTrigger : NSObject

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic) BOOL isEnabled;
@property (nonatomic) BOOL isHidden;
@property (nonatomic, strong) NSDate *lastModified;
@property (nonatomic, copy) NSString *trigger;
@property (nonatomic, copy) NSString *commands;
@property (nonatomic, copy, nullable) NSString *soundFileName;
@property (nonatomic) MUDTriggerType triggerType;
@property (nonatomic, strong, nullable) UIColor *highlightColor;
@property (nonatomic) BOOL vibrate;
@property (nonatomic, readonly) BOOL canSave;
+ (NSArray<NSString *> *)triggerTypeLabelArray;

@end

#pragma mark - MUDGag

@interface MUDGag : NSObject

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic) BOOL isEnabled;
@property (nonatomic) BOOL isHidden;
@property (nonatomic, strong) NSDate *lastModified;
@property (nonatomic) MUDGagType gagType;
@property (nonatomic, copy) NSString *gag;
@property (nonatomic, readonly) BOOL canSave;
+ (NSArray<NSString *> *)gagTypeLabelArray;

@end

#pragma mark - MUDTicker

@interface MUDTicker : NSObject

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic) BOOL isEnabled;
@property (nonatomic) BOOL isHidden;
@property (nonatomic, strong) NSDate *lastModified;
@property (nonatomic) int64_t interval;
@property (nonatomic, copy) NSString *commands;
@property (nonatomic, copy, nullable) NSString *soundFileName;
@property (nonatomic, readonly) BOOL canSave;

@end

#pragma mark - MUDWorld

@interface MUDWorld : NSObject

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic) BOOL isHidden;
@property (nonatomic, strong) NSDate *lastModified;
@property (nonatomic, copy) NSString *hostname;
@property (nonatomic, copy) NSString *name;
@property (nonatomic) int16_t port;
@property (nonatomic) BOOL isDefault;
@property (nonatomic) BOOL isSecure;
@property (nonatomic, copy, nullable) NSString *connectCommand;
@property (nonatomic, strong) NSArray<MUDAlias *> *aliases;
@property (nonatomic, strong) NSArray<MUDTrigger *> *triggers;
@property (nonatomic, strong) NSArray<MUDGag *> *gags;
@property (nonatomic, strong) NSArray<MUDTicker *> *tickers;

// Validation
@property (nonatomic, readonly) BOOL canSave;

// Computed properties from Models+Logic.swift
@property (nonatomic, readonly, copy) NSString *worldDescription;
@property (nonatomic, readonly) NSArray<MUDAlias *> *orderedAliases;
@property (nonatomic, readonly) NSArray<MUDGag *> *orderedGags;
@property (nonatomic, readonly) NSArray<MUDTicker *> *orderedTickers;
- (NSArray<MUDTrigger *> *)orderedTriggersWithActive:(BOOL)active;
- (MUDWorld *)deepClone;
+ (NSString *)cleanedHostNameFor:(NSString *)host;

@end

NS_ASSUME_NONNULL_END
