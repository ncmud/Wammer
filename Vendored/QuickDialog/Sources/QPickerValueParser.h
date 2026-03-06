//
//  QPickerValueExtrator.h
//  QuickDialog
//
//  Created by HiveHicks on 05.04.12.
//

#import <UIKit/UIKit.h>

@protocol QPickerValueParser <NSObject>

@required
- (id)objectFromComponentsValues:(NSArray *)componentsValues;
- (NSArray *)componentsValuesFromObject:(id)object;

@optional
- (NSString *)presentationOfObject:(id)object;

@end
