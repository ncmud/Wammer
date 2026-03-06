//
// Created by Eduardo Scoz on 1/11/14.
//

#import <UIKit/UIKit.h>
#import "QTableViewCell.h"

@class QDateTimeInlineElement;
@class QuickDialogTableView;

@interface QDateInlineTableViewCell : QTableViewCell

- (void)prepareForElement:(QDateTimeInlineElement *)element inTableView:(QuickDialogTableView *)tableView;

@end


