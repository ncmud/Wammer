//
//  MRThemeTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/14/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

#import "MRTestHelpers.h"
#import "SPLTerminalDataSource.h"
#import "SSGrowingTextView.h"
#import "SSThemes.h"
#import "SSMRConstants.h"

@interface MRThemeTests : XCTestCase

@end

@implementation MRThemeTests
{
    SPLTerminalDataSource *dataSource;
    NSDictionary *originalTheme;
}

- (void)setUp {
    [super setUp];

    dataSource = [[SPLTerminalDataSource alloc] initWithItems:nil];
    originalTheme = [[[SSThemes sharedThemer] currentTheme] copy];
}

- (void)tearDown {
    if (originalTheme) {
        [[SSThemes sharedThemer] applyTheme:originalTheme];
    }

    [super tearDown];
}

- (void)testThemeChangeChangesTextColors {
    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithAttributedString:SPLTestStringWithStringAndColor(@"Hello World", kDefaultColor)]];

    EXP_expect(dataSource.numberOfItems).will.equal(1);
    EXP_expect(dataSource.allItems[0]).will.equal(SPLItemWithString(SPLTestStringWithStringAndColor(@"Hello World", kDefaultColor)));

    [[SSThemes sharedThemer] applyTheme:@{ kThemeFontColor : [UIColor redColor] }];

    EXP_expect(dataSource.numberOfItems).will.equal(1);
    EXP_expect(dataSource.allItems[0]).will.equal(SPLItemWithString(SPLTestStringWithStringAndColor(@"Hello World", [UIColor redColor])));
}

- (void)testThemeChangeChangesFont {
    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithAttributedString:SPLTestStringWithStringAndColorAndFont(@"Hello World", kDefaultColor, kDefaultFont)]];

    EXP_expect(dataSource.numberOfItems).will.equal(1);
    EXP_expect(dataSource.allItems[0]).will.equal(SPLItemWithString(SPLTestStringWithStringAndColorAndFont(@"Hello World", kDefaultColor, kDefaultFont)));

    [[SSThemes sharedThemer] applyTheme:@{ kThemeFontName : @"Courier", kThemeFontSize : @12 }];

    EXP_expect(dataSource.numberOfItems).will.equal(1);
    EXP_expect(dataSource.allItems[0]).will.equal(SPLItemWithString(SPLTestStringWithStringAndColorAndFont(@"Hello World", kDefaultColor, [UIFont fontWithName:@"Courier" size:12])));
}

- (void)testGrowingTextViewUsesCurrentThemeFontColor {
    [[SSThemes sharedThemer] applyTheme:@{ kThemeFontColor : [UIColor redColor] }];

    SSGrowingTextView *textView = [[SSGrowingTextView alloc] initWithFrame:CGRectZero textContainer:nil];

    XCTAssertEqualObjects(textView.textColor, [UIColor redColor]);
}

- (void)testGrowingTextViewUpdatesWhenThemeFontColorChanges {
    SSGrowingTextView *textView = [[SSGrowingTextView alloc] initWithFrame:CGRectZero textContainer:nil];

    [[SSThemes sharedThemer] applyTheme:@{ kThemeFontColor : [UIColor blueColor] }];

    XCTAssertEqualObjects(textView.textColor, [UIColor blueColor]);
}

@end
