//
//  SPLCore.h
//  SPLCore
//
//  Created by Jonathan Hersh on 10/2/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#pragma once

@import Foundation;
@import UIKit;

// Pod dependencies
#import <EXTScope.h>

// Core
#import "SPLFloat.h"
#import "SPLDebug.h"

// View Additions
#import "NSString+SSAdditions.h"
#import "UIBarButtonItem+SSAdditions.h"
#import "UITableView+SSAdditions.h"
#import "UIView+SPLAdditions.h"
#import "UIColor+SSAdditions.h"

// Core Additions
#import "UIDevice+SSAdditions.h"
#import "UIApplication+SSAdditions.h"
#import "NSNumber+SSAdditions.h"
#import "UIColor+SSAdditions.h"
#if !TARGET_OS_VISION
#import "UIScreen+SSAdditions.h"
#endif
