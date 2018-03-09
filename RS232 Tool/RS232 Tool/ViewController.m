//
//  ViewController.m
//  RS232 Tool
//
//  Created by zbh on 17/3/3.
//  Copyright © 2017年 zbh. All rights reserved.
//

#import "ViewController.h"
#import "ORSSerialPortManager.h"

@class AMPathPopUpButton;
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
        
        _panel = [NSSavePanel savePanel];
        [_panel setMessage:@"选择存储路径"];
        [_panel setAllowsOtherFileTypes:YES];
        [_panel setAllowedFileTypes:@[@"txt"]];
        [_panel setExtensionHidden:YES];
        [_panel setCanCreateDirectories:YES];
        self.isLoopSend = NO;
        self.isWorkInSend = NO;
        
        self.MyMoneyWindow =((NSWindowController *)[[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"HelpWindow And Read Me"]).window;
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
    self.isRXGBKString = NO;
    self.isTXGBKString = NO;
    self.TXNumber = 0;
    self.RXNumber = 0;
    // Do any additional setup after loading the view.
    self.TXDataDisplayTextView.delegate = self;
    self.tableviewFordevices.delegate = self;
}

-(void)viewDidAppear{
    [super viewDidAppear];
    
    if(self.serialPortManager.availablePorts.count>0){
        self.serialPort=self.serialPortManager.availablePorts[0];
    }
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

- (IBAction)helpButtonAction:(NSButton *)sender {
    [self.view.window beginSheet:self.MyMoneyWindow completionHandler:^(NSModalResponse returnCode) {
    }];
}


//设置循环发送数据
- (IBAction)setSendLoop:(NSButton *)sender {
    if(sender.intValue==1){
        [self.countOfSend setEnabled:YES];
        [self.TimeInternel setEnabled:YES];
        self.isLoopSend = YES;
    }else{
        [self.countOfSend setEnabled:NO];
        [self.TimeInternel setEnabled:NO];
        self.isLoopSend = NO;
    }
    [self stopTimer];
}


- (IBAction)openComPort:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.serialPort.isOpen ? [self.serialPort close] : [self.serialPort open];
    });
}

//设置接收区采用hexstring还是字符串显示方式
- (IBAction)setDisplayMode:(NSMatrix *)sender {
    if (sender.selectedTag==1) {
        self.isRXHexString = YES;
        [self.stringType setEnabled:NO];
    }else if(sender.selectedTag==2){
        self.isRXHexString = NO;
        [self.stringType setEnabled:YES];
    }
}

//设置发送区采用hexstring还是字符串发送
- (IBAction)setDisplayMode_TX:(NSMatrix *)sender {
    
    if (sender.selectedTag==1) {
        self.isTXHexString = YES;
        [self.stringType_TX setEnabled:NO];
    }else{
        self.isTXHexString = NO;
        [self.stringType_TX setEnabled:YES];
    }
}

//设置接收区字符串编码方式
- (IBAction)setStringDisplayEncode:(NSMatrix *)sender {
    if (sender.selectedTag==1) {
        self.isRXGBKString = NO;
        [self.RXDataDisplayTextView.textStorage.mutableString appendString:@"接收区格式变更为--> ASCII\n"];
    }else{
        self.isRXGBKString = YES;
       [self.RXDataDisplayTextView.textStorage.mutableString appendString:@"接收区格式变更为--> GBK\n"];
    }
}

//设置发送区字符串编码方式
- (IBAction)setStringDisplayEncode_TX:(NSMatrix *)sender {
    if (sender.selectedTag==1) {
        _isTXGBKString = NO;
    }else{
        _isTXGBKString = YES;
    }
}


//发送数据
- (IBAction)sendData:(NSButton *)sender {
    
    //停止循环发送
    if (self.isWorkInSend) {
        [self stopTimer];
        return;
    }
    
    self.StatusText.stringValue = @"发送数据中...";
    NSString *textStr = self.TXDataDisplayTextView.textStorage.mutableString;
    if(textStr.length==0){
        self.StatusText.stringValue = @"发送数据长度为0";
        return;
    }
    
    if (_isLoopSend) {
        //获取次数和间隔值
        _sendCount = [self.countOfSend.stringValue intValue];
        double timeout = [self.TimeInternel.stringValue doubleValue]/1000.0;
        
        if(_sendCount<=0 || timeout <= 0){
            self.StatusText.stringValue = @"请填入循环发送参数(时间间隔和次数)";
            return;
        }
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(timeout) userInfo:nil repeats:YES];
        self.StatusText.stringValue = @"循环发送中...";
        self.SendButton.title = @"停止循环发送";
        _isWorkInSend = YES;
        
    }else{
        [self sendDataWithPort];
    }
}

-(void)stopTimer{
    [_timer invalidate];
    _timer = nil;
    if (_isLoopSend) {
        self.SendButton.title = @"循环发送";
    }else{
        self.SendButton.title = @"手动发送";
    }
    self.isWorkInSend = NO;
}

-(void)timeout{
    if (0 ==_sendCount) {
        [self stopTimer];
        return;
    }
    [self sendDataWithPort];
    _sendCount --;
}

-(void)sendDataWithPort{
    NSData *sendData;
    NSString *textStr = self.TXDataDisplayTextView.textStorage.mutableString;
    if (self.isTXHexString) {
        textStr = [textStr stringByReplacingOccurrencesOfString:@"," withString:@""];
        textStr = [textStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        textStr = [textStr stringByReplacingOccurrencesOfString:@"0x" withString:@""];
        textStr = [textStr stringByReplacingOccurrencesOfString:@"\\x" withString:@""];
        if (textStr.length%2!=0) {
            self.StatusText.stringValue = @"发送16进制数据长度错误！";
            return;
        }
        
        NSString* number=@"^[a-f|A-F|0-9]+$";
        NSPredicate *numberPre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",number];
        if(![numberPre evaluateWithObject:textStr]){
            self.StatusText.stringValue = @"包含非[0-9A-Fa-f]字符！";
            return;
        }
        
        
        self.TXNumber += textStr.length/2;
        sendData = [ORSSerialPortManager twoOneData:textStr];
        if([self.serialPort sendData:sendData]){
            self.StatusText.stringValue = @"发送HEX数据成功";
            self.TXCounter.stringValue = [NSString stringWithFormat:@"%ld",self.TXNumber];
        }else{
            self.StatusText.stringValue = @"发送HEX数据失败";
        }
        
        //显示文字为深灰色，大小为14
        NSInteger startPorint = self.RXDataDisplayTextView.textStorage.length;
        NSString *sendStr = [NSString stringWithFormat:@"%@ 发送 > %@\n",[self get2DateTime],[ORSSerialPortManager oneTwoData:sendData]];
        NSInteger length = sendStr.length;
        [self.RXDataDisplayTextView.textStorage.mutableString appendString:sendStr];
        [self.RXDataDisplayTextView.textStorage addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Andale Mono" size:14] range:NSMakeRange(startPorint, length)];
        [self.RXDataDisplayTextView.textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor darkGrayColor] range:NSMakeRange(startPorint, length)];
        
        [self.RXDataDisplayTextView scrollRangeToVisible:NSMakeRange(self.RXDataDisplayTextView.string.length, 1)];
        return;
    }else{
        
        const char* cstr;
        NSString *tmp;
        if (_isTXGBKString) {
            NSStringEncoding enc =CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
            cstr = [textStr cStringUsingEncoding:enc];
            tmp = @"发送GBK编码数据成功";
        }else{
            cstr = [textStr cStringUsingEncoding:NSUTF8StringEncoding];
            tmp = @"发送UTF8编码数据成功";
        }
        if(cstr!=NULL){
            self.TXNumber += strlen(cstr);
            sendData = [NSData dataWithBytes:cstr length:strlen(cstr)];
            if([self.serialPort sendData:sendData]){
                self.TXCounter.stringValue = [NSString stringWithFormat:@"%ld",self.TXNumber];
                self.StatusText.stringValue = tmp;
            }else{
                self.StatusText.stringValue = @"发送数据失败";
                return;
            }
        }else{
            self.StatusText.stringValue=@"字符串按选定编码转为字节流失败";
            return;
        }
        
        //显示文字为深灰色，大小为14
        NSInteger startPorint = self.RXDataDisplayTextView.textStorage.length;
        NSString *sendStr = [NSString stringWithFormat:@"%@ 发送 > %@\n(HEX)->%@\n",[self get2DateTime],textStr,[ORSSerialPortManager oneTwoData:sendData]];
        NSInteger length = sendStr.length;
        [self.RXDataDisplayTextView.textStorage.mutableString appendString:sendStr];
        [self.RXDataDisplayTextView.textStorage addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Andale Mono" size:14] range:NSMakeRange(startPorint, length)];
        [self.RXDataDisplayTextView.textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor darkGrayColor] range:NSMakeRange(startPorint, length)];
        
        [self.RXDataDisplayTextView scrollRangeToVisible:NSMakeRange(self.RXDataDisplayTextView.string.length, 1)];
        return;
    }
}

- (IBAction)clearTXDataDisplayTextView:(id)sender {
    self.StatusText.stringValue = @"已清空发送区";
    [self.TXDataDisplayTextView setString:@""];
}

- (IBAction)clearRXDataDisplayTextView:(id)sender {
    self.StatusText.stringValue = @"已清空接收区";
    [self.RXDataDisplayTextView setString:@""];
}

- (IBAction)clearCounter:(id)sender {
    
    self.RXNumber = 0;
    self.TXNumber = 0;
    self.TXCounter.stringValue=@"";
    self.RXCounter.stringValue = @"";
    
}


-(void)textDidChange:(NSNotification *)notification {
    
    [self.TXDataDisplayTextView.textStorage addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Andale Mono" size:18] range:NSMakeRange(0, [self.TXDataDisplayTextView string].length)];
    [self.TXDataDisplayTextView.textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, [self.TXDataDisplayTextView string].length)];
    [self.TXDataDisplayTextView.textStorage addAttribute:NSBackgroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, [self.TXDataDisplayTextView string].length)];
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
    if(serialPort!=self.serialPort){//不是同一个对象，直接返回
        return;
    }
    NSLog(@"收到数据: %@",data);
    self.StatusText.stringValue = @"收到一次数据...";
    self.RXNumber += data.length;
    self.RXCounter.stringValue = [NSString stringWithFormat:@"%ld",self.RXNumber];
    
    NSString *string;
    if (self.isRXHexString) {
        string = [ORSSerialPortManager oneTwoData:data];
    }else{
        
        if(self.isRXGBKString){
            NSStringEncoding enc =CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
//            string = [NSString stringWithCString:(const char*)[data bytes] encoding:enc];
            string = [[NSString alloc] initWithData:data encoding:enc];
        }else{
            string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    if ([string length] == 0){
        return;
    }
    
    int prelen = (int)string.length;
    string = [NSString stringWithFormat:@"%@ 接收 > %@\n",[self get2DateTime],string];
    prelen = (int)string.length-prelen-1;
    
    //显示文字为深灰色，大小为14
    NSInteger startPorint = self.RXDataDisplayTextView.textStorage.length;
    NSInteger length = string.length;
    [self.RXDataDisplayTextView.textStorage.mutableString appendString:string];
    [self.RXDataDisplayTextView.textStorage addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Andale Mono" size:14] range:NSMakeRange(startPorint, length)];
    
    //前面提示语句设为红色
    [self.RXDataDisplayTextView.textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:NSMakeRange(startPorint, prelen)];
    
    static int i = 0;
    if(i%2==0){
        [self.RXDataDisplayTextView.textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor greenColor] range:NSMakeRange(startPorint+prelen, length-prelen-1)];
        [self.RXDataDisplayTextView.textStorage addAttribute:NSBackgroundColorAttributeName value:[NSColor brownColor] range:NSMakeRange(startPorint+prelen, length-prelen-1)];
    }else{
        [self.RXDataDisplayTextView.textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor yellowColor] range:NSMakeRange(startPorint+prelen, length-prelen-1)];
        [self.RXDataDisplayTextView.textStorage addAttribute:NSBackgroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(startPorint+prelen, length-prelen-1)];
    }
    [self.RXDataDisplayTextView scrollRangeToVisible:NSMakeRange(self.RXDataDisplayTextView.string.length, 1)];
    i++;
    
    [self.RXDataDisplayTextView setNeedsDisplay:YES];
    self.StatusText.stringValue = @"数据接收完毕";
}

- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort;
{
    // After a serial port is removed from the system, it is invalid and we must discard any references to it
    self.serialPort = nil;
    self.OpenOrClose.title = @"打开串口";
}

//各种错误，比如打开，关闭，发送数据等发生错误
- (void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error
{
    NSLog(@"Serial port %@ encountered an error: %@", serialPort, error);
    self.StatusText.stringValue = [NSString stringWithFormat:@"错误:%@",error.userInfo[@"NSLocalizedDescription"]];
    
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
        userNote.title = NSLocalizedString(@"侦测到串口线连接", @"侦测到串口线连接");
        NSString *informativeTextFormat = NSLocalizedString(@"串口设备 %@ 已经连接到你的 Mac电脑.", @"Serial port connected user notification informative text");
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
        userNote.title = NSLocalizedString(@"侦测到串口线断开", @"侦测到串口线断开");
        NSString *informativeTextFormat = NSLocalizedString(@"串口设备 %@ 已从你的 Mac电脑断开物理连接.", @"Serial port disconnected user notification informative text");
        userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
        userNote.soundName = nil;
        [unc deliverNotification:userNote];
    }
#endif
}

-(void)tableViewSelectionDidChange:(NSNotification*)notification{
    self.serialPort = [self getCurrentORSSerialPort];
    self.serialPort.delegate = self;
    self.serialPort.allowsNonStandardBaudRates = YES;//允许非标准的波特率
}

-(ORSSerialPort *)getCurrentORSSerialPort {
    if([[self.DeviceArray selectedObjects] count]> 0){
        return [[self.DeviceArray selectedObjects] objectAtIndex:0];
    } else {
        return nil;
    }
}


#pragma mark - Properties

- (void)setSerialPort:(ORSSerialPort *)port
{
    if (port != _serialPort)
    {
//        [_serialPort close];
        _serialPort.delegate = nil;
        _serialPort = port;
        _serialPort.delegate = self;
        self.OpenOrClose.title = self.serialPort.isOpen ? @"关闭串口" : @"打开串口";
        NSString *tmp=[NSString stringWithFormat:@"%@%@",_serialPort.name,(self.serialPort.isOpen ? @"串口已打开" : @"串口已关闭")];
        self.StatusText.stringValue = tmp;
    }
}


// 保存日志文件
- (IBAction)SaveLog:(id)sender {
    
    [_panel setNameFieldStringValue:[NSString stringWithFormat:@"%@-%@.txt",_serialPort.name,[self getDateTime]]];
    
    [_panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            NSString *path = [[_panel URL] path];
    
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.RXDataDisplayTextView.textStorage.mutableString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
            });
        }
    }];
}

- (NSString *)getDateTime
{
    char dateTime[15];
    time_t t;
    struct tm tm;
    t = time( NULL );
    memcpy(&tm, localtime(&t), sizeof(struct tm));
    sprintf(dateTime, "%04d%02d%02d%02d%02d%02d",
            tm.tm_year+1900, tm.tm_mon+1, tm.tm_mday,
            tm.tm_hour, tm.tm_min,tm.tm_sec);
    return [[NSString alloc] initWithCString:dateTime encoding:NSASCIIStringEncoding];
}

- (NSString *)get2DateTime
{
    char dateTime[15];
    time_t t;
    struct tm tm;
    t = time( NULL );
    memcpy(&tm, localtime(&t), sizeof(struct tm));
    sprintf(dateTime, "%02d:%02d:%02d",
            tm.tm_hour, tm.tm_min,tm.tm_sec);
    return [[NSString alloc] initWithCString:dateTime encoding:NSASCIIStringEncoding];
}
@end
