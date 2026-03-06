//
//  SSTGAEditor.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 1/5/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

@import UIKit;
#import "SSQuickDialogController.h"

// Editor for gags, triggers, aliases

@interface SSTGAEditor : SSQuickDialogController

+ (instancetype) editorForTrigger:(NSString *)triggerIdentifier
                  worldIdentifier:(NSString *)worldIdentifier;

+ (instancetype) editorForAlias:(NSString *)aliasIdentifier
                worldIdentifier:(NSString *)worldIdentifier;

+ (instancetype) editorForGag:(NSString *)gagIdentifier
              worldIdentifier:(NSString *)worldIdentifier;

- (void) deleteCurrentRecord;

- (void) showSoundPicker;

@end
