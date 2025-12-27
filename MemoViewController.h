#import <UIKit/UIKit.h>
#import <PencilKit/PencilKit.h>

@interface MemoViewController : UIViewController <PKCanvasViewDelegate, PKToolPickerObserver>

@property (nonatomic, strong) NSString *filename;
@property (nonatomic, assign) BOOL isNewMemo;

@end
