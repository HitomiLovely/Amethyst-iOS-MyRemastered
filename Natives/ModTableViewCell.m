#import "ModTableViewCell.h"
#import "ModItem.h"
#import "ModService.h"
#import <QuartzCore/QuartzCore.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
#import "UIKit+AFNetworking.h"
#pragma clang diagnostic pop

@interface ModTableViewCell ()
@property (nonatomic, strong) ModItem *currentMod;
@property (nonatomic, strong) UIImageView *loaderIconView;
@end

@implementation ModTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor]; // Use clear color for custom background
        self.contentView.backgroundColor = [UIColor clearColor];

        // --- Initialization of UI Elements ---
    _modIconView = [self createImageViewWithCornerRadius:8];
    _nameLabel = [self createLabelWithFont:[UIFont systemFontOfSize:15 weight:UIFontWeightMedium] textColor:[UIColor whiteColor] numberOfLines:1];

    _loaderIconView = [self createImageViewWithCornerRadius:0];

    // --- NEW: Version Labels ---
    _modVersionLabel = [self createLabelWithFont:[UIFont systemFontOfSize:15 weight:UIFontWeightRegular] textColor:[UIColor whiteColor] numberOfLines:1];
    _gameVersionLabel = [self createLabelWithFont:[UIFont systemFontOfSize:12 weight:UIFontWeightMedium] textColor:[UIColor systemGreenColor] numberOfLines:1];

    _authorLabel = [self createLabelWithFont:[UIFont systemFontOfSize:12] textColor:[UIColor colorWithWhite:1.0f alpha:0.7f] numberOfLines:1];
    _descLabel = [self createLabelWithFont:[UIFont systemFontOfSize:12] textColor:[UIColor colorWithWhite:1.0f alpha:0.7f] numberOfLines:2];
    _statsLabel = [self createLabelWithFont:[UIFont systemFontOfSize:12] textColor:[UIColor colorWithWhite:1.0f alpha:0.7f] numberOfLines:1];
    _categoryLabel = [self createLabelWithFont:[UIFont systemFontOfSize:12] textColor:[UIColor colorWithRed:0.133f green:0.710f blue:1.0f alpha:1.0f] numberOfLines:1];

        _enableSwitch = [[UISwitch alloc] init];
        _enableSwitch.transform = CGAffineTransformMakeScale(0.75, 0.75); // Scale down for compact view
        _enableSwitch.translatesAutoresizingMaskIntoConstraints = NO;
        [_enableSwitch addTarget:self action:@selector(toggleTapped) forControlEvents:UIControlEventValueChanged];

        _downloadButton = [self createButtonWithTitle:@"下载" titleColor:[UIColor whiteColor] action:@selector(downloadTapped)];
        _downloadButton.backgroundColor = [UIColor systemGreenColor];
        _downloadButton.layer.cornerRadius = 10;
        _downloadButton.titleLabel.font = [UIFont boldSystemFontOfSize:10];
        _downloadButton.contentEdgeInsets = UIEdgeInsetsMake(4, 8, 4, 8);

        _openLinkButton = [self createButtonWithImage:[UIImage systemImageNamed:@"globe"] action:@selector(openLinkTapped)];

        _loaderBadgesStackView = [[UIStackView alloc] init];
        _loaderBadgesStackView.translatesAutoresizingMaskIntoConstraints = NO;
        _loaderBadgesStackView.axis = UILayoutConstraintAxisHorizontal;
        _loaderBadgesStackView.spacing = 4;
        _loaderBadgesStackView.alignment = UIStackViewAlignmentCenter;

        // Add subviews
        [self.contentView addSubview:_loaderBadgesStackView];
        [self.contentView addSubview:_modIconView];
        [self.contentView addSubview:_loaderIconView];
        [self.contentView addSubview:_nameLabel];
        [self.contentView addSubview:_modVersionLabel];
        [self.contentView addSubview:_gameVersionLabel];
        [self.contentView addSubview:_authorLabel];
        [self.contentView addSubview:_descLabel];
        [self.contentView addSubview:_statsLabel];
        [self.contentView addSubview:_categoryLabel];
        [self.contentView addSubview:_enableSwitch];
        [self.contentView addSubview:_downloadButton];
        [self.contentView addSubview:_openLinkButton];

        [self setupConstraints];
    }
    return self;
}

#pragma mark - UI Element Factory Methods

- (UIImageView *)createImageViewWithCornerRadius:(CGFloat)radius {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.layer.cornerRadius = radius;
    imageView.clipsToBounds = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    return imageView;
}

- (UILabel *)createLabelWithFont:(UIFont *)font textColor:(UIColor *)color numberOfLines:(NSInteger)lines {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = font;
    label.textColor = color;
    label.numberOfLines = lines;
    [label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    return label;
}

- (UIButton *)createButtonWithAction:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIButton *)createButtonWithTitle:(NSString *)title titleColor:(UIColor *)color action:(SEL)action {
    UIButton *button = [self createButtonWithAction:action];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:color forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    return button;
}

- (UIButton *)createButtonWithImage:(UIImage *)image action:(SEL)action {
    UIButton *button = [self createButtonWithAction:action];
    [button setImage:image forState:UIControlStateNormal];
    return button;
}

- (UIImageView *)createBadgeImageView:(NSString *)imageName {
    UIImage *image = [self loadImageWithName:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    return imageView;
}

- (UIImage *)loadImageWithName:(NSString *)imageName {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *resourcePath = [bundle resourcePath];
    
    // Check if dark mode is active
    BOOL isDarkMode = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    
    // Try to load appropriate theme version first
    NSString *theme = isDarkMode ? @"dark" : @"light";
    NSString *imagePath = [resourcePath stringByAppendingPathComponent:[NSString stringWithFormat:@"ModLoaderIcons/%@_%@.png", imageName, theme]];
    
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    if (!image) {
        // Fallback to opposite theme if preferred theme doesn't exist
        theme = isDarkMode ? @"light" : @"dark";
        imagePath = [resourcePath stringByAppendingPathComponent:[NSString stringWithFormat:@"ModLoaderIcons/%@_%@.png", imageName, theme]];
        image = [UIImage imageWithContentsOfFile:imagePath];
    }
    
    return image;
}

#pragma mark - UIAppearance & Trait Collection

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    // Reload loader icons when interface style changes
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        // Simply reload the current cell configuration to update icons
        if (self.currentMod) {
            [self configureForLocalMode:self.currentMod];
        }
    }
}

#pragma mark - Auto Layout Constraints

- (void)setupConstraints {
    CGFloat padding = 24.0;
    CGFloat iconSize = 64.0;

    // --- Common Left-aligned Elements ---
    [NSLayoutConstraint activateConstraints:@[
        // Mod Icon
        [_modIconView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:padding],
        [_modIconView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [_modIconView.widthAnchor constraintEqualToConstant:iconSize],
        [_modIconView.heightAnchor constraintEqualToConstant:iconSize],

        // Mod Name
        [_nameLabel.leadingAnchor constraintEqualToAnchor:_modIconView.trailingAnchor constant:24],
        [_nameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:20],
        [_nameLabel.widthAnchor constraintEqualToConstant:200],

        // Mod Version
        [_modVersionLabel.leadingAnchor constraintEqualToAnchor:_nameLabel.trailingAnchor constant:80],
        [_modVersionLabel.centerYAnchor constraintEqualToAnchor:_nameLabel.centerYAnchor],
        [_modVersionLabel.widthAnchor constraintEqualToConstant:150],

        // Game Version
        [_gameVersionLabel.leadingAnchor constraintEqualToAnchor:_modVersionLabel.trailingAnchor constant:80],
        [_gameVersionLabel.centerYAnchor constraintEqualToAnchor:_nameLabel.centerYAnchor],
        [_gameVersionLabel.widthAnchor constraintEqualToConstant:150],

        // Mod Source
        [_authorLabel.leadingAnchor constraintEqualToAnchor:_gameVersionLabel.trailingAnchor constant:80],
        [_authorLabel.centerYAnchor constraintEqualToAnchor:_nameLabel.centerYAnchor],
        [_authorLabel.widthAnchor constraintEqualToConstant:150],

        // Last Updated
        [_statsLabel.leadingAnchor constraintEqualToAnchor:_authorLabel.trailingAnchor constant:80],
        [_statsLabel.centerYAnchor constraintEqualToAnchor:_nameLabel.centerYAnchor],
        [_statsLabel.widthAnchor constraintEqualToConstant:150],

        // Hide other elements not needed in the current layout
        [_loaderIconView.widthAnchor constraintEqualToConstant:0],
        [_loaderIconView.heightAnchor constraintEqualToConstant:0],
        [_descLabel.widthAnchor constraintEqualToConstant:0],
        [_descLabel.heightAnchor constraintEqualToConstant:0],
        [_categoryLabel.widthAnchor constraintEqualToConstant:0],
        [_categoryLabel.heightAnchor constraintEqualToConstant:0],
        [_enableSwitch.widthAnchor constraintEqualToConstant:0],
        [_enableSwitch.heightAnchor constraintEqualToConstant:0],
        [_downloadButton.widthAnchor constraintEqualToConstant:0],
        [_downloadButton.heightAnchor constraintEqualToConstant:0],
        [_openLinkButton.widthAnchor constraintEqualToConstant:0],
        [_openLinkButton.heightAnchor constraintEqualToConstant:0],
        [_loaderBadgesStackView.widthAnchor constraintEqualToConstant:0],
        [_loaderBadgesStackView.heightAnchor constraintEqualToConstant:0],
    ]];
}

#pragma mark - Configuration

- (void)configureWithMod:(ModItem *)mod displayMode:(ModTableViewCellDisplayMode)mode {
    self.currentMod = mod;

    _nameLabel.text = mod.displayName ?: mod.fileName;

    if (mod.icon) {
        _modIconView.image = mod.icon;
    } else if (mod.iconURL) {
        [_modIconView setImageWithURL:[NSURL URLWithString:mod.iconURL] placeholderImage:[UIImage systemImageNamed:@"puzzlepiece.extension"]];
    } else {
        _modIconView.image = [UIImage systemImageNamed:@"puzzlepiece.extension"];
    }

    if (mode == ModTableViewCellDisplayModeLocal) {
        [self configureForLocalMode:mod];
    } else {
        [self configureForOnlineMode:mod];
    }
}

- (void)configureForLocalMode:(ModItem *)mod {
    // 添加自定义背景视图
    [self addCustomBackgroundView];
    
    // Hide online/unused elements
    _authorLabel.hidden = YES;
    _statsLabel.hidden = YES;
    _categoryLabel.hidden = YES;
    _downloadButton.hidden = YES;
    _descLabel.hidden = YES;

    // Show local elements
    _openLinkButton.hidden = YES;
    _enableSwitch.hidden = YES;
    _loaderBadgesStackView.hidden = YES;
    _modVersionLabel.hidden = NO;
    _gameVersionLabel.hidden = NO;
    _loaderIconView.hidden = YES;

    // Populate version labels
    if (mod.version && mod.version.length > 0) {
        _modVersionLabel.text = [NSString stringWithFormat:@"%@", mod.version];
        _modVersionLabel.hidden = NO;
    } else {
        _modVersionLabel.text = nil;
        _modVersionLabel.hidden = YES;
    }

    if (mod.gameVersion && mod.gameVersion.length > 0) {
        _gameVersionLabel.text = [NSString stringWithFormat:@"%@", mod.gameVersion];
        _gameVersionLabel.hidden = NO;
    } else {
        _gameVersionLabel.text = nil;
        _gameVersionLabel.hidden = YES;
    }

    // Clear previous badges
    for (UIView *view in self.loaderBadgesStackView.arrangedSubviews) {
        [self.loaderBadgesStackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }

    // Add new badges
    if (mod.isFabric) [self.loaderBadgesStackView addArrangedSubview:[self createBadgeImageView:@"fabric"]];
    if (mod.isForge) [self.loaderBadgesStackView addArrangedSubview:[self createBadgeImageView:@"forge"]];
    if (mod.isNeoForge) [self.loaderBadgesStackView addArrangedSubview:[self createBadgeImageView:@"neoforge"]];

    [self updateToggleState:mod.disabled];

    if (mod.modDescription && mod.modDescription.length > 0) {
        _descLabel.text = mod.modDescription;
        _descLabel.hidden = YES;
    } else {
        _descLabel.text = nil;
        _descLabel.hidden = YES;
    }
}

- (void)addCustomBackgroundView {
    // 移除旧的背景视图
    for (UIView *subview in self.contentView.subviews) {
        if ([subview tag] == 999) {
            [subview removeFromSuperview];
        }
    }
    
    // 创建新的背景视图
    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    backgroundView.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.8f];
    backgroundView.layer.borderWidth = 1.0f;
    backgroundView.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.1f].CGColor;
    backgroundView.layer.cornerRadius = 16.0f;
    backgroundView.tag = 999;
    
    // 将背景视图插入到最底层
    [self.contentView insertSubview:backgroundView atIndex:0];
    
    // 设置约束
    [NSLayoutConstraint activateConstraints:@[
        [backgroundView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:0],
        [backgroundView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:0],
        [backgroundView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:0],
        [backgroundView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:0]
    ]];
}

- (void)configureForOnlineMode:(ModItem *)mod {
    // Hide local/unused elements
    _enableSwitch.hidden = YES;
    _loaderBadgesStackView.hidden = YES;
    _descLabel.hidden = YES;
    _modVersionLabel.hidden = YES;
    _gameVersionLabel.hidden = YES;

    // Ensure loader icon is not shown on download (online) list
    _loaderIconView.image = nil;
    _loaderIconView.hidden = YES;

    // Show online elements
    _authorLabel.hidden = NO;
    _statsLabel.hidden = NO;
    _downloadButton.hidden = NO;
    _openLinkButton.hidden = NO;

    _authorLabel.text = [NSString stringWithFormat:@"by %@", mod.author ?: @"Unknown"];

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSString *downloadsStr = [formatter stringFromNumber:mod.downloads ?: @0];

    _statsLabel.text = [NSString stringWithFormat:@"%@ downloads", downloadsStr];
}


#pragma mark - State Updates

- (void)updateToggleState:(BOOL)disabled {
    [_enableSwitch setOn:!disabled animated:YES];
    self.contentView.alpha = disabled ? 0.6 : 1.0;
}

#pragma mark - Actions

- (void)toggleTapped {
    if ([self.delegate respondsToSelector:@selector(modCellDidTapToggle:)]) {
        [self.delegate modCellDidTapToggle:self];
    }
}

- (void)downloadTapped {
    if ([self.delegate respondsToSelector:@selector(modCellDidTapDownload:)]) {
        [self.delegate modCellDidTapDownload:self];
    }
}

- (void)openLinkTapped {
    if ([self.delegate respondsToSelector:@selector(modCellDidTapOpenLink:)]) {
        [self.delegate modCellDidTapOpenLink:self];
    }
}

@end
#pragma clang diagnostic pop
