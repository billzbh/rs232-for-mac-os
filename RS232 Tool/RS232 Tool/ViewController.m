//
//  ViewController.m
//  RS232 Tool
//
//  Created by zbh on 17/3/3.
//  Copyright © 2017年 zbh. All rights reserved.
//

#import "ViewController.h"
#import "ORSSerialPortManager.h"

@implementation ViewController


- (void)awakeFromNib{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
        self.availableBaudRates = @[@300, @1200, @2400, @4800, @9600, @14400, @19200, @28800, @38400, @57600, @115200, @230400];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(serialPortsWereConnected:) name:ORSSerialPortsWereConnectedNotification object:nil];
        [nc addObserver:self selector:@selector(serialPortsWereDisconnected:) name:ORSSerialPortsWereDisconnectedNotification object:nil];
        
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
#endif
    });
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    [self.RXDataDisplayTextView setEditable:NO];
    [self.RXCounter setEditable:NO];
    [self.TXCounter setEditable:NO];
    self.isRXHexString = YES;
    self.isTXHexString = YES;
    self.TXNumber = 0;
    self.RXNumber = 0;
    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

- (IBAction)openComPort:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.serialPort.isOpen ? [self.serialPort close] : [self.serialPort open];
    });
}

- (IBAction)setDisplayMode:(NSMatrix *)sender {
    if (sender.selectedTag==1) {
        self.isRXHexString = YES;
    }else if(sender.selectedTag==2){
        self.isRXHexString = NO;
    }
}

- (IBAction)setDisplayMode_TX:(NSMatrix *)sender {
    
    if (sender.selectedTag==1) {
        self.isTXHexString = YES;
    }else{
        self.isTXHexString = NO;
    }
}

- (IBAction)sendData:(id)sender {
    
    NSString *textStr = self.TXDataDisplayTextView.textStorage.mutableString;
    if(textStr.length==0)
        return;
    
    if (self.isTXHexString) {
        
        textStr = [textStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        textStr = [textStr stringByReplacingOccurrencesOfString:@"0x" withString:@""];
        textStr = [textStr stringByReplacingOccurrencesOfString:@"\\x" withString:@""];
        if (textStr.length%2!=0) {
            return;
        }
        self.TXNumber += textStr.length/2;
        [self.serialPort sendData:[ORSSerialPortManager twoOneData:textStr]];
    }else{
        const char* cstr = [textStr cStringUsingEncoding:NSASCIIStringEncoding];
        self.TXNumber += textStr.length;
        NSData *sendData = [NSData dataWithBytes:cstr length:textStr.length];
        [self.serialPort sendData:sendData];
    }
    self.TXCounter.stringValue = [NSString stringWithFormat:@"%ld",self.TXNumber];
}

- (IBAction)clearTXDataDisplayTextView:(id)sender {
    [self.TXDataDisplayTextView setString:@""];
}

- (IBAction)clearRXDataDisplayTextView:(id)sender {
    [self.RXDataDisplayTextView setString:@""];
}

- (IBAction)clearCounter:(id)sender {
    
    self.RXNumber = 0;
    self.TXNumber = 0;
    self.TXCounter.stringValue=@"";
    self.RXCounter.stringValue = @"";
}

#pragma mark - ORSSerialPortDelegate Methods

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort
{
    self.OpenOrClose.title = @"关闭串口";
    self.StatusText.stringValue = @"串口已打开";
}

- (void)serialPortWasClosed:(ORSSerialPort *)serialPort
{
    self.OpenOrClose.title = @"打开串口";
    self.StatusText.stringValue = @"串口已关闭";
}

- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
    NSLog(@"收到数据: %@",data);
    self.RXNumber += data.length;
    self.RXCounter.stringValue = [NSString stringWithFormat:@"%ld",self.RXNumber];
    
    NSString *string;
    if (self.isRXHexString) {
        string = [ORSSerialPortManager oneTwoData:data];
    }else{
        string = [NSString stringWithCString:(const char*)[data bytes] encoding:NSASCIIStringEncoding];
    }
    if ([string length] == 0) return;
    [self.RXDataDisplayTextView.textStorage.mutableString appendString:string];
    [self.RXDataDisplayTextView setNeedsDisplay:YES];
}

- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort;
{
    // After a serial port is removed from the system, it is invalid and we must discard any references to it
    self.serialPort = nil;
    self.OpenOrClose.title = @"打开串口";
}

- (void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error
{
    NSLog(@"Serial port %@ encountered an error: %@", serialPort, error);
}

#pragma mark - NSUserNotificationCenterDelegate

#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [center removeDeliveredNotification:notification];
    });
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

#endif

#pragma mark - Notifications

- (void)serialPortsWereConnected:(NSNotification *)notification
{
    NSArray *connectedPorts = [notification userInfo][ORSConnectedSerialPortsKey];
    NSLog(@"Ports were connected: %@", connectedPorts);
    [self postUserNotificationForConnectedPorts:connectedPorts];
}

- (void)serialPortsWereDisconnected:(NSNotification *)notification
{
    NSArray *disconnectedPorts = [notification userInfo][ORSDisconnectedSerialPortsKey];
    NSLog(@"Ports were disconnected: %@", disconnectedPorts);
    [self postUserNotificationForDisconnectedPorts:disconnectedPorts];
    
}

- (void)postUserNotificationForConnectedPorts:(NSArray *)connectedPorts
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    if (!NSClassFromString(@"NSUserNotificationCenter")) return;
    
    NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (ORSSerialPort *port in connectedPorts)
    {
        NSUserNotification *userNote = [[NSUserNotification alloc] init];
        userNote.title = NSLocalizedString(@"Serial Port Connected", @"Serial Port Connected");
        NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ was connected to your Mac.", @"Serial port connected user notification informative text");
        userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
        userNote.soundName = nil;
        [unc deliverNotification:userNote];
    }
#endif
}

- (void)postUserNotificationForDisconnectedPorts:(NSArray *)disconnectedPorts
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    if (!NSClassFromString(@"NSUserNotificationCenter")) return;
    
    NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (ORSSerialPort *port in disconnectedPorts)
    {
        NSUserNotification *userNote = [[NSUserNotification alloc] init];
        userNote.title = NSLocalizedString(@"Serial Port Disconnected", @"Serial Port Disconnected");
        NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ was disconnected from your Mac.", @"Serial port disconnected user notification informative text");
        userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
        userNote.soundName = nil;
        [unc deliverNotification:userNote];
    }
#endif
}


#pragma mark - Properties

- (void)setSerialPort:(ORSSerialPort *)port
{
    if (port != _serialPort)
    {
        [_serialPort close];
        _serialPort.delegate = nil;
        
        _serialPort = port;
        
        _serialPort.delegate = self;
    }
}

@end
