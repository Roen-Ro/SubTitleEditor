//
//  LrcSplitViewController.m
//  SubTitleEditor
//
//  Created by 罗 亮富 on 16/12/31.
//  Copyright © 2016年 Roen. All rights reserved.
//

#import "LrcSplitViewController.h"
#import "SubTitleProcess.h"
#import "NSDate+Utility.h"

@interface LrcSplitViewController ()

@property (weak) IBOutlet NSTableView *tableView;

@property (weak) IBOutlet NSTextField *inputFileLabel;
@property (weak) IBOutlet NSTextField *outputDirectoryLabel;

@property (unsafe_unretained) IBOutlet NSTextView *contentTextView;
@property (weak) IBOutlet NSTextField *startTimeTextField;

@end

@implementation LrcSplitViewController
{
    NSMutableArray *_posArray;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
    _posArray = [NSMutableArray arrayWithCapacity:5];
}


-(void)alertWithMessage:(NSString *)msg
{
    // NSAlert *alert = [NSAlert alloc]INI
}

-(void)openSavePannel
{
    [self openSavePannelWithFinishBlock:nil];
}
-(void)openSavePannelWithFinishBlock:(void (^)(NSString *dirPath))block
{

    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    openDlg.allowedFileTypes = nil;
    [openDlg setCanChooseFiles:NO];
    
    [openDlg setCanChooseDirectories:YES];
    openDlg.prompt = @"select";
    
    if([openDlg runModal] == NSFileHandlingPanelOKButton)
    {
         _outputDirectoryLabel.stringValue = openDlg.directoryURL.path;
        if(block)
            block(openDlg.directoryURL.path);
    }
}

-(void)OpenFileDialog
{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    openDlg.allowedFileTypes = @[@"lrc",@"txt"];
    [openDlg setCanChooseFiles:YES];
    
    [openDlg setCanChooseDirectories:NO];
    
    if([openDlg runModal] == NSFileHandlingPanelOKButton)
    {
        NSURL *url = [openDlg URLs].firstObject;
        _inputFileLabel.stringValue = url.path;
        _outputDirectoryLabel.stringValue = @"";
        [self loadContentAtPath:url.path];
    }
}

-(void)loadContentAtPath:(NSString *)path
{
    NSString *s = [SubTitleProcess readStringFromFile:path];
    if(s)
    {
        _contentTextView.string = s;
    }
    else
    {
        [self alertWithMessage:@"读取失败"];
    }
}

- (IBAction)openLrcAction:(id)sender
{
    [self OpenFileDialog];
}

- (IBAction)selectDestDirectoryAction:(id)sender
{
    [self openSavePannel];
}

- (IBAction)addPieceStartTime:(id)sender
{
    NSString *s = self.startTimeTextField.stringValue;

    NSPredicate *timePredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"\\d{1,5}:\\d{1,2}(\\.\\d+)?"];
    if([timePredicate evaluateWithObject:s])
    {
        NSScanner *scanner = [NSScanner scannerWithString:s];
        NSString *minStr, *secStr;
        [scanner scanUpToString:@":" intoString:&minStr];
        [scanner scanString:@":" intoString:nil];
        [scanner scanUpToString:@"" intoString:&secStr];
        
        NSTimeInterval t = minStr.integerValue*60 + secStr.floatValue;
        [self addPieceStartTimeWithSecond:t];
    }
    else
    {
        [self alertWithMessage:@"分割开始时间格式不正确"];
    }
}

-(void)addPieceStartTimeWithSecond:(NSTimeInterval)sec
{
    NSNumber *num = [NSNumber numberWithDouble:sec];
    
    BOOL conflictTime = NO;
    for(NSNumber *secNum in _posArray)
    {
        if(fabs(secNum.floatValue - sec) < 0.1)
        {
            conflictTime = YES;
            break;
        }
    }
    
    if(conflictTime)
    {
        [self alertWithMessage:@"分割时间已经存在"];
    }
    else
    {
        [_posArray addObject:num];
        [_posArray sortUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2)
        {
            return (obj1.floatValue > obj2.floatValue ? NSOrderedDescending:NSOrderedAscending);
        }];
        
        [self.tableView reloadData];
    }
}

- (IBAction)removeSelectedRow:(id)sender
{
    NSInteger i = [self.tableView selectedRow];
    if(i != NSNotFound)
    {
        
        [self.tableView beginUpdates];
        [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:i] withAnimation:NSTableViewAnimationEffectNone];
        [self.tableView endUpdates];
        
        [_posArray removeObjectAtIndex:i];
    }
}

- (IBAction)doSplit:(id)sender
{
    if(_contentTextView.string.length < 15)
        return;
    
    if(_posArray.count > 0)
    {
        NSArray *splitedSegs = [SubTitleProcess splitLrcFromLrcString:_contentTextView.string wihtSplitTimePos:_posArray];
        
        if(splitedSegs.count > 0)
        {
            NSString *fileName = [_inputFileLabel.stringValue.lastPathComponent stringByDeletingPathExtension];
            if(!fileName)
            {
                NSDate *d = [NSDate date];
                fileName = [NSString stringWithFormat:@"%@分割",[d dateStringWithFormat:TIME_FORMAT_DEFAULT]];
                
            }
            
            NSUInteger i = 0;
            NSString *dirPath = _outputDirectoryLabel.stringValue;
            BOOL dirExist;
            [[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&dirExist];
            if(dirExist)
            {
                for(NSArray *lrcSeg in splitedSegs)
                {
                    NSString *path = [dirPath stringByAppendingFormat:@"/%@%lu.lrc",fileName,(unsigned long)++i];
                    [SubTitleProcess saveLrcLines:lrcSeg toFile:path];
                   
                }
            }
            else
            {
                __weak typeof(self) wSelf = self;
                [self openSavePannelWithFinishBlock:^(NSString *dirPath) {
                    [wSelf doSplit:nil];
                }];
            }
        }
    }
}


//分割lrc中的中文和英文，并在中间加入<br>
- (IBAction)tmpSeparateChineseAndEnglishLetter:(id)sender
{
    NSString *s = _contentTextView.string;
    if(s.length < 20)
        return;
        
    NSArray *lrcs = [SubTitleProcess parseLrcString:s];
    for(LrcLine *line in lrcs)
    {
        NSString *match = @"“?(-?[\\u2E80-\\u9FFF]+,?，?!?！?。?-?：?:?”?(! *)?(\\.* *)? *\\?*)+";
        NSArray* chunks = [SubTitleProcess chunksWithRegularExpressionPattern:match forString:line.content];
     //   NSLog(@"Line-->:%@",line.content);
        
        NSRange r = NSMakeRange(NSNotFound, 0);
        if(chunks.count == 0)
            continue;
    
        NSTextCheckingResult* b1 = [chunks firstObject];
        NSTextCheckingResult* b2 = [chunks lastObject];
        r.location = b1.range.location;
        
        NSUInteger len = b2.range.location + b2.range.length - b1.range.location;
        r.length = len;
        
        @autoreleasepool
        {
            
            if(r.length == line.content.length)
                continue;
            
           // NSLog(@"range(%lu,%lu) total:%lu",r.location,r.length,line.content.length);
            NSString *revertedStr;
            //中文在后面
            if(r.location + r.length == line.content.length
               || (r.location >= line.content.length/2 && r.location > 0))
            {
                revertedStr = [NSString stringWithFormat:@"%@<br>%@",[line.content substringToIndex:r.location],[line.content substringFromIndex:r.location]];
            }
            else//中文在前面
            {
                revertedStr = [NSString stringWithFormat:@"%@<br>%@",[line.content substringFromIndex:r.location + r.length],[line.content substringToIndex:r.location + r.length]];
            }
            
          //  NSString *subStr = [line.content substringWithRange:r];
            line.content = revertedStr;
           // NSLog(@"\n%@\n%@",subStr,revertedStr);

        }
    }
    
    NSString *fileName = [_inputFileLabel.stringValue.lastPathComponent stringByDeletingPathExtension];
    NSString *destPath = [[_inputFileLabel.stringValue stringByDeletingLastPathComponent]stringByAppendingFormat:@"/%@-rer.lrc",fileName];
    [SubTitleProcess saveLrcLines:lrcs toFile:destPath];
}


#pragma mark- table view
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return _posArray.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    id retValue = nil;
    NSNumber *secNum = [_posArray objectAtIndex:row];
    if([tableColumn.identifier isEqualToString:@"timePiece"])
    {
        retValue = [SubTitleProcess lrcTimeTagStringForTime:secNum.doubleValue];
    }
    
    return retValue;
}

@end
