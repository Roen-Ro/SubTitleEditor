//
//  MainViewController.m
//  SubTitleEditor
//
//  Created by lolaage on 2016/12/26.
//  Copyright © 2016年 Roen. All rights reserved.
//

#import "MainViewController.h"
#import "SubTitleProcess.h"

@interface MainViewController ()

@property (weak) IBOutlet NSButton *revertCheckBox;

@property (unsafe_unretained) IBOutlet NSTextView *srtTextView;
@property (unsafe_unretained) IBOutlet NSTextView *lrcTextView;


@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

}

-(void)alertWithMessage:(NSString *)msg
{
   // NSAlert *alert
}


-(void)openFileAtPath:(NSString *)path
{
    _lrcDestinationPathField.stringValue = @"";
    _srtSourcePathField.stringValue = path;
    [self loadSrt:nil];
}

- (IBAction)loadSrt:(id)sender
{
    NSString *path = _srtSourcePathField.stringValue;
    if(path.length < 4)
    {
        [self OpenFileDialog];
    }
    else
    {
        NSString *s = [SubTitleProcess readStringFromFile:path];
        if(s)
        {
            _srtTextView.string = s;
        }
        else
        {
            [self alertWithMessage:@"读取失败"];
        }
    }
    
}



- (IBAction)doConvertion:(id)sender
{
    NSLog(@"revert %d",_revertCheckBox.state==NSOnState);
    NSString *lrcStr = [SubTitleProcess convertSrtString2LrcString:_srtTextView.string revertLineOrder:_revertCheckBox.state==NSOnState];
    _lrcTextView.string = lrcStr;
    
}

-(IBAction)saveLrcToDestPath:(id)sender
{
    NSString *path = _lrcDestinationPathField.stringValue;
    
    if(path.length < 3)
    {
        [self openSavePannel];
    }
    
}

-(void)saveLrcToPath:(NSString *)path
{
    _lrcDestinationPathField.stringValue = path;
    NSString *str =  _lrcTextView.string;
    
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error;
    
    [data writeToFile:path options:NSDataWritingAtomic error:&error];
    
    if(error)
        [self alertWithMessage:error.localizedDescription];
}

- (IBAction)showFileInFinder:(id)sender
{
    NSString *path = _lrcDestinationPathField.stringValue;
    if(path.length > 3)
    {
        NSURL *url = [NSURL fileURLWithPath:path];
        if(url)
            [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[url]];
    }
}

-(void)openSavePannel
{
    NSSavePanel *savePl = [NSSavePanel savePanel];
    savePl.allowedFileTypes =  @[@"lrc",@"txt"];
    savePl.nameFieldStringValue = @"XXOO";
    if([savePl runModal] == NSFileHandlingPanelOKButton)
    {
        [self saveLrcToPath:savePl.URL.path];
    }
}

-(void)OpenFileDialog
{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    openDlg.allowedFileTypes = @[@"srt",@"txt"];
    [openDlg setCanChooseFiles:YES];

    [openDlg setCanChooseDirectories:NO];
    
    if([openDlg runModal] == NSFileHandlingPanelOKButton)
    {
        NSURL *url = [openDlg URLs].firstObject;
        NSString *path = url.path;
        [self openFileAtPath:path];
    }
}


@end
