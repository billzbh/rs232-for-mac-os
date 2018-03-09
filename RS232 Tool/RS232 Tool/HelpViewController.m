//
//  HelpViewController.m
//  RS232 Tool
//
//  Created by zhang biaohe on 2018/3/9.
//  Copyright © 2018年 zbh. All rights reserved.
//

#import "HelpViewController.h"

@interface HelpViewController ()

@end

@implementation HelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)closeMySheetWindow:(NSButton *)sender {
    [self.view.window.sheetParent endSheet:self.view.window returnCode:NSModalResponseContinue];
}


@end
