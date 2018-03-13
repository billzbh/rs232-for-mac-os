//
//  AppDelegate.m
//  RS232 Tool
//
//  Created by zbh on 17/3/3.
//  Copyright © 2017年 zbh. All rights reserved.
//

#import "AppDelegate.h"
#import "NSMyWindowController.h"
#import "MainWindow.h"
#import "ViewController.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

+(AppDelegate *)shareAppdelegate{
    AppDelegate *appDelegate=(AppDelegate *)[[NSApplication sharedApplication] delegate];
    return appDelegate;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
//    _WindowControllers = [NSMutableArray arrayWithCapacity:5];
    NSMyWindowController* mainController = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"MyWindowControllerZBH"];
//    [_WindowControllers addObject:mainController];
    _windowController = mainController;
    [mainController.window orderFront:nil];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    
}


//是否最后一个窗口关闭时退出程序
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
    return YES;
}




-(IBAction)NewTabForComShell:(id)sender{
    
    NSMyWindowController * myMainWindowController = (NSMyWindowController *)[[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"MyWindowControllerZBH"];
//    [_WindowControllers addObject:myMainWindowController];
    
    [_windowController.myWindow addTabbedWindow:myMainWindowController.window ordered:NSWindowAbove];
    [_windowController.myWindow selectNextTab:sender];
}


@end
