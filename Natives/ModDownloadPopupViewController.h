#import <UIKit/UIKit.h>

@protocol ModDownloadPopupViewControllerDelegate <NSObject>

- (void)modDownloadPopupViewControllerDidConfirmDownload:(NSArray *)selectedMods;
- (void)modDownloadPopupViewControllerDidCancel;

@end

@interface ModDownloadPopupViewController : UIViewController

@property (nonatomic, weak) id<ModDownloadPopupViewControllerDelegate> delegate;
@property (nonatomic, strong) NSArray *mods;

@end
