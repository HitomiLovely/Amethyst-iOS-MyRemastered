#import "LauncherMenuViewController.h"
#import "LauncherNavigationController.h"
#import "LauncherPreferences.h"
#import "LauncherPrefGameDirViewController.h"
#import "LauncherPrefManageJREViewController.h"
#import "LauncherProfileEditorViewController.h"
#import "LauncherProfilesViewController.h"
#import "PLProfiles.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
#import "UIKit+AFNetworking.h"
#pragma clang diagnostic pop
#import "UIKit+hook.h"
#import "installer/FabricInstallViewController.h"
#import "installer/ForgeInstallViewController.h"
#import "installer/ModpackInstallViewController.h"
#import "ios_uikit_bridge.h"
#import "utils.h"
#import "ModsManagerViewController.h"

typedef NS_ENUM(NSUInteger, LauncherProfilesCollectionSection) {
    kInstances,
    kProfiles
};

@interface ProfileCollectionViewCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *versionLabel;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIImageView *statusIndicator;
@property (nonatomic, strong) UIStackView *actionButtonsStack;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIButton *deleteButton;
@end

@interface InstanceSettingCollectionViewCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UISwitch *toggleSwitch;
@end

@implementation InstanceSettingCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.contentView.backgroundColor = [UIColor colorWithRed:0.05f green:0.05f blue:0.05f alpha:0.8f];
    self.contentView.layer.cornerRadius = 12;
    self.contentView.layer.borderWidth = 1;
    self.contentView.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.1f].CGColor;
    self.contentView.clipsToBounds = YES;
    
    // 创建水平布局的StackView
    UIStackView *mainStack = [[UIStackView alloc] init];
    mainStack.translatesAutoresizingMaskIntoConstraints = NO;
    mainStack.axis = UILayoutConstraintAxisHorizontal;
    mainStack.spacing = 16;
    mainStack.alignment = UIStackViewAlignmentCenter;
    mainStack.distribution = UIStackViewDistributionFill;
    [self.contentView addSubview:mainStack];
    
    // 图标
    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [mainStack addArrangedSubview:self.iconImageView];
    
    // 文本信息的垂直StackView
    UIStackView *textStack = [[UIStackView alloc] init];
    textStack.axis = UILayoutConstraintAxisVertical;
    textStack.spacing = 4;
    textStack.alignment = UIStackViewAlignmentLeading;
    textStack.distribution = UIStackViewDistributionFill;
    [mainStack addArrangedSubview:textStack];
    
    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [UIColor whiteColor];
    [textStack addArrangedSubview:self.titleLabel];
    
    // 详情
    self.detailLabel = [[UILabel alloc] init];
    self.detailLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.detailLabel.textColor = [UIColor colorWithWhite:1.0f alpha:0.7f];
    [textStack addArrangedSubview:self.detailLabel];
    
    // 切换开关
    self.toggleSwitch = [[UISwitch alloc] init];
    self.toggleSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [mainStack addArrangedSubview:self.toggleSwitch];
    
    // 约束
    [NSLayoutConstraint activateConstraints:@[
        [mainStack.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16],
        [mainStack.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [mainStack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [mainStack.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-16],
        [self.iconImageView.widthAnchor constraintEqualToConstant:24],
        [self.iconImageView.heightAnchor constraintEqualToConstant:24],
    ]];
}

@end

@interface LauncherProfilesViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property(nonatomic) UIBarButtonItem *createButtonItem;
@property(nonatomic) UICollectionView *collectionView;
@property(nonatomic) UICollectionViewFlowLayout *collectionViewLayout;
@end

@implementation ProfileCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.contentView.backgroundColor = [UIColor colorWithRed:0.05f green:0.05f blue:0.05f alpha:0.8f];
    self.contentView.layer.cornerRadius = 12;
    self.contentView.layer.borderWidth = 1;
    self.contentView.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.1f].CGColor;
    self.contentView.clipsToBounds = YES;
    
    // Icon Image View
    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconImageView.layer.cornerRadius = 8;
    self.iconImageView.clipsToBounds = YES;
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:self.iconImageView];
    
    // Name Label
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.font = [UIFont systemFontOfSize:21 weight:UIFontWeightSemibold];
    self.nameLabel.textColor = [UIColor whiteColor];
    [self.contentView addSubview:self.nameLabel];
    
    // Version Label
    self.versionLabel = [[UILabel alloc] init];
    self.versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.versionLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.versionLabel.textColor = [UIColor colorWithWhite:1.0f alpha:0.7f];
    [self.contentView addSubview:self.versionLabel];
    
    // Status Container
    UIStackView *statusContainer = [[UIStackView alloc] init];
    statusContainer.translatesAutoresizingMaskIntoConstraints = NO;
    statusContainer.axis = UILayoutConstraintAxisHorizontal;
    statusContainer.spacing = 8;
    statusContainer.alignment = UIStackViewAlignmentCenter;
    [self.contentView addSubview:statusContainer];
    
    // Status Indicator
    self.statusIndicator = [[UIImageView alloc] init];
    self.statusIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [statusContainer addArrangedSubview:self.statusIndicator];
    
    // Status Label
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    self.statusLabel.textColor = [UIColor systemGreenColor];
    [statusContainer addArrangedSubview:self.statusLabel];
    
    // Action Buttons Stack
    self.actionButtonsStack = [[UIStackView alloc] init];
    self.actionButtonsStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.actionButtonsStack.axis = UILayoutConstraintAxisHorizontal;
    self.actionButtonsStack.spacing = 16;
    self.actionButtonsStack.alignment = UIStackViewAlignmentCenter;
    [self.contentView addSubview:self.actionButtonsStack];
    
    // Play Button
    self.playButton = [[UIButton alloc] init];
    [self.playButton setImage:[UIImage systemImageNamed:@"play.fill"] forState:UIControlStateNormal];
    self.playButton.tintColor = [UIColor whiteColor];
    [self.actionButtonsStack addArrangedSubview:self.playButton];
    
    // Settings Button
    self.settingsButton = [[UIButton alloc] init];
    [self.settingsButton setImage:[UIImage systemImageNamed:@"gearshape.fill"] forState:UIControlStateNormal];
    self.settingsButton.tintColor = [UIColor whiteColor];
    [self.actionButtonsStack addArrangedSubview:self.settingsButton];
    
    // Edit Button
    self.editButton = [[UIButton alloc] init];
    [self.editButton setImage:[UIImage systemImageNamed:@"pencil"] forState:UIControlStateNormal];
    self.editButton.tintColor = [UIColor whiteColor];
    [self.actionButtonsStack addArrangedSubview:self.editButton];
    
    // Delete Button
    self.deleteButton = [[UIButton alloc] init];
    [self.deleteButton setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    self.deleteButton.tintColor = [UIColor whiteColor];
    [self.actionButtonsStack addArrangedSubview:self.deleteButton];
    
    // Constraints
    [NSLayoutConstraint activateConstraints:@[
        // Icon Image View
        [self.iconImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:24],
        [self.iconImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],
        [self.iconImageView.widthAnchor constraintEqualToConstant:48],
        [self.iconImageView.heightAnchor constraintEqualToConstant:48],
        
        // Name Label
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.iconImageView.bottomAnchor constant:16],
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],
        [self.nameLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-24],
        
        // Version Label
        [self.versionLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:4],
        [self.versionLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],
        [self.versionLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-24],
        
        // Status Container
        [statusContainer.topAnchor constraintEqualToAnchor:self.versionLabel.bottomAnchor constant:8],
        [statusContainer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],
        
        // Action Buttons Stack
        [self.actionButtonsStack.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:24],
        [self.actionButtonsStack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-24],
        [self.actionButtonsStack.heightAnchor constraintEqualToConstant:24],
        
        // Button Sizes
        [self.playButton.widthAnchor constraintEqualToConstant:24],
        [self.playButton.heightAnchor constraintEqualToConstant:24],
        [self.settingsButton.widthAnchor constraintEqualToConstant:24],
        [self.settingsButton.heightAnchor constraintEqualToConstant:24],
        [self.editButton.widthAnchor constraintEqualToConstant:24],
        [self.editButton.heightAnchor constraintEqualToConstant:24],
        [self.deleteButton.widthAnchor constraintEqualToConstant:24],
        [self.deleteButton.heightAnchor constraintEqualToConstant:24],
        
        // Status Indicator
        [self.statusIndicator.widthAnchor constraintEqualToConstant:24],
        [self.statusIndicator.heightAnchor constraintEqualToConstant:24],
    ]];
}

@end

@implementation LauncherProfilesViewController

- (id)init {
    self = [super init];
    self.title = localize(@"Profiles", nil);
    return self;
}

- (NSString *)imageName {
    return @"MenuProfiles";
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIMenu *createMenu = [UIMenu menuWithTitle:localize(@"profile.title.create", nil) image:nil identifier:nil
    options:UIMenuOptionsDisplayInline
    children:@[
        [UIAction
            actionWithTitle:@"Vanilla" image:nil
            identifier:@"vanilla" handler:^(UIAction *action) {
                [self actionEditProfile:@{@"name": @"",
                    @"lastVersionId": @"latest-release"}];
            }],
        [UIAction
            actionWithTitle:@"Fabric/Quilt" image:nil
            identifier:@"fabric_or_quilt" handler:^(UIAction *action) {
                [self actionCreateFabricProfile];
            }],
        [UIAction
            actionWithTitle:@"Forge" image:nil
            identifier:@"forge" handler:^(UIAction *action) {
                [self actionCreateForgeProfile];
            }],
        [UIAction
            actionWithTitle:@"Modpack" image:nil
            identifier:@"modpack" handler:^(UIAction *action) {
                [self actionCreateModpackProfile];
            }],
        
    ]];
    self.createButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd menu:createMenu];

    // Create collection view layout
    self.collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    self.collectionViewLayout.sectionInset = UIEdgeInsetsMake(20, 20, 20, 20);
    self.collectionViewLayout.minimumLineSpacing = 20;
    self.collectionViewLayout.minimumInteritemSpacing = 20;
    
    // Create collection view
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.collectionViewLayout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    // Register cell classes
    [self.collectionView registerClass:[ProfileCollectionViewCell class] forCellWithReuseIdentifier:@"ProfileCell"];
    [self.collectionView registerClass:[InstanceSettingCollectionViewCell class] forCellWithReuseIdentifier:@"InstanceSettingCell"];
    // Register supplementary view for section headers
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SectionHeader"];
    
    // Set as main view
    self.view = self.collectionView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationItem.rightBarButtonItems = @[[sidebarViewController drawAccountButton], self.createButtonItem];

    [PLProfiles updateCurrent];
    [self.collectionView reloadData];
    [self.navigationController performSelector:@selector(reloadProfileList)];
}

- (void)actionTogglePrefIsolation:(UISwitch *)sender {
    if (!sender.isOn) {
        setPrefBool(@"internal.isolated", NO);
    }
    toggleIsolatedPref(sender.isOn);
}

- (void)actionCreateFabricProfile {
    FabricInstallViewController *vc = [FabricInstallViewController new];
    [self presentNavigatedViewController:vc];
}

- (void)actionCreateForgeProfile {
    ForgeInstallViewController *vc = [ForgeInstallViewController new];
    [self presentNavigatedViewController:vc];
}

- (void)actionCreateModpackProfile {
    ModpackInstallViewController *vc = [ModpackInstallViewController new];
    [self presentNavigatedViewController:vc];
}

- (void)actionEditProfile:(NSDictionary *)profile {
    LauncherProfileEditorViewController *vc = [LauncherProfileEditorViewController new];
    vc.profile = profile.mutableCopy;
    [self presentNavigatedViewController:vc];
}

- (void)presentNavigatedViewController:(UIViewController *)vc {
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - Manage Mods

- (void)openManageMods {
    ModsManagerViewController *vc = [ModsManagerViewController new];
    if (PLProfiles.current.selectedProfileName.length > 0) {
        vc.profileName = PLProfiles.current.selectedProfileName;
    } else {
        vc.profileName = @"default";
    }
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch (section) {
        case kInstances: return 3; // 显示实例设置选项
        case kProfiles: return [PLProfiles.current.profiles count];
        default: return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kInstances) {
        InstanceSettingCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"InstanceSettingCell" forIndexPath:indexPath];
        
        // 根据行号设置不同的实例设置选项
        if (indexPath.row == 0) {
            // 游戏目录
            [cell.iconImageView setImage:[UIImage systemImageNamed:@"folder"]];
            cell.titleLabel.text = localize(@"preference.title.game_directory", nil);
            cell.detailLabel.text = getenv("DEMO_LOCK") ? @".demo" : getPrefObject(@"general.game_directory");
            cell.toggleSwitch.hidden = YES;
        } else if (indexPath.row == 1) {
            // 独立偏好设置
            NSString *imageName;
            if (@available(iOS 15.0, *)) {
                imageName = @"folder.badge.gearshape";
            } else {
                imageName = @"folder.badge.gear";
            }
            [cell.iconImageView setImage:[UIImage systemImageNamed:imageName]];
            cell.titleLabel.text = localize(@"profile.title.separate_preference", nil);
            cell.detailLabel.text = localize(@"profile.detail.separate_preference", nil);
            cell.toggleSwitch.hidden = NO;
            [cell.toggleSwitch setOn:getPrefBool(@"internal.isolated") animated:NO];
            [cell.toggleSwitch addTarget:self action:@selector(actionTogglePrefIsolation:) forControlEvents:UIControlEventValueChanged];
        } else if (indexPath.row == 2) {
            // 管理 Mod
            [cell.iconImageView setImage:[UIImage systemImageNamed:@"puzzlepiece.extension"]];
            cell.titleLabel.text = @"管理 Mod";
            cell.detailLabel.text = nil;
            cell.toggleSwitch.hidden = YES;
        }
        
        return cell;
    } else {
        ProfileCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ProfileCell" forIndexPath:indexPath];
        
        NSMutableDictionary *profile = PLProfiles.current.profiles.allValues[indexPath.row];
        
        // 确保所有UI操作在主线程执行
        dispatch_async(dispatch_get_main_queue(), ^{        // 设置标题和版本
            cell.nameLabel.text = profile[@"name"];
            cell.versionLabel.text = profile[@"lastVersionId"];
            
            // 设置图标
            cell.iconImageView.layer.magnificationFilter = kCAFilterNearest;
            UIImage *fallbackImage = [[UIImage imageNamed:@"DefaultProfile"] _imageWithSize:CGSizeMake(48, 48)];
            [cell.iconImageView setImageWithURL:[NSURL URLWithString:profile[@"icon"]] placeholderImage:fallbackImage];
            
            // 设置状态
            cell.statusLabel.text = @"Running";
            cell.statusLabel.textColor = [UIColor systemGreenColor];
            [cell.statusIndicator setImage:[UIImage systemImageNamed:@"play.fill"]];
            cell.statusIndicator.tintColor = [UIColor systemGreenColor];
            
            // 添加渐变背景
            CAGradientLayer *gradientLayer = [CAGradientLayer layer];
            gradientLayer.frame = cell.contentView.bounds;
            gradientLayer.colors = @[(__bridge id)[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.6f].CGColor, 
                                     (__bridge id)[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.8f].CGColor];
            gradientLayer.startPoint = CGPointMake(0.5, 0.0);
            gradientLayer.endPoint = CGPointMake(0.5, 1.0);
            
            // Remove existing gradient layer if any
            for (CALayer *layer in cell.contentView.layer.sublayers) {
                if ([layer isKindOfClass:[CAGradientLayer class]]) {
                    [layer removeFromSuperlayer];
                    break;
                }
            }
            
            // Insert gradient layer at the bottom
            [cell.contentView.layer insertSublayer:gradientLayer atIndex:0];
        });
        
        return cell;
    }
}

#pragma mark - Collection View Delegate Flow Layout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
    
    if (indexPath.section == kInstances) {
        // 实例设置选项，占满一行
        return CGSizeMake(screenWidth - 40, 60); // 20 padding on each side
    } else {
        // Profile卡片，每行显示2个
        CGFloat cellWidth = (screenWidth - 60) / 2; // 20 padding on each side, 20 spacing between cells
        return CGSizeMake(cellWidth, 220); // Fixed height for cells
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kInstances) {
        // 处理实例设置选项的点击
        if (indexPath.row == 0) {
            // 游戏目录
            [self.navigationController pushViewController:[LauncherPrefGameDirViewController new] animated:YES];
        } else if (indexPath.row == 2) {
            // 管理 Mod
            [self openManageMods];
        }
    } else {
        // Profile卡片点击
        [self actionEditProfile:PLProfiles.current.profiles.allValues[indexPath.row]];
    }
}

#pragma mark - Header View

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"SectionHeader" forIndexPath:indexPath];
        
        // Clear any existing subviews
        for (UIView *subview in headerView.subviews) {
            [subview removeFromSuperview];
        }
        
        // Create header label
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
        titleLabel.textColor = [UIColor whiteColor];
        
        if (indexPath.section == kProfiles) {
            titleLabel.text = localize(@"profile.section.profiles", nil);
        }
        
        [headerView addSubview:titleLabel];
        
        // Add constraints
        [NSLayoutConstraint activateConstraints:@[
            [titleLabel.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor],
            [titleLabel.trailingAnchor constraintEqualToAnchor:headerView.trailingAnchor],
            [titleLabel.topAnchor constraintEqualToAnchor:headerView.topAnchor],
            [titleLabel.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor]
        ]];
        
        return headerView;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(0, 40);
}

@end