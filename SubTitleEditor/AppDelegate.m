//
//  AppDelegate.m
//  SubTitleEditor
//
//  Created by lolaage on 2016/12/26.
//  Copyright © 2016年 Roen. All rights reserved.
//

#import "AppDelegate.h"

#ifdef TARGET_LRCSPLITER
#import "LrcSplitViewController.h"
#elif defined TARGET_SUBTITLE_EDITOR
#import "MainViewController.h"
#endif



@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
#ifdef TARGET_LRCSPLITER
@property (nonatomic, strong) LrcSplitViewController *mainViewController;
#elif defined TARGET_SUBTITLE_EDITOR
@property (nonatomic, strong) MainViewController *mainViewController;
#endif
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
#ifdef TARGET_LRCSPLITER
    LrcSplitViewController *vc = [[LrcSplitViewController alloc] initWithNibName:@"LrcSplitViewController" bundle:nil];
#elif defined TARGET_SUBTITLE_EDITOR
    MainViewController *vc = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
#endif
    vc.view.frame = self.window.contentView.bounds;
    
    [self.window.contentView addSubview:vc.view];
    self.mainViewController = vc;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (IBAction)openSubTitleFile:(id)sender
{
    [self.mainViewController OpenFileDialog];
}

- (IBAction)saveSubTitleFile:(id)sender
{
    if([self.mainViewController respondsToSelector:@selector(saveLrcToDestPath:)])
        [self.mainViewController saveLrcToDestPath:nil];
}
- (IBAction)saveSubTitleFileAs:(id)sender
{
    [self.mainViewController openSavePannel];
}



@end
