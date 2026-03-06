#import <UIKit/UIKit.h>
#import "QuickDialogController.h"
#import "QRootElement.h"

@interface QuickDialogController(Navigation)

- (void)displayViewController:(UIViewController *)newController;

- (void)displayViewController:(UIViewController *)newController withPresentationMode:(QPresentationMode)mode;

- (void)displayViewControllerForRoot:(QRootElement *)element;

- (void)dismissModalViewController;

- (void)displayViewControllerInPopover:(UIViewController *)newController withNavigation:(BOOL)navigation fromRect:(CGRect)position;

- (void)displayViewControllerInPopover:(UIViewController *)newController withNavigation:(BOOL)navigation;

- (void)popToPreviousRootElement;


@end
