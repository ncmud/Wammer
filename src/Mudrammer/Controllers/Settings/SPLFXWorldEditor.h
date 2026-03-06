//
//  SPLFXWorldEditor.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 7/20/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SPLFXFormViewController.h"

@interface SPLFXWorldEditor : SPLFXFormViewController

+ (instancetype) editorForTicker:(NSString *)tickerIdentifier
                 worldIdentifier:(NSString *)worldIdentifier;

- (void) deleteCurrentRecord;

- (void) showSoundPicker;

@end
