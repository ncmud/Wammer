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
#if TARGET_OS_VISION
    return YES;
#else
    return [self userInterfaceIdiom] == UIUserInterfaceIdiomPad;
#endif
}

+ (BOOL)isLandscape {
    UIWindowScene *scene = (UIWindowScene *)[[[[UIApplication sharedApplication] connectedScenes] allObjects] firstObject];
    if (scene && [scene isKindOfClass:[UIWindowScene class]]) {
        return UIInterfaceOrientationIsLandscape(scene.effectiveGeometry.interfaceOrientation);
    }
    return NO;
}

+ (CGFloat)preferredPopoverWidth {
#if TARGET_OS_MACCATALYST
    return 420.0f;
#else
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow && w.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)
                    return 420.0f;
            }
        }
    }
    return 320.0f;
#endif
}

+ (void)vibrateWithBeepFallback:(BOOL)beep {
#if !TARGET_OS_VISION
    if( beep )
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    else
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
#endif
}

@end
