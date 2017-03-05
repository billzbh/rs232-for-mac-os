//
//  ViewController.h
//  RS232 Tool
//
//  Created by zbh on 17/3/3.
//  Copyright © 2017年 zbh. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ORSSerialPort.h"

@class ORSSerialPortManager;

@interface ViewController : NSViewController <ORSSerialPortDelegate, NSUserNotificationCenterDelegate>
@property (weak) IBOutlet NSButton *OpenOrClose;

@property (weak) IBOutlet NSTextField *StatusText;

@property (weak) IBOutlet NSTextField *RXCounter;
@property (nonatomic, assign) long RXNumber;

@property (weak) IBOutlet NSTextField *TXCounter;
@property (nonatomic, assign) long TXNumber;

@property (unsafe_unretained) IBOutlet NSTextView *RXDataDisplayTextView;

@property (unsafe_unretained) IBOutlet NSTextView *TXDataDisplayTextView;

@property (nonatomic, assign) BOOL isRXHexString;

@property (nonatomic, assign) BOOL isTXHexString;


@property (nonatomic, strong) ORSSerialPortManager *serialPortManager;
@property (nonatomic, strong) ORSSerialPort *serialPort;
@property (nonatomic, strong) NSArray *availableBaudRates;
@end

