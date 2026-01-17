#import "ModDownloadPopupViewController.h"

@interface ModDownloadPopupViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UISegmentedControl *tabSwitcher;
@property (nonatomic, strong) UIView *modListView;
@property (nonatomic, strong) UITableView *modTableView;
@property (nonatomic, strong) UIView *modDetailView;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIView *selectedModsView;
@property (nonatomic, strong) UIButton *confirmButton;

@property (nonatomic, strong) NSMutableArray *selectedMods;

@end

@implementation ModDownloadPopupViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.6f];
    self.selectedMods = [NSMutableArray array];
    
    [self setupUI];
}

- (void)setupUI {
    // 创建容器视图
    self.containerView = [[UIView alloc] init];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.containerView.backgroundColor = [UIColor colorWithRed:0.05f green:0.05f blue:0.05f alpha:1.0f];
    self.containerView.layer.cornerRadius = 24.0f;
    self.containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.containerView.layer.shadowOpacity = 0.8;
    self.containerView.layer.shadowOffset = CGSizeMake(0, 4);
    self.containerView.layer.shadowRadius = 54.0f;
    [self.view addSubview:self.containerView];
    
    // 创建顶部标签切换
    self.tabSwitcher = [[UISegmentedControl alloc] initWithItems:@[@"Modrinth", @"Curseforge"]];
    self.tabSwitcher.translatesAutoresizingMaskIntoConstraints = NO;
    self.tabSwitcher.selectedSegmentIndex = 0;
    self.tabSwitcher.backgroundColor = [UIColor clearColor];
    self.tabSwitcher.tintColor = [UIColor colorWithRed:0.133f green:0.710f blue:1.0f alpha:1.0f];
    [self.containerView addSubview:self.tabSwitcher];
    
    // 创建标签指示器
    UIView *tabIndicator = [[UIView alloc] init];
    tabIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    tabIndicator.backgroundColor = [UIColor colorWithRed:0.133f green:0.710f blue:1.0f alpha:1.0f];
    tabIndicator.layer.cornerRadius = 2.0f;
    [self.containerView addSubview:tabIndicator];
    
    // 创建主要内容容器
    UIView *contentContainer = [[UIView alloc] init];
    contentContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:contentContainer];
    
    // 创建左侧Mod列表
    self.modListView = [[UIView alloc] init];
    self.modListView.translatesAutoresizingMaskIntoConstraints = NO;
    self.modListView.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.8f];
    self.modListView.layer.borderWidth = 1.0f;
    self.modListView.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.1f].CGColor;
    self.modListView.layer.cornerRadius = 9.0f;
    [contentContainer addSubview:self.modListView];
    
    // 创建Mod列表表格
    self.modTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.modTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.modTableView.dataSource = self;
    self.modTableView.delegate = self;
    self.modTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.modTableView.backgroundColor = [UIColor clearColor];
    self.modTableView.rowHeight = 64.0f;
    [self.modListView addSubview:self.modTableView];
    
    // 创建右侧Mod详情
    self.modDetailView = [[UIView alloc] init];
    self.modDetailView.translatesAutoresizingMaskIntoConstraints = NO;
    self.modDetailView.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.8f];
    self.modDetailView.layer.borderWidth = 1.0f;
    self.modDetailView.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.1f].CGColor;
    self.modDetailView.layer.cornerRadius = 9.0f;
    [contentContainer addSubview:self.modDetailView];
    
    // 创建版本选择下拉框
    UIView *versionDropdown = [self createDropdownWithTitle:@"Sodium 0.5.8"];
    [self.modDetailView addSubview:versionDropdown];
    
    // 创建版本信息标签
    UILabel *versionInfoLabel = [[UILabel alloc] init];
    versionInfoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    versionInfoLabel.text = @"Fabric, Quilt - 1.20.3-1.20.4";
    versionInfoLabel.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightRegular];
    versionInfoLabel.textColor = [UIColor whiteColor];
    [self.modDetailView addSubview:versionInfoLabel];
    
    // 创建截图
    UIView *screenshotView = [[UIView alloc] init];
    screenshotView.translatesAutoresizingMaskIntoConstraints = NO;
    screenshotView.backgroundColor = [UIColor colorWithRed:0.15f green:0.15f blue:0.15f alpha:1.0f];
    screenshotView.layer.cornerRadius = 8.0f;
    [self.modDetailView addSubview:screenshotView];
    
    // 创建底部操作栏
    self.bottomBar = [[UIView alloc] init];
    self.bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.bottomBar];
    
    // 创建已选Mod容器
    self.selectedModsView = [[UIView alloc] init];
    self.selectedModsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bottomBar addSubview:self.selectedModsView];
    
    // 创建确认下载按钮
    self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.confirmButton setTitle:@"Confirm & Download" forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [UIColor colorWithRed:0.133f green:0.710f blue:1.0f alpha:0.75f];
    self.confirmButton.layer.cornerRadius = 9.0f;
    self.confirmButton.tintColor = [UIColor whiteColor];
    self.confirmButton.titleLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightMedium];
    [self.bottomBar addSubview:self.confirmButton];
    
    // 设置约束
    [NSLayoutConstraint activateConstraints:@[
        // 容器视图
        [self.containerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.containerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.containerView.widthAnchor constraintEqualToConstant:1189.0f],
        [self.containerView.heightAnchor constraintEqualToConstant:955.0f],
        
        // 标签切换
        [self.tabSwitcher.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:64.0f],
        [self.tabSwitcher.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        
        // 标签指示器
        [tabIndicator.topAnchor constraintEqualToAnchor:self.tabSwitcher.bottomAnchor constant:4.0f],
        [tabIndicator.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [tabIndicator.widthAnchor constraintEqualToConstant:80.0f],
        [tabIndicator.heightAnchor constraintEqualToConstant:4.0f],
        
        // 主要内容容器
        [contentContainer.topAnchor constraintEqualToAnchor:tabIndicator.bottomAnchor constant:16.0f],
        [contentContainer.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:47.0f],
        [contentContainer.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-47.0f],
        [contentContainer.bottomAnchor constraintEqualToAnchor:self.bottomBar.topAnchor constant:-12.0f],
        
        // Mod列表
        [self.modListView.leadingAnchor constraintEqualToAnchor:contentContainer.leadingAnchor],
        [self.modListView.topAnchor constraintEqualToAnchor:contentContainer.topAnchor],
        [self.modListView.bottomAnchor constraintEqualToAnchor:contentContainer.bottomAnchor],
        [self.modListView.widthAnchor constraintEqualToAnchor:contentContainer.widthAnchor multiplier:0.4],
        
        // Mod列表表格
        [self.modTableView.leadingAnchor constraintEqualToAnchor:self.modListView.leadingAnchor],
        [self.modTableView.trailingAnchor constraintEqualToAnchor:self.modListView.trailingAnchor],
        [self.modTableView.topAnchor constraintEqualToAnchor:self.modListView.topAnchor],
        [self.modTableView.bottomAnchor constraintEqualToAnchor:self.modListView.bottomAnchor],
        
        // Mod详情
        [self.modDetailView.leadingAnchor constraintEqualToAnchor:self.modListView.trailingAnchor constant:16.0f],
        [self.modDetailView.topAnchor constraintEqualToAnchor:contentContainer.topAnchor],
        [self.modDetailView.bottomAnchor constraintEqualToAnchor:contentContainer.bottomAnchor],
        [self.modDetailView.trailingAnchor constraintEqualToAnchor:contentContainer.trailingAnchor],
        
        // 版本下拉框
        [versionDropdown.leadingAnchor constraintEqualToAnchor:self.modDetailView.leadingAnchor constant:47.0f],
        [versionDropdown.topAnchor constraintEqualToAnchor:self.modDetailView.topAnchor constant:47.0f],
        [versionDropdown.trailingAnchor constraintEqualToAnchor:self.modDetailView.trailingAnchor constant:-47.0f],
        [versionDropdown.heightAnchor constraintEqualToConstant:48.0f],
        
        // 版本信息
        [versionInfoLabel.centerXAnchor constraintEqualToAnchor:self.modDetailView.centerXAnchor],
        [versionInfoLabel.topAnchor constraintEqualToAnchor:versionDropdown.bottomAnchor constant:12.0f],
        
        // 截图
        [screenshotView.leadingAnchor constraintEqualToAnchor:self.modDetailView.leadingAnchor constant:47.0f],
        [screenshotView.topAnchor constraintEqualToAnchor:versionInfoLabel.bottomAnchor constant:20.0f],
        [screenshotView.widthAnchor constraintEqualToConstant:426.0f],
        [screenshotView.heightAnchor constraintEqualToConstant:241.0f],
        
        // 底部操作栏
        [self.bottomBar.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:47.0f],
        [self.bottomBar.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-47.0f],
        [self.bottomBar.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor constant:-64.0f],
        [self.bottomBar.heightAnchor constraintEqualToConstant:42.0f],
        
        // 已选Mod
        [self.selectedModsView.leadingAnchor constraintEqualToAnchor:self.bottomBar.leadingAnchor],
        [self.selectedModsView.topAnchor constraintEqualToAnchor:self.bottomBar.topAnchor],
        [self.selectedModsView.bottomAnchor constraintEqualToAnchor:self.bottomBar.bottomAnchor],
        [self.selectedModsView.trailingAnchor constraintEqualToAnchor:self.confirmButton.leadingAnchor constant:-12.0f],
        
        // 确认按钮
        [self.confirmButton.trailingAnchor constraintEqualToAnchor:self.bottomBar.trailingAnchor],
        [self.confirmButton.centerYAnchor constraintEqualToAnchor:self.bottomBar.centerYAnchor],
        [self.confirmButton.heightAnchor constraintEqualToAnchor:self.bottomBar.heightAnchor],
        [self.confirmButton.widthAnchor constraintEqualToConstant:200.0f],
    ]];
}

- (UIView *)createDropdownWithTitle:(NSString *)title {
    UIView *dropdownView = [[UIView alloc] init];
    dropdownView.translatesAutoresizingMaskIntoConstraints = NO;
    dropdownView.backgroundColor = [UIColor colorWithRed:0.15f green:0.15f blue:0.15f alpha:1.0f];
    dropdownView.layer.borderWidth = 1.0f;
    dropdownView.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.05f].CGColor;
    dropdownView.layer.cornerRadius = 9.0f;
    
    // 创建水平StackView
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.spacing = 8.0f;
    stackView.alignment = UIStackViewAlignmentCenter;
    [dropdownView addSubview:stackView];
    
    // 添加标题标签
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor whiteColor];
    [stackView addArrangedSubview:titleLabel];
    
    // 添加占位符
    [stackView addArrangedSubview:[UIView new]];
    
    // 添加下拉图标
    UIImage *iconImage = [UIImage systemImageNamed:@"chevron.down"];
    UIImageView *iconView = [[UIImageView alloc] initWithImage:iconImage];
    iconView.tintColor = [UIColor whiteColor];
    [iconView.widthAnchor constraintEqualToConstant:10.0f].active = YES;
    [iconView.heightAnchor constraintEqualToConstant:6.0f].active = YES;
    [stackView addArrangedSubview:iconView];
    
    // 设置StackView约束
    [NSLayoutConstraint activateConstraints:@[
        [stackView.leadingAnchor constraintEqualToAnchor:dropdownView.leadingAnchor constant:23.0f],
        [stackView.trailingAnchor constraintEqualToAnchor:dropdownView.trailingAnchor constant:-23.0f],
        [stackView.topAnchor constraintEqualToAnchor:dropdownView.topAnchor],
        [stackView.bottomAnchor constraintEqualToAnchor:dropdownView.bottomAnchor]
    ]];
    
    return dropdownView;
}

#pragma mark - UITableView DataSource & Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.mods.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ModCell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ModCell"];
    }
    
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    
    // 添加自定义背景
    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.backgroundColor = [UIColor colorWithRed:0.15f green:0.15f blue:0.15f alpha:1.0f];
    backgroundView.layer.borderWidth = 1.0f;
    backgroundView.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.1f].CGColor;
    backgroundView.layer.cornerRadius = 9.0f;
    backgroundView.frame = CGRectMake(0, 0, cell.contentView.bounds.size.width, 64.0f);
    [cell.contentView insertSubview:backgroundView atIndex:0];
    
    // 设置Mod名称
    cell.textLabel.text = [self.mods[indexPath.row] valueForKey:@"name"];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightMedium];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // 处理Mod选择
    NSDictionary *selectedMod = self.mods[indexPath.row];
    if ([self.selectedMods containsObject:selectedMod]) {
        [self.selectedMods removeObject:selectedMod];
    } else {
        [self.selectedMods addObject:selectedMod];
    }
    
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end
