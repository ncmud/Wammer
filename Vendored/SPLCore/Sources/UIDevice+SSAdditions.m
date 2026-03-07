//
//  UIDevice+SSAdditions.m
//  SPLCore
//
//  Created by Jonathan Hersh on 10/22/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "UIDevice+SSAdditions.h"
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@implementation UIDevice (SSAdditions)

- (BOOL) isIPad {
    return [self userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

+ (BOOL)isLandscape {
    UIWindowScene *scene = (UIWindowScene *)[[[[UIApplication sharedApplication] connectedScenes] allObjects] firstObject];
    if (scene && [scene isKindOfClass:[UIWindowScene class]]) {
        return UIInterfaceOrientationIsLandscape(scene.effectiveGeometry.interfaceOrientation);
    }
    return NO;
}

+ (void)vibrateWithBeepFallback:(BOOL)beep {
    if( beep )
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    else
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

@end
