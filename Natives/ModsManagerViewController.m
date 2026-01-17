#import "ModsManagerViewController.h"
#import "ModTableViewCell.h"
#import "ModService.h"
#import "ModItem.h"
#import "installer/modpack/ModrinthAPI.h"
#import "ModDownloadPopupViewController.h"

@interface ModsManagerViewController () <UITableViewDataSource, UITableViewDelegate, ModTableViewCellDelegate, UISearchBarDelegate, ModVersionViewControllerDelegate, ModDownloadPopupViewControllerDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@property (nonatomic, strong) NSMutableArray<ModItem *> *localMods;
@property (nonatomic, strong) NSMutableArray<ModItem *> *filteredLocalMods;

@end

@implementation ModsManagerViewController

// ... (viewDidLoad, setupUI, modeChanged, updateUIForCurrentMode, updateNavigationButtons are the same)

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"管理 Mod";
    self.currentMode = ModsManagerModeLocal;
    self.localMods = [NSMutableArray array];
    self.filteredLocalMods = [NSMutableArray array];
    self.onlineSearchResults = [NSMutableArray array];
    [self setupUI];
    [self refreshLocalModsList];
}

- (void)setupUI {
    // 设置背景色
    self.view.backgroundColor = [UIColor colorWithRed:0.05f green:0.05f blue:0.05f alpha:1.0f];
    
    // 创建顶部操作栏容器
    UIView *topBarContainer = [[UIView alloc] init];
    topBarContainer.translatesAutoresizingMaskIntoConstraints = NO;
    topBarContainer.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.8f];
    topBarContainer.layer.borderWidth = 1.0f;
    topBarContainer.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.1f].CGColor;
    topBarContainer.layer.cornerRadius = 16.0f;
    [self.view addSubview:topBarContainer];
    
    // 创建左侧按钮Stack
    UIStackView *leftButtonsStack = [[UIStackView alloc] init];
    leftButtonsStack.translatesAutoresizingMaskIntoConstraints = NO;
    leftButtonsStack.axis = UILayoutConstraintAxisHorizontal;
    leftButtonsStack.spacing = 32.0f;
    [topBarContainer addSubview:leftButtonsStack];
    
    // 创建Download Mods按钮
    UIButton *downloadModsButton = [self createTopBarButtonWithTitle:@"Download Mods"];
    [downloadModsButton setTintColor:[UIColor whiteColor]];
    [leftButtonsStack addArrangedSubview:downloadModsButton];
    
    // 创建Add Mod Files按钮
    UIButton *addModFilesButton = [self createTopBarButtonWithTitle:@"Add Mod Files"];
    [addModFilesButton setTintColor:[UIColor whiteColor]];
    [leftButtonsStack addArrangedSubview:addModFilesButton];
    
    // 创建Select按钮
    UIButton *selectButton = [self createTopBarButtonWithTitle:@"Select"];
    [selectButton setTintColor:[UIColor whiteColor]];
    [leftButtonsStack addArrangedSubview:selectButton];
    
    // 创建右侧排序按钮
    UIButton *sortButton = [self createSortButton];
    [topBarContainer addSubview:sortButton];
    
    // 创建搜索栏
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"搜索本地 Mod...";
    self.searchBar.backgroundColor = [UIColor clearColor];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    
    // 适配iOS 14.0+的搜索栏样式
    if (@available(iOS 13.0, *)) {
        self.searchBar.searchTextField.backgroundColor = [UIColor colorWithRed:0.15f green:0.15f blue:0.15f alpha:1.0f];
        self.searchBar.searchTextField.textColor = [UIColor whiteColor];
        self.searchBar.searchTextField.placeholderColor = [UIColor colorWithWhite:1.0f alpha:0.7f];
    }
    
    [self.view addSubview:self.searchBar];
    
    // 创建表格视图
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView registerClass:[ModTableViewCell class] forCellReuseIdentifier:@"ModCell"];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 64.0f;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = [UIView new];
    [self.view addSubview:self.tableView];
    
    // 创建下拉刷新控件
    UIRefreshControl *rc = [UIRefreshControl new];
    rc.tintColor = [UIColor whiteColor];
    [rc addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = rc;
    
    // 创建加载指示器
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator.tintColor = [UIColor whiteColor];
    [self.view addSubview:self.activityIndicator];
    
    // 创建空状态标签
    self.emptyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.textColor = [UIColor colorWithWhite:1.0f alpha:0.7f];
    self.emptyLabel.hidden = YES;
    self.emptyLabel.font = [UIFont systemFontOfSize:15.0f];
    [self.view addSubview:self.emptyLabel];
    
    // 设置约束
    [NSLayoutConstraint activateConstraints:@[
        // 顶部操作栏
        [topBarContainer.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0f],
        [topBarContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0f],
        [topBarContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0f],
        [topBarContainer.heightAnchor constraintEqualToConstant:48.0f],
        
        // 左侧按钮Stack
        [leftButtonsStack.leadingAnchor constraintEqualToAnchor:topBarContainer.leadingAnchor constant:20.0f],
        [leftButtonsStack.centerYAnchor constraintEqualToAnchor:topBarContainer.centerYAnchor],
        
        // 右侧排序按钮
        [sortButton.trailingAnchor constraintEqualToAnchor:topBarContainer.trailingAnchor constant:-20.0f],
        [sortButton.centerYAnchor constraintEqualToAnchor:topBarContainer.centerYAnchor],
        
        // 搜索栏
        [self.searchBar.topAnchor constraintEqualToAnchor:topBarContainer.bottomAnchor constant:24.0f],
        [self.searchBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0f],
        [self.searchBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0f],
        [self.searchBar.heightAnchor constraintEqualToConstant:44.0f],
        
        // 表格视图
        [self.tableView.topAnchor constraintEqualToAnchor:self.searchBar.bottomAnchor constant:24.0f],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20.0f],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0f],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0f],
        
        // 加载指示器
        [self.activityIndicator.centerXAnchor constraintEqualToAnchor:self.tableView.centerXAnchor],
        [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.tableView.centerYAnchor],
        
        // 空状态标签
        [self.emptyLabel.centerXAnchor constraintEqualToAnchor:self.tableView.centerXAnchor],
        [self.emptyLabel.centerYAnchor constraintEqualToAnchor:self.tableView.centerYAnchor]
    ]];
}



- (void)updateUIForCurrentMode {
    if (self.currentMode == ModsManagerModeLocal) {
        self.searchBar.placeholder = @"搜索本地 Mod...";
        self.emptyLabel.text = @"未发现 Mod";
        self.emptyLabel.hidden = self.localMods.count > 0;
    } else {
        self.searchBar.placeholder = @"在线搜索 Modrinth...";
        self.emptyLabel.text = @"输入关键词进行在线搜索";
        self.emptyLabel.hidden = self.onlineSearchResults.count > 0;
    }
    // Re-enable pull-to-refresh for all modes
    self.tableView.refreshControl.enabled = YES;
    [self updateNavigationButtons];
    [self.tableView reloadData];
}

- (void)updateNavigationButtons {
    // 统一显示刷新按钮
    self.navigationItem.rightBarButtonItems = @[self.refreshButton];
}

#pragma mark - Data Loading

- (void)handleRefresh:(id)sender {
    if (self.currentMode == ModsManagerModeLocal) {
        [self refreshLocalModsList];
    } else {
        // For online mode, only refresh if there's text, otherwise it's pointless.
        if (self.searchBar.text.length > 0) {
            [self performOnlineSearch];
        } else {
            // If no text, just end the refreshing indicator.
            [self.tableView.refreshControl endRefreshing];
        }
    }
}

- (void)setLoading:(BOOL)loading {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (loading) {
            self.emptyLabel.hidden = YES;
            [self.activityIndicator startAnimating];
        } else {
            [self.activityIndicator stopAnimating];
            [self.tableView.refreshControl endRefreshing];
        }
    });
}

- (void)refreshLocalModsList {
    if (self.currentMode != ModsManagerModeLocal) return;

    [self setLoading:YES];
    NSString *profile = self.profileName ?: @"default";
    [[ModService sharedService] scanModsForProfile:profile completion:^(NSArray<ModItem *> *mods) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.localMods removeAllObjects];
            [self.localMods addObjectsFromArray:mods];
            [self filterLocalMods];
            [self setLoading:NO];
        });
    }];
}

- (void)performOnlineSearch {
    NSString *searchText = self.searchBar.text;
    if (searchText.length == 0) return;

    [self setLoading:YES];
    [self.onlineSearchResults removeAllObjects];
    [self.tableView reloadData];

    NSDictionary *filters = @{@"name": searchText};

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableArray *modrinthResults = [[ModrinthAPI sharedInstance] searchModWithFilters:filters previousPageResult:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (modrinthResults) {
                [self.onlineSearchResults addObjectsFromArray:modrinthResults];
            }
            [self setLoading:NO];
            self.emptyLabel.hidden = self.onlineSearchResults.count > 0;
            if (self.onlineSearchResults.count == 0) {
                self.emptyLabel.text = @"未找到在线结果";
            }
            [self.tableView reloadData];
        });
    });
}


#pragma mark - UISearchBarDelegate
// ... (search bar delegate methods are the same)
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (self.currentMode == ModsManagerModeLocal) {
        [self filterLocalMods];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    if (self.currentMode == ModsManagerModeOnline) {
        [self performOnlineSearch];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    if (self.currentMode == ModsManagerModeLocal) {
        [self filterLocalMods];
    } else {
        [self.onlineSearchResults removeAllObjects];
        [self.tableView reloadData];
        [self updateUIForCurrentMode];
    }
}

- (void)filterLocalMods {
    [self.filteredLocalMods removeAllObjects];
    if (self.searchBar.text.length == 0) {
        [self.filteredLocalMods addObjectsFromArray:self.localMods];
    } else {
        NSString *searchText = [self.searchBar.text lowercaseString];
        for (ModItem *mod in self.localMods) {
            if ([mod.displayName.lowercaseString containsString:searchText] ||
                [mod.fileName.lowercaseString containsString:searchText]) {
                [self.filteredLocalMods addObject:mod];
            }
        }
    }
    self.emptyLabel.hidden = self.filteredLocalMods.count > 0;
    if (!self.emptyLabel.hidden) {
        self.emptyLabel.text = @"未找到本地 Mod";
    }
    [self.tableView reloadData];
}

#pragma mark - UITableView DataSource & Delegate
// ... (UITableView methods are the same)
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 64.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    // 创建表头视图
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor clearColor];
    
    // 添加自定义背景
    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.8f];
    backgroundView.layer.borderWidth = 1.0f;
    backgroundView.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.1f].CGColor;
    backgroundView.layer.cornerRadius = 16.0f;
    backgroundView.frame = CGRectMake(0, 0, headerView.bounds.size.width, 64.0f);
    [headerView addSubview:backgroundView];
    
    // 创建列标题数组
    NSArray *columnTitles = @[@"Image", @"Mod Name", @"Mod version", @"Mod source", @"Last updated"];
    
    // 创建列标题标签
    CGFloat padding = 24.0f;
    CGFloat iconSize = 64.0f;
    CGFloat labelWidth = 150.0f;
    
    for (int i = 0; i < columnTitles.count; i++) {
        UILabel *label = [[UILabel alloc] init];
        label.text = columnTitles[i];
        label.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightMedium];
        label.textColor = [UIColor colorWithWhite:1.0f alpha:0.7f];
        
        if (i == 0) {
            // Image column
            label.frame = CGRectMake(padding, 24.0f, iconSize, 22.0f);
        } else if (i == 1) {
            // Mod Name column
            label.frame = CGRectMake(padding + iconSize + 24.0f, 24.0f, 200.0f, 22.0f);
        } else {
            // Other columns
            CGFloat xOffset = padding + iconSize + 24.0f + 200.0f + (i - 2) * (labelWidth + 80.0f);
            label.frame = CGRectMake(xOffset, 24.0f, labelWidth, 22.0f);
        }
        
        [headerView addSubview:label];
    }
    
    return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.currentMode == ModsManagerModeLocal ? self.filteredLocalMods.count : self.onlineSearchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ModTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ModCell" forIndexPath:indexPath];
    cell.delegate = self;

    if (self.currentMode == ModsManagerModeLocal) {
        ModItem *mod = self.filteredLocalMods[indexPath.row];
        [cell configureWithMod:mod displayMode:ModTableViewCellDisplayModeLocal];
    } else {
        NSDictionary *modData = self.onlineSearchResults[indexPath.row];
        ModItem *modItem = [[ModItem alloc] initWithOnlineData:modData];
        [cell configureWithMod:modItem displayMode:ModTableViewCellDisplayModeOnline];
    }

    return cell;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.currentMode != ModsManagerModeLocal) {
        return nil;
    }

    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"删除" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {

        ModItem *modToDelete = self.filteredLocalMods[indexPath.row];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认删除" message:[NSString stringWithFormat:@"确定要删除 %@ 吗？\n此操作无法撤销。", modToDelete.displayName] preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            completionHandler(NO);
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            NSError *error = nil;
            [[ModService sharedService] deleteMod:modToDelete error:&error];

            if (error) {
                NSLog(@"[ModsManager] Error deleting mod: %@", error);
                // Optionally show an alert to the user
                completionHandler(NO);
            } else {
                // Remove from data source
                NSInteger indexInFullList = [self.localMods indexOfObject:modToDelete];
                if (indexInFullList != NSNotFound) {
                    [self.localMods removeObjectAtIndex:indexInFullList];
                }
                [self.filteredLocalMods removeObjectAtIndex:indexPath.row];

                // Perform the table view update
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

                completionHandler(YES);
            }
        }]];

        [self presentViewController:alert animated:YES completion:nil];
    }];

    deleteAction.backgroundColor = [UIColor systemRedColor];

    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
    configuration.performsFirstActionWithFullSwipe = YES; // Allow full swipe to delete

    return configuration;
}


#pragma mark - ModTableViewCellDelegate (Download Implementation)

- (void)modCellDidTapDownload:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (!indexPath || self.currentMode != ModsManagerModeOnline) return;

    // 获取所有在线Mod数据
    NSArray *allMods = self.onlineSearchResults;
    
    // 创建并显示下载弹窗
    ModDownloadPopupViewController *popupVC = [[ModDownloadPopupViewController alloc] init];
    popupVC.mods = allMods;
    popupVC.delegate = self;
    
    [self presentViewController:popupVC animated:YES completion:nil];
}

#pragma mark - ModVersionViewControllerDelegate

- (void)modVersionViewController:(ModVersionViewController *)viewController didSelectVersion:(ModVersion *)version {
    ModItem *itemToDownload = viewController.modItem;
    
    // Find the primary file to download
    NSDictionary *primaryFile = version.primaryFile;
    if (!primaryFile || ![primaryFile[@"url"] isKindOfClass:[NSString class]]) {
        [self showSimpleAlertWithTitle:@"错误" message:@"未找到有效的下载链接。"];
        return;
    }

    itemToDownload.selectedVersionDownloadURL = primaryFile[@"url"];
    itemToDownload.fileName = primaryFile[@"filename"];

    [self startDownloadForItem:itemToDownload];
}

#pragma mark - ModDownloadPopupViewControllerDelegate

- (void)modDownloadPopupViewControllerDidConfirmDownload:(NSArray *)selectedMods {
    // 处理确认下载逻辑
    for (NSDictionary *modData in selectedMods) {
        ModItem *modItem = [[ModItem alloc] initWithOnlineData:modData];
        // 这里可以添加下载逻辑
        NSLog(@"Downloading mod: %@", modItem.displayName);
    }
    
    // 显示下载成功提示
    [self showSimpleAlertWithTitle:@"下载成功" message:[NSString stringWithFormat:@"已成功添加 %lu 个 Mod 到下载队列。", (unsigned long)selectedMods.count]];
}

- (void)modDownloadPopupViewControllerDidCancel {
    // 处理取消逻辑
    NSLog(@"Download canceled");
}

- (void)startDownloadForItem:(ModItem *)item {
    // Show a temporary "downloading" alert
    UIAlertController *downloadingAlert = [UIAlertController alertControllerWithTitle:@"正在下载"
                                                                              message:[NSString stringWithFormat:@"%@...", item.displayName]
                                                                       preferredStyle:UIAlertControllerStyleAlert];

    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    indicator.translatesAutoresizingMaskIntoConstraints = NO;
    [downloadingAlert.view addSubview:indicator];
    [NSLayoutConstraint activateConstraints:@[
        [indicator.centerXAnchor constraintEqualToAnchor:downloadingAlert.view.centerXAnchor],
        [indicator.centerYAnchor constraintEqualToAnchor:downloadingAlert.view.centerYAnchor constant:20]
    ]];
    [indicator startAnimating];

    [self presentViewController:downloadingAlert animated:YES completion:nil];

    [[ModService sharedService] downloadMod:item toProfile:self.profileName completion:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // First, dismiss the "downloading" alert
            [downloadingAlert dismissViewControllerAnimated:YES completion:^{
                // Then, show the result alert
                if (error) {
                    [self showSimpleAlertWithTitle:@"下载失败" message:error.localizedDescription];
                } else {
                    UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"下载成功"
                                                                                          message:[NSString stringWithFormat:@"%@ 已成功安装。", item.displayName]
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                    [successAlert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        // After user acknowledges, switch to local mods and refresh
                        [self.modeSwitcher setSelectedSegmentIndex:0];
                        [self modeChanged:self.modeSwitcher];
                        [self refreshLocalModsList];
                    }]];
                    [self presentViewController:successAlert animated:YES completion:nil];
                }
            }];
        });
    }];
}

- (void)showSimpleAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.currentMode == ModsManagerModeOnline) {
        // Handle online search item selection if necessary (e.g., show details)
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)modCellDidTapToggle:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (!indexPath || self.currentMode != ModsManagerModeLocal) return;

    ModItem *mod = self.filteredLocalMods[indexPath.row];

    NSError *error = nil;
    BOOL success = [[ModService sharedService] toggleEnableForMod:mod error:&error];

    if (!success) {
        NSLog(@"[ModsManager] Error toggling mod: %@", error);
        // Optionally show an alert to the user
        // Revert the switch state if the operation failed
        [(ModTableViewCell *)cell updateToggleState:mod.disabled];
    } else {
        // The service already changed the mod's state, so we just update the UI
        [(ModTableViewCell *)cell updateToggleState:mod.disabled];
    }
}

- (void)modCellDidTapOpenLink:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (!indexPath) return;

    ModItem *modItem = nil;
    if (self.currentMode == ModsManagerModeLocal) {
        modItem = self.filteredLocalMods[indexPath.row];
    } else {
        NSDictionary *modData = self.onlineSearchResults[indexPath.row];
        modItem = [[ModItem alloc] initWithOnlineData:modData];
    }

    if (modItem.onlineID && modItem.onlineID.length > 0) {
        NSString *urlString = [NSString stringWithFormat:@"https://modrinth.com/mod/%@", modItem.onlineID];
        NSURL *url = [NSURL URLWithString:urlString];
        if (url) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
    } else {
        // Optionally, inform the user that there's no link available
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"链接不可用" message:@"该 Mod 没有可用的在线链接。" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
