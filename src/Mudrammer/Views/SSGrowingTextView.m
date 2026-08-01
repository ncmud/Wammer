//
//  SSGrowingTextView.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/2/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SSGrowingTextView.h"
#import "SSClientViewController+Interactions.h"
#import "SSThemes.h"
#import <FBKVOController.h>

UIEdgeInsets const kContentInset = (UIEdgeInsets) { 0, 0, 0, 0 };
UIEdgeInsets const kTextContainerInset = (UIEdgeInsets) { 4, 4, 2, 4 };

@interface SSGrowingTextView ()

- (void) notifyDelegateArrowKey:(NSString *)input;
- (BOOL) cursorIsOnFirstLine;
- (BOOL) cursorIsOnLastLine;

@property (nonatomic, strong) FBKVOController *kvoController;

@end

@implementation SSGrowingTextView

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer {
    if ((self = [super initWithFrame:frame textContainer:textContainer])) {

        _minHeight = 26.0f;
        _maxHeight = 72.0f;

        self.contentMode = UIViewContentModeCenter;
        self.contentInset = kContentInset;
        self.textContainerInset = kTextContainerInset;

        self.textContainer.lineFragmentPadding = 0;

        // The text and background colors must come from the same theme pair, or
        // typed text can vanish (a white theme font on the default white field).
        // Pin the trait too: on iOS 26 a dark keyboardAppearance can leak a dark
        // trait into the text view's color resolution.
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;

        SSThemes *themer = [SSThemes sharedThemer];
        UIColor *fontColor = [themer valueForThemeKey:kThemeFontColor];
        UIColor *themeBackgroundColor = [themer valueForThemeKey:kThemeBackgroundColor];
        self.textColor = fontColor ?: [UIColor darkGrayColor];
        self.backgroundColor = themeBackgroundColor ?: [UIColor whiteColor];
        self.tintColor = self.textColor;
        self.font = [UIFont systemFontOfSize:14.0f];

        self.returnKeyType = UIReturnKeySend;
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;

        self.layer.borderWidth = 1.f;
        self.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.layer.cornerRadius = 5.f;

        _kvoController = [FBKVOController controllerWithObserver:self];
        [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                            keyPath:kThemeFontColor
                            options:NSKeyValueObservingOptionNew
                              block:^(SSGrowingTextView *textView, id object, NSDictionary *change) {
                                  UIColor *newColor = change[NSKeyValueChangeNewKey];
                                  textView.textColor = newColor ?: [UIColor darkGrayColor];
                                  textView.tintColor = textView.textColor;
                              }];
        [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                            keyPath:kThemeBackgroundColor
                            options:NSKeyValueObservingOptionNew
                              block:^(SSGrowingTextView *textView, id object, NSDictionary *change) {
                                  UIColor *newColor = change[NSKeyValueChangeNewKey];
                                  textView.backgroundColor = newColor ?: [UIColor whiteColor];
                              }];
    }

    return self;
}

- (void)dealloc {
    _textDelegate = nil;
    self.delegate = nil;
}

- (void)setText:(NSString *)text {
    [super setText:text];

    id del = self.delegate;

    if ([del respondsToSelector:@selector(textViewDidChange:)]) {
        [del textViewDidChange:self];
    }
}

- (void)setTextDelegate:(id<UITextViewDelegate,SSGrowingTextViewDelegate>)textDelegate {
    _textDelegate = textDelegate;
    self.delegate = textDelegate;
}

#pragma mark - Auto Layout

- (CGSize)currentContentSize {
    CGFloat boundsWidth = CGRectGetWidth(self.bounds);

    if ([self.text length] == 0 || boundsWidth <= 0) {
        return CGSizeMake(boundsWidth, self.minHeight);
    }

    NSString *str = [self.text copy];

    CGRect rect = [str boundingRectWithSize:CGSizeMake(boundsWidth - self.textContainerInset.left - self.textContainerInset.right,
                                                       CGFLOAT_MAX)
                                    options:NSStringDrawingUsesLineFragmentOrigin
                                 attributes:@{ NSFontAttributeName : self.font,
                                               NSKernAttributeName : [NSNull null] }
                                    context:nil];

    CGFloat height = SPLFloat_ceil(CGRectGetHeight(rect));

    height += self.textContainerInset.top + self.textContainerInset.bottom + self.contentInset.top + self.contentInset.bottom;

    if (height > self.maxHeight) {
        height = self.maxHeight;
    }

    if (height < self.minHeight) {
        height = self.minHeight;
    }

    return CGSizeMake(CGRectGetWidth(self.bounds),
                      height);
}

#pragma mark - Key commands

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    for (UIPress *press in presses) {
        UIKey *key = press.key;
        if (!key) continue;

        // Mask out UIKeyModifierNumericPad — arrow keys always have it set on Catalyst
        UIKeyModifierFlags mods = key.modifierFlags & ~UIKeyModifierNumericPad;

        // Up/down with no modifiers → history if on first/last line, else normal cursor movement
        if (mods == 0) {
            if (key.keyCode == UIKeyboardHIDUsageKeyboardUpArrow && [self cursorIsOnFirstLine]) {
                [self notifyDelegateArrowKey:UIKeyInputUpArrow];
                return;
            } else if (key.keyCode == UIKeyboardHIDUsageKeyboardDownArrow && [self cursorIsOnLastLine]) {
                [self notifyDelegateArrowKey:UIKeyInputDownArrow];
                return;
            }
        }

        // Cmd+arrow → cardinal direction, Cmd+Ctrl+arrow → diagonal
        BOOL hasCmd = (mods & UIKeyModifierCommand) != 0;
        if (hasCmd) {
            NSString *direction = nil;
            BOOL hasCmdCtrl = hasCmd && (mods & UIKeyModifierControl) != 0;

            switch (key.keyCode) {
                case UIKeyboardHIDUsageKeyboardLeftArrow:
                    direction = hasCmdCtrl ? @"sw" : @"w";
                    break;
                case UIKeyboardHIDUsageKeyboardRightArrow:
                    direction = hasCmdCtrl ? @"ne" : @"e";
                    break;
                case UIKeyboardHIDUsageKeyboardUpArrow:
                    direction = hasCmdCtrl ? @"nw" : @"n";
                    break;
                case UIKeyboardHIDUsageKeyboardDownArrow:
                    direction = hasCmdCtrl ? @"se" : @"s";
                    break;
                default:
                    break;
            }

            if (direction) {
                id del = self.textDelegate;
                if ([del respondsToSelector:@selector(growingTextViewSentDirectionalCommand:)]) {
                    [del growingTextViewSentDirectionalCommand:direction];
                }
                return;
            }
        }
    }

    [super pressesBegan:presses withEvent:event];
}

- (void)notifyDelegateArrowKey:(NSString *)input {
    id del = self.textDelegate;
    if ([del respondsToSelector:@selector(growingTextViewPressedKeyCommand:)]) {
        [del growingTextViewPressedKeyCommand:input];
    }
}

- (BOOL)cursorIsOnFirstLine {
    UITextRange *selection = self.selectedTextRange;
    if (!selection) return YES;

    CGRect cursorRect = [self caretRectForPosition:selection.start];
    CGRect firstRect = [self caretRectForPosition:self.beginningOfDocument];

    return CGRectGetMidY(cursorRect) <= CGRectGetMaxY(firstRect);
}

- (BOOL)cursorIsOnLastLine {
    UITextRange *selection = self.selectedTextRange;
    if (!selection) return YES;

    CGRect cursorRect = [self caretRectForPosition:selection.start];
    CGRect lastRect = [self caretRectForPosition:self.endOfDocument];

    return CGRectGetMidY(cursorRect) >= CGRectGetMinY(lastRect);
}

- (NSArray *)keyCommands {
    static NSArray *keys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *cmds = [NSMutableArray array];

        // Unmodified up/down arrows are handled in pressesBegan:withEvent: instead of
        // keyCommands, because UITextView's text system intercepts unmodified arrow
        // keyCommands on Catalyst before the action fires.

        // Directional movement (Cmd+arrow = cardinal, Cmd+Ctrl+arrow = diagonal)
        NSArray *arrowInputs = @[UIKeyInputLeftArrow, UIKeyInputRightArrow, UIKeyInputUpArrow, UIKeyInputDownArrow];
        for (NSString *arrow in arrowInputs) {
            [cmds addObject:[UIKeyCommand keyCommandWithInput:arrow
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(pressedDirectionalCommand:)]];
            [cmds addObject:[UIKeyCommand keyCommandWithInput:arrow
                                                modifierFlags:UIKeyModifierControl | UIKeyModifierCommand
                                                       action:@selector(pressedDirectionalCommand:)]];
        }

        // Session navigation
        UIKeyCommand *cycle = [UIKeyCommand keyCommandWithInput:@"`"
                                                  modifierFlags:UIKeyModifierControl
                                                         action:@selector(keyCommandCycleActiveConnections:)];
        cycle.discoverabilityTitle = @"Cycle Connections";
        [cmds addObject:cycle];

        for (int i = 1; i <= 9; i++) {
            UIKeyCommand *cmd = [UIKeyCommand keyCommandWithInput:[NSString stringWithFormat:@"%d", i]
                                                    modifierFlags:UIKeyModifierControl
                                                           action:@selector(keyCommandSwitchToActiveConnection:)];
            cmd.discoverabilityTitle = [NSString stringWithFormat:@"Connection %d", i];
            [cmds addObject:cmd];
        }

        keys = [cmds copy];
    });

    return keys;
}

- (void)pressedDirectionalCommand:(UIKeyCommand *)command {
    NSString *direction;
    BOOL isAltDirection = (command.modifierFlags & UIKeyModifierControl) && (command.modifierFlags & UIKeyModifierCommand);

    if ([command.input isEqualToString:UIKeyInputLeftArrow]) {
        direction = (isAltDirection ? @"sw" : @"w");
    } else if ([command.input isEqualToString:UIKeyInputRightArrow]) {
        direction = (isAltDirection ? @"ne" : @"e");
    } else if ([command.input isEqualToString:UIKeyInputUpArrow]) {
        direction = (isAltDirection ? @"nw" : @"n");
    } else if ([command.input isEqualToString:UIKeyInputDownArrow]) {
        direction = (isAltDirection ? @"se" : @"s");
    }

    if ([direction length] == 0) {
        return;
    }

    id del = self.textDelegate;

    if ([del respondsToSelector:@selector(growingTextViewSentDirectionalCommand:)]) {
        [del growingTextViewSentDirectionalCommand:direction];
    }
}

@end
