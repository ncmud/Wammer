//
//  SSWorldListViewController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "SSWorldListViewController.h"
#import "SSWorldEditViewController.h"
#import "SSWorldCell.h"
#import "Wammer-Swift.h"

@interface SSWorldListViewController ()

@property (nonatomic, copy) WorldPickerSelectionBlock completeBlock;
@property (nonatomic, strong) NSArray<MUDWorldBridge *> *worlds;

- (SSWorldListViewController *) init;
- (void) addWorld:(id)sender;
- (void) reloadWorlds;

@end

@implementation SSWorldListViewController

- (instancetype)init {
    if ((self = [self initWithStyle:UITableViewStylePlain])) {
        [SSThemes configureTable:self.tableView];

        self.title = NSLocalizedString(@"WORLDS", @"Worlds");

        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(addWorld:)];

        addButton.accessibilityLabel = NSLocalizedString(@"NEW_WORLD", nil);
        addButton.accessibilityHint = @"Adds a new world.";
        self.navigationItem.rightBarButtonItem = addButton;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(worldStoreDidChange:)
                                                     name:WorldStoreBridge.didChangeNotification
                                                   object:nil];
    }

    return self;
}

+ (SSWorldListViewController *)worldPickerViewControllerWithCompletion:(WorldPickerSelectionBlock)block {
    SSWorldListViewController *picker = [self new];

    picker.completeBlock = block;

    return picker;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self reloadWorlds];
}

- (void)reloadWorlds {
    NSArray<MUDWorldBridge *> *all = [WorldStoreBridge allWorlds];
    NSMutableArray<MUDWorldBridge *> *visible = [NSMutableArray array];
    for (MUDWorldBridge *w in all) {
        if ([w.name length] > 0 || [w.hostname length] > 0) {
            [visible addObject:w];
        }
    }
    [visible sortUsingComparator:^NSComparisonResult(MUDWorldBridge *a, MUDWorldBridge *b) {
        NSComparisonResult nameCompare = [a.name localizedCaseInsensitiveCompare:b.name];
        if (nameCompare != NSOrderedSame) return nameCompare;
        return [a.hostname localizedCaseInsensitiveCompare:b.hostname];
    }];
    self.worlds = visible;
    [self.tableView reloadData];
}

- (void)worldStoreDidChange:(NSNotification *)notification {
    [self reloadWorlds];
}

- (CGSize)preferredContentSize {
    return [self.tableView sizeThatFits:CGSizeMake(320, CGFLOAT_MAX)];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _completeBlock = nil;
}

#pragma mark - actions

- (void)addWorld:(id)sender {
    NSString *newWorldId = [WorldStoreBridge addEmptyWorld];

    SSWorldEditViewController *editor = [SSWorldEditViewController editorForWorldIdentifier:newWorldId];

    [self.navigationController pushViewController:editor
                                         animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.worlds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SSWorldCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SSWorldCell"];
    if (!cell) {
        cell = [[SSWorldCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SSWorldCell"];
    }

    MUDWorldBridge *world = self.worlds[(NSUInteger)indexPath.row];

    cell.textLabel.text = world.name;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumScaleFactor = 0.6f;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@:%d",
                                 world.hostname,
                                 world.port];

    if (self.completeBlock)
        cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.completeBlock == nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        MUDWorldBridge *world = self.worlds[(NSUInteger)indexPath.row];
        [WorldStoreBridge removeWorldWithIdentifier:world.identifier];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MUDWorldBridge *world = self.worlds[(NSUInteger)indexPath.row];

    [tv deselectRowAtIndexPath:indexPath animated:YES];

    if( self.completeBlock )
        self.completeBlock( world.identifier );
    else
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWorldChanged
                                                            object:world.identifier];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    MUDWorldBridge *world = self.worlds[(NSUInteger)indexPath.row];

    [self.navigationController pushViewController:[SSWorldEditViewController editorForWorldIdentifier:world.identifier]
                                         animated:YES];
}

@end
