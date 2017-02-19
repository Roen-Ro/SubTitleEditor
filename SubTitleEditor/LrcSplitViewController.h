//
//  LrcSplitViewController.h
//  SubTitleEditor
//
//  Created by 罗 亮富 on 16/12/31.
//  Copyright © 2016年 Roen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LrcSplitViewController : NSViewController

-(void)openSavePannel;
-(void)OpenFileDialog;

-(IBAction)saveLrcToDestPath:(id)sender;


@end
