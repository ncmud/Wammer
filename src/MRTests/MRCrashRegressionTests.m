//
//  MRCrashRegressionTests.m
//  MRTests
//
//  Regression tests for upstream crash reports.
//  Each test reproduces the conditions that caused the crash.
//

#import "MRTestHelpers.h"
#import "SSTextViewCell.h"
#import "SSGrowingTextView.h"

@interface MRCrashRegressionTests : XCTestCase
@end

@implementation MRCrashRegressionTests

#pragma mark - #68: characterAtIndex: out of bounds

- (void)testItemWithEmptyAttributedStringDoesNotCrash {
    NSAttributedString *empty = [NSAttributedString new];
    SSAttributedLineGroupItem *item = [SSAttributedLineGroupItem itemWithAttributedString:empty];

    XCTAssertNotNil(item);
    XCTAssertEqual(item.line.length, 0);
}

- (void)testItemWithNewlineOnlyStringDoesNotCrash {
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    SSAttributedLineGroupItem *item = [SSAttributedLineGroupItem itemWithAttributedString:newline];

    XCTAssertNotNil(item);
    XCTAssertTrue(item.endsInNewLine);
    XCTAssertEqual(item.line.length, 0);
}

- (void)testBlankLineItemDoesNotCrash {
    SSAttributedLineGroupItem *item = [SSAttributedLineGroupItem itemWithBlankLine];

    XCTAssertNotNil(item);
    XCTAssertTrue(item.endsInNewLine);
    XCTAssertEqual(item.line.length, 0);
}

#pragma mark - #69: TTTAttributedLabel nil string

- (void)testTTTAttributedLabelNilTextDoesNotCrash {
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
    label.enabledTextCheckingTypes = NSTextCheckingTypeLink;

    label.text = @"Hello world";
    label.text = nil;
    label.text = @"";

    // If we get here without crashing, the nil guard works
    XCTAssertTrue(YES);
}

#pragma mark - #72: SSGrowingTextView zero bounds

- (void)testGrowingTextViewZeroBoundsDoesNotCrash {
    SSGrowingTextView *textView = [[SSGrowingTextView alloc] initWithFrame:CGRectZero];
    textView.text = @"Hello world";

    CGSize size = [textView currentContentSize];

    XCTAssertEqual(size.width, 0);
    XCTAssertEqual(size.height, textView.minHeight);
}

- (void)testGrowingTextViewNormalBoundsReturnsValidSize {
    SSGrowingTextView *textView = [[SSGrowingTextView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    textView.text = @"Hello world";

    CGSize size = [textView currentContentSize];

    XCTAssertGreaterThanOrEqual(size.height, textView.minHeight);
    XCTAssertLessThanOrEqual(size.height, textView.maxHeight);
    XCTAssertEqual(size.width, 320);
}

@end
