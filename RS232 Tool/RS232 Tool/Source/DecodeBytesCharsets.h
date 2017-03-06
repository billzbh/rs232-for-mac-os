//
//  DecodeBytesCharsets.h
//  RS232 Tool
//
//  Created by zbh on 17/3/6.
//  Copyright © 2017年 zbh. All rights reserved.
//
#include <stdio.h>
#include <string.h>

#define CODE_ANSI           1
#define CODE_UNICODE        2
#define CODE_UTF8           3
#define CODE_GB18030        4
#define CODE_UNICODEB       5
#define CODE_UNICODE4       6
#define CODE_UNICODE4B      7
#define CODE_BIG5           8

#define CODE_ANSIASCII      1
#define CODE_ANSIGB2312     2
#define CODE_ANSIGBK        3

#define FILE_TYPE_ANSI      CODE_ANSI
#define FILE_TYPE_UNICODE   CODE_UNICODE
#define FILE_TYPE_UTF8      CODE_UTF8
#define FILE_TYPE_GB18030   CODE_GB18030
#define FILE_TYPE_UNICODEB  CODE_UNICODEB
#define FILE_TYPE_UNICODE4  CODE_UNICODE4
#define FILE_TYPE_UNICODE4B CODE_UNICODE4B
#define FILE_TYPE_BIG5      CODE_BIG5
#define CHARBetween(CH_,Low_,Hi_)  (((CH_)>=(Low_)) && ((CH_)<=(Hi_)))
#define CHARBetween(CH_,Low_,Hi_)  (((CH_)>=(Low_)) && ((CH_)<=(Hi_)))


int    TL_IsATwiceBig5Code(unsigned char* pBuf); //头2字节是否属于big5码区
int    TL_IsATwiceGB2312Code(unsigned char* pBuf);//头2字节是否属于GB码区
int    TL_IsATwiceGBKCode(unsigned char* pBuf);//头2字节是否属于GBK码区
int     TL_IsStreamCodeLikeUTF8(unsigned char* pBuf,int Len);//是否utf8，返回0为否，否则返回可能性（75-100）
int    TL_DetechStreamCode(unsigned char* pBuf,int Len,int* CodeOut,int* ProbalyOut,int* ANSIDetailCode);//字节流的编码检测
