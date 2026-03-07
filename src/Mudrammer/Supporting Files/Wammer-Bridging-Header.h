//
//  Wammer-Bridging-Header.h
//  Mudrammer
//

@import UIKit;

#import "SSMRConstants.h"
#import "SPLNotificationManager.h"

// SSClientContainer.h can't be imported here (uses @import JASidePanels
// which isn't available in the bridging header module context).
@class SSClientContainer;
@interface SSClientContainer : UIViewController
- (instancetype)init;
@end

@class SSRadialControl;
@interface SSRadialControl : UIControl
+ (void)validateRadialPositions;
@end
