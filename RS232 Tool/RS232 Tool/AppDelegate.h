//
//  AppDelegate.h
//  RS232 Tool
//
//  Created by zbh on 17/3/3.
//  Copyright © 2017年 zbh. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSMyWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate>

@property(strong,nonatomic) NSMyWindowController *windowController;
@property(strong,nonatomic) NSMutableArray <NSMyWindowController *>*WindowControllers;
+(AppDelegate *)shareAppdelegate;

@end

