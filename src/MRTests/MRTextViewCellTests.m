//
//  MRTextViewCellTests.m
//  MRTests
//
//  Reproducing test for P0 zombie crash:
//  _textStorageDidProcessEditing: sent to deallocated delegate
//
//  Root cause: SSTextViewCell has no prepareForReuse, so when cells
//  are recycled the old TTTAttributedLabel delegate pointer is stale.
//

#import "MRTestHelpers.h"
#import "SSTextViewCell.h"

@interface MRTextViewCellTests : XCTestCase
@end

@interface MRFakeTextViewDelegate : NSObject <TTTAttributedLabelDelegate>
@end

@implementation MRFakeTextViewDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {}

@end

@implementation MRTextViewCellTests

- (SSTextViewCell *)makeCell {
    SSTextViewCell *cell = [[SSTextViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                reuseIdentifier:@"test"];
    [cell configureCell];
    return cell;
}

- (void)testDelegateIsClearedOnPrepareForReuse {
    SSTextViewCell *cell = [self makeCell];

    MRFakeTextViewDelegate *delegate = [MRFakeTextViewDelegate new];
    cell.textView.delegate = delegate;

    XCTAssertNotNil(cell.textView.delegate, @"Delegate should be set before reuse");

    [cell prepareForReuse];

    XCTAssertNil(cell.textView.delegate,
                 @"Delegate must be nil after prepareForReuse to prevent zombie crashes");
}

- (void)testTextIsClearedOnPrepareForReuse {
    SSTextViewCell *cell = [self makeCell];

    cell.textView.text = @"Hello world";

    XCTAssertNotNil(cell.textView.text, @"Text should be set before reuse");

    [cell prepareForReuse];

    XCTAssertNil(cell.textView.text,
                 @"Text must be nil after prepareForReuse to clear stale NSTextStorage references");
}

@end
