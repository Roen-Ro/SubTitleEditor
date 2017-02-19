//
//  MainViewController.h
//  SubTitleEditor
//
//  Created by lolaage on 2016/12/26.
//  Copyright © 2016年 Roen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MainViewController : NSViewController<NSTextViewDelegate>

@property (weak) IBOutlet NSTextField *srtSourcePathField;
@property (weak) IBOutlet NSTextField *lrcDestinationPathField;


-(void)openSavePannel;
-(void)OpenFileDialog;

-(IBAction)saveLrcToDestPath:(id)sender;

@end
