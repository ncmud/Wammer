//
//  UIScreen+SSAdditions.m
//  SPLCore
//
//  Created by Jonathan Hersh on 7/19/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#if !TARGET_OS_VISION
#import "UIScreen+SSAdditions.h"

@implementation UIScreen (SSAdditions)

- (BOOL)isRetina {
    return [self scale] > 1;
}

@end
#endif
