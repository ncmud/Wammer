//
//  SSWorldEditViewController.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;
#import "SSQuickDialogController.h"

typedef void (^SSWorldSaveCompletionBlock) (BOOL);

@interface SSWorldEditViewController : SSQuickDialogController

@property (nonatomic, copy) SSWorldSaveCompletionBlock saveCompletionBlock;

// Edit world
+ (instancetype) editorForWorldIdentifier:(NSString *)worldIdentifier;

// New actions
- (void) editTrigger:(NSString *)triggerIdentifier;
- (void) editAlias:(NSString *)aliasIdentifier;
- (void) editGag:(NSString *)gagIdentifier;
- (void) editTicker:(NSString *)tickerIdentifier;
- (void) newTrigger;
- (void) newAlias;
- (void) newGag;
- (void) newTicker;
- (void) deepClone;
- (void) chooseAmbientMusic;

@end
