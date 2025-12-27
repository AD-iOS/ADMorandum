#import "RootViewController.h"
#import "MemoViewController.h"

@interface RootViewController ()
@property (nonatomic, strong) NSMutableArray<NSString *> *memoFiles;
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"ADMorandum";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createNewMemo)];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadFileList];
}

- (void)reloadFileList {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *docs = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
    NSArray *files = [fm contentsOfDirectoryAtURL:docs includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    
    NSMutableSet *fileSet = [NSMutableSet set];
    for (NSURL *fileURL in files) {
        NSString *ext = fileURL.pathExtension;
        // 只要有 .data (筆跡) 或 .txt (文本) 都算一個備忘錄
        if ([ext isEqualToString:@"data"] || [ext isEqualToString:@"txt"]) {
            [fileSet addObject:[fileURL.URLByDeletingPathExtension lastPathComponent]];
        }
    }
    self.memoFiles = [[fileSet allObjects] mutableCopy];
    [self.memoFiles sortUsingSelector:@selector(localizedStandardCompare:)]; // 排序
    [self.tableView reloadData];
}

- (void)createNewMemo {
    MemoViewController *vc = [[MemoViewController alloc] init];
    // 不預設文件名，讓用戶保存時輸入
    vc.filename = nil; 
    [self.navigationController pushViewController:vc animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.memoFiles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text = self.memoFiles[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MemoViewController *vc = [[MemoViewController alloc] init];
    vc.filename = self.memoFiles[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *filename = self.memoFiles[indexPath.row];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *docs = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
        
        [fm removeItemAtURL:[[docs URLByAppendingPathComponent:filename] URLByAppendingPathExtension:@"data"] error:nil];
        [fm removeItemAtURL:[[docs URLByAppendingPathComponent:filename] URLByAppendingPathExtension:@"txt"] error:nil];
        
        [self.memoFiles removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end