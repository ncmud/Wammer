//
//  QFloatTableViewCell.h
//  QuickDialog
//
//  Created by Bart Vandendriessche on 29/04/13.
//
//

#import <UIKit/UIKit.h>
#import "QTableViewCell.h"

@interface QFloatTableViewCell : QTableViewCell

@property (nonatomic, strong, readonly) UISlider *slider;

@end
