#import "QuickDialogController+Helpers.h"
#import "QuickDialog.h"


NSString *QTranslate(NSString *value) {
    NSString * translated = NSLocalizedString(value, nil);
    //if ([translated isEqualToString:value])
    //    NSLog(@"\"%@\" = \"%@\";", value, value);
    return translated;
}


@implementation QuickDialogController (Helpers)
@end
