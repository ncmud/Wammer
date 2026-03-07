//
//  SSGrowingTextView.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/2/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SSGrowingTextView.h"
#import "SSClientViewController+Interactions.h"

UIEdgeInsets const kContentInset = (UIEdgeInsets) { 0, 0, 0, 0 };
UIEdgeInsets const kTextContainerInset = (UIEdgeInsets) { 4, 4, 2, 4 };

@interface SSGrowingTextView ()

- (void) pressedArrowKey:(UIKeyCommand *)command;

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

        self.textColor = [UIColor darkGrayColor];
        self.font = [UIFont systemFontOfSize:14.0f];

        self.returnKeyType = UIReturnKeySend;
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;

        self.layer.borderWidth = 1.f;
        self.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.layer.cornerRadius = 5.f;
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

- (void)pressedArrowKey:(UIKeyCommand *)command {
    id del = self.textDelegate;

    if ([del respondsToSelector:@selector(growingTextViewPressedKeyCommand:)]) {
        [del growingTextViewPressedKeyCommand:command.input];
    }
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

- (NSArray *)keyCommands {
    static NSArray *keys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *cmds = [NSMutableArray array];

        // History navigation
        UIKeyCommand *histUp = [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow
                                                   modifierFlags:kNilOptions
                                                          action:@selector(pressedArrowKey:)];
        histUp.discoverabilityTitle = @"Previous Command";
        [cmds addObject:histUp];

        UIKeyCommand *histDown = [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow
                                                     modifierFlags:kNilOptions
                                                            action:@selector(pressedArrowKey:)];
        histDown.discoverabilityTitle = @"Next Command";
        [cmds addObject:histDown];

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

@end
