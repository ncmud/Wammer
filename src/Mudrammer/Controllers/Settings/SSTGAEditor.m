//
//  SSTGAEditor.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 1/5/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSTGAEditor.h"
#import "Wammer-Swift.h"

#import "SSSoundPickerViewController.h"
#import "JSQSystemSoundPlayer+SSAdditions.h"

#import "SSTriggerForm.h"
#import "SSAliasForm.h"
#import "SSGagForm.h"

#import "SPLAlerts.h"

typedef NS_ENUM(NSUInteger, SSTGARecordType) {
    SSTGARecordTypeTrigger,
    SSTGARecordTypeAlias,
    SSTGARecordTypeGag,
};

@interface SSTGAEditor ()

- (void) cancelEditing:(id)sender;
- (void) saveEditing:(id)sender;

@property (nonatomic, strong) NSObject *record;
@property (nonatomic, copy) NSString *worldIdentifier;
@property (nonatomic, assign) SSTGARecordType recordType;

@end

@implementation SSTGAEditor
{
    UIBarButtonItem *saveButton;
}

+ (instancetype)editorForTrigger:(NSString *)triggerIdentifier worldIdentifier:(NSString *)worldIdentifier {
    MUDWorld *world = [WorldStoreBridge mudWorldForIdentifier:worldIdentifier];
    if (!world) return nil;

    MUDTrigger *trigger = nil;
    for (MUDTrigger *t in world.triggers) {
        if ([t.identifier isEqualToString:triggerIdentifier]) {
            trigger = t;
            break;
        }
    }
    if (!trigger) return nil;

    SSBaseForm *form = [SSTriggerForm formForTrigger:trigger];
    SSTGAEditor *editor = [[SSTGAEditor alloc] initWithRoot:form];
    editor.record = trigger;
    editor.worldIdentifier = worldIdentifier;
    editor.recordType = SSTGARecordTypeTrigger;
    [editor commonSetup];
    return editor;
}

+ (instancetype)editorForAlias:(NSString *)aliasIdentifier worldIdentifier:(NSString *)worldIdentifier {
    MUDWorld *world = [WorldStoreBridge mudWorldForIdentifier:worldIdentifier];
    if (!world) return nil;

    MUDAlias *alias = nil;
    for (MUDAlias *a in world.aliases) {
        if ([a.identifier isEqualToString:aliasIdentifier]) {
            alias = a;
            break;
        }
    }
    if (!alias) return nil;

    SSBaseForm *form = [SSAliasForm formForAlias:alias];
    SSTGAEditor *editor = [[SSTGAEditor alloc] initWithRoot:form];
    editor.record = alias;
    editor.worldIdentifier = worldIdentifier;
    editor.recordType = SSTGARecordTypeAlias;
    [editor commonSetup];
    return editor;
}

+ (instancetype)editorForGag:(NSString *)gagIdentifier worldIdentifier:(NSString *)worldIdentifier {
    MUDWorld *world = [WorldStoreBridge mudWorldForIdentifier:worldIdentifier];
    if (!world) return nil;

    MUDGag *gag = nil;
    for (MUDGag *g in world.gags) {
        if ([g.identifier isEqualToString:gagIdentifier]) {
            gag = g;
            break;
        }
    }
    if (!gag) return nil;

    SSBaseForm *form = [SSGagForm formForGag:gag];
    SSTGAEditor *editor = [[SSTGAEditor alloc] initWithRoot:form];
    editor.record = gag;
    editor.worldIdentifier = worldIdentifier;
    editor.recordType = SSTGARecordTypeGag;
    [editor commonSetup];
    return editor;
}

- (void)commonSetup {
    [SSThemes configureTable:self.quickDialogTableView];

    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                               target:self
                                                               action:@selector(saveEditing:)];

    self.navigationItem.rightBarButtonItem = saveButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if(![[UIDevice currentDevice] isIPad] || self.navigationController.SPLNavigationIsAtRoot) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(cancelEditing:)];
    }
}

#pragma mark - actions

- (void)showSoundPicker {
    SSSoundPickerViewController *picker = [SSSoundPickerViewController new];
    picker.selectedFileName = [_record valueForKey:@"soundFileName"];

    @weakify(self);
    picker.selectedBlock = ^(NSString *str) {
        @strongify(self);

        // Manual bind because it's not an entry element?
        [self.record setValue:str forKey:@"soundFileName"];

        QLabelElement *element = (QLabelElement *)[self.root elementWithKey:kSoundElement];

        SSSound *newSound = [JSQSystemSoundPlayer soundForFileName:str];

        element.value = (newSound
                         ? newSound.soundName
                         : @"None");

        [self.quickDialogTableView reloadCellForElements:element, nil];
    };

    [self.navigationController pushViewController:picker
                                         animated:YES];
}

- (void)deleteCurrentRecord {
    [self.quickDialogTableView endEditing:YES];

    @weakify(self);
    NSString *title;

    switch (_recordType) {
        case SSTGARecordTypeTrigger:
            title = NSLocalizedString(@"DELETE_TRIGGER", nil);
            break;
        case SSTGARecordTypeAlias:
            title = NSLocalizedString(@"DELETE_ALIAS", nil);
            break;
        case SSTGARecordTypeGag:
            title = NSLocalizedString(@"DELETE_GAG", nil);
            break;
    }

    [SPLAlerts SPLShowActionViewWithTitle:nil
                              cancelTitle:NSLocalizedString(@"CANCEL", @"Cancel")
                              cancelBlock:nil
                         destructiveTitle:title
                         destructiveBlock:^{
                             @strongify(self);
                             NSString *recordId = [self.record valueForKey:@"identifier"];


                             switch (self.recordType) {
                                 case SSTGARecordTypeTrigger:
                                     [WorldStoreBridge removeTriggerWithIdentifier:recordId
                                                              fromWorldIdentifier:self.worldIdentifier];
                                     break;
                                 case SSTGARecordTypeAlias:
                                     [WorldStoreBridge removeAliasWithIdentifier:recordId
                                                            fromWorldIdentifier:self.worldIdentifier];
                                     break;
                                 case SSTGARecordTypeGag:
                                     [WorldStoreBridge removeGagWithIdentifier:recordId
                                                           fromWorldIdentifier:self.worldIdentifier];
                                     break;
                             }

                             [self SPLDismiss];
                         }
                            barButtonItem:nil
                               sourceView:self.quickDialogTableView
                               sourceRect:self.quickDialogTableView.frame
                      presentingController:self];
}

- (void)SPLDismiss {
    [self.quickDialogTableView endEditing:YES];

    if (self.navigationController.SPLNavigationIsAtRoot) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)cancelEditing:(id)sender {
    // If record is new (hidden), remove it since user cancelled
    BOOL isHidden = [[_record valueForKey:@"isHidden"] boolValue];
    if (isHidden) {
        NSString *recordId = [_record valueForKey:@"identifier"];

        switch (_recordType) {
            case SSTGARecordTypeTrigger:
                [WorldStoreBridge removeTriggerWithIdentifier:recordId
                                         fromWorldIdentifier:_worldIdentifier];
                break;
            case SSTGARecordTypeAlias:
                [WorldStoreBridge removeAliasWithIdentifier:recordId
                                       fromWorldIdentifier:_worldIdentifier];
                break;
            case SSTGARecordTypeGag:
                [WorldStoreBridge removeGagWithIdentifier:recordId
                                     fromWorldIdentifier:_worldIdentifier];
                break;
        }
    }

    [self SPLDismiss];
}

- (void)saveEditing:(id)sender {
    [self.quickDialogTableView endEditing:YES];

    [self.root fetchValueIntoObject:_record];

    if( ![(id)_record canSave] )
        return;

    [_record setValue:@(NO) forKey:@"isHidden"];

    [WorldStoreBridge updateMUDWorld:[WorldStoreBridge mudWorldForIdentifier:_worldIdentifier]];

    [self SPLDismiss];
}

#pragma mark - lifecycle

- (CGSize)preferredContentSize {
    return [self.quickDialogTableView sizeThatFits:CGSizeMake(320.f, CGFLOAT_MAX)];
}

@end
