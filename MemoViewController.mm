#import "MemoViewController.h"
#import <Vision/Vision.h>

@interface MemoViewController ()
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) PKCanvasView *canvasView;
@property (nonatomic, strong) PKToolPicker *toolPicker;
@property (nonatomic, assign) BOOL isDrawingMode;
@end

@implementation MemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = self.filename ?: @"新備忘錄";
    self.isDrawingMode = YES;

    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    self.textView.font = [UIFont systemFontOfSize:18];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.textView.backgroundColor = [UIColor systemBackgroundColor];
    // 避免被導航欄遮擋
    self.textView.textContainerInset = UIEdgeInsetsMake(20, 10, 100, 10);
    [self.view addSubview:self.textView];

    // 2. 設置手寫畫布
    self.canvasView = [[PKCanvasView alloc] initWithFrame:self.view.bounds];
    self.canvasView.delegate = self;
    self.canvasView.drawingPolicy = PKCanvasViewDrawingPolicyAnyInput;
    self.canvasView.backgroundColor = [UIColor clearColor];
    self.canvasView.opaque = NO;
    self.canvasView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.canvasView];

    // 3. 設置工具選擇器
    self.toolPicker = [[PKToolPicker alloc] init];
    [self.toolPicker setVisible:YES forFirstResponder:self.canvasView];
    [self.toolPicker addObserver:self.canvasView];
    [self.toolPicker addObserver:self];
    
    // 4. 加載數據
    if (self.filename) {
        [self loadDrawing];
        [self loadText];
    }

    [self setupNavigationItems];
    
    [self updateInputMode];
}

- (void)setupNavigationItems {
    UIBarButtonItem *saveBtn = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(saveAllData)];
    
    UIBarButtonItem *ocrBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"text.viewfinder"] style:UIBarButtonItemStylePlain target:self action:@selector(performOCR)];

    UIBarButtonItem *modeBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"keyboard"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleMode)];
    self.navigationItem.rightBarButtonItems = @[saveBtn, ocrBtn, modeBtn];
}

- (void)toggleMode {
    self.isDrawingMode = !self.isDrawingMode;
    [self updateInputMode];
}

- (void)updateInputMode {
    NSArray *items = self.navigationItem.rightBarButtonItems;
    UIBarButtonItem *modeBtn = items.lastObject; // 假設它是最後一個

    if (self.isDrawingMode) {

        self.canvasView.userInteractionEnabled = YES;
        [self.canvasView becomeFirstResponder];
        [self.textView resignFirstResponder];
        [modeBtn setImage:[UIImage systemImageNamed:@"keyboard"]];
        self.title = @"手寫模式";
    } else {

        self.canvasView.userInteractionEnabled = NO;
        [self.textView becomeFirstResponder];
        [modeBtn setImage:[UIImage systemImageNamed:@"pencil.tip"]];
        self.title = @"文本模式";
    }
}

- (NSURL *)documentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)fileURLForExtension:(NSString *)ext {
    // 如果是新文件還沒命名，先暫存為 Untitled
    NSString *name = self.filename ?: @"Untitled";
    return [[self documentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", name, ext]];
}

// MARK: - 加載與保存
- (void)loadDrawing {
    NSData *data = [NSData dataWithContentsOfURL:[self fileURLForExtension:@"data"]];
    if (data) {
        NSError *error;
        PKDrawing *drawing = [[PKDrawing alloc] initWithData:data error:&error];
        if (drawing) self.canvasView.drawing = drawing;
    }
}

- (void)loadText {
    // 讀取 .txt 文件內容到 textView
    NSError *error;
    NSString *content = [NSString stringWithContentsOfURL:[self fileURLForExtension:@"txt"] encoding:NSUTF8StringEncoding error:&error];
    if (content) {
        self.textView.text = content;
    }
}

- (void)saveAllData {

    if (!self.filename) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"保存備忘錄" message:@"請輸入文件名" preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:nil];
        [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *name = alert.textFields.firstObject.text;
            if (name.length > 0) {
                self.filename = name;
                [self executeSave];
            }
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [self executeSave];
    }
}

- (void)executeSave {
    // 1. 保存筆跡為 .data
    NSData *drawingData = [self.canvasView.drawing dataRepresentation];
    [drawingData writeToURL:[self fileURLForExtension:@"data"] atomically:YES];
    
    // 2. 保存文本為 .txt
    NSString *textContent = self.textView.text ?: @"";
    [textContent writeToURL:[self fileURLForExtension:@"txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // 提示成功
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"成功" message:@"筆跡與文字已保存" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

// MARK: - OCR 識別
- (void)performOCR {
    // 截圖畫布內容
    UIImage *image = [self.canvasView.drawing imageFromRect:self.canvasView.drawing.bounds scale:1.0];
    
    VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        NSMutableString *recognizedText = [NSMutableString string];
        for (VNRecognizedTextObservation *observation in request.results) {
            VNRecognizedText *candidate = [observation topCandidates:1].firstObject;
            if (candidate) [recognizedText appendFormat:@"%@\n", candidate.string];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (recognizedText.length > 0) {
                // 將識別結果追加到文本框
                self.textView.text = [NSString stringWithFormat:@"%@\n\n--- 識別內容 ---\n%@", self.textView.text, recognizedText];

                if (self.isDrawingMode) [self toggleMode];
                
                NSRange range = NSMakeRange(self.textView.text.length - 1, 1);
                [self.textView scrollRangeToVisible:range];
            } else {
                // 提示沒識別到
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"未識別到文字" message:@"請寫得清楚一點" preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        });
    }];
    
    request.recognitionLanguages = @[@"zh-Hant", @"en-US"];
    request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
    
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:image.CGImage options:@{}];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [handler performRequests:@[request] error:nil];
    });
}

@end
