//
//  DecodeBytesCharsets.m
//  RS232 Tool
//
//  Created by zbh on 17/3/6.
//  Copyright © 2017年 zbh. All rights reserved.
//

#include "DecodeBytesCharsets.h"

int TL_IsStreamCodeLikeUTF8(unsigned char* pBuf,int Len)
{
    int i,AsciiNum=0,ZeroNum=0,LastZero=0,UTFNum=0,UnKnow=0;
    int     UTFRate=0,UnKnowRate=0;
    if (Len<1) return 0;
    for (i=0;i<Len;i++)
    {
        if (pBuf[i]==0)
        {
            ZeroNum++;
            LastZero++;
            continue;
        }
        LastZero=0;
        if (pBuf[i]<=127)
        {
            AsciiNum++;
            continue;
        }
        if (CHARBetween(pBuf[i],0xC0,0xDF) && ((i+1)<Len) && CHARBetween(pBuf[i+1],0x80,0xBF))
        {//两字节UTF8,110xxx,10xx
            UTFNum +=2;
            i+=1;
            continue;
        }
        if (CHARBetween(pBuf[i],0xE0,0xEF) && ((i+2)<Len) && CHARBetween(pBuf[i+1],0x80,0xBF)&& CHARBetween(pBuf[i+2],0x80,0xBF))
        {//三字节UTF8
            UTFNum +=3;
            i+=2;
            continue;
        }
        UnKnow++;
    }
    if (UTFNum == 0) return 0;
    UTFRate = (int)(100*((float)UTFNum /(float)(Len-AsciiNum)));
    UnKnowRate = (int)(100*((float)UnKnow /(float)(Len-AsciiNum)));
    if (UTFRate > 98) return UTFRate; //UTF8字节数的比率超过98
    if ((UTFRate > 95) && (UTFNum>30) && (UnKnowRate<5)) return UTFRate;  //UTF8字节数的比率超过95 且个数差不多可以接受
    if ((UTFRate > 75) && (UTFNum>150) && (UnKnowRate<20)) return UTFRate;
    return 0;
}





int TL_IsATwiceBig5Code(unsigned char* pBuf)
{
#define BIGZONENum  8
    const unsigned char Big5Tbl[BIGZONENum][12]={
        {0xA1,0xA2,0x40,0x7E,0xA1,0xFE,0},
        {0xA3,0xA3,0x40,0x7E,0xA1,0xBF,0xE1,0xE1,0},
        {0xA4,0xC5,0x40,0x7E,0xA1,0xFE,0},
        {0xC6,0xC6,0x40,0x7E,0xA1,0xfE,0},
        {0xC7,0xC7,0x40,0x7E,0xA1,0xFE,0},
        {0xC8,0xC8,0x40,0x7E,0xA1,0xD3,0},
        {0xC9,0xF8,0x40,0x7E,0xA1,0xFE,0},
        {0xF9,0xF9,0x40,0x7E,0xA1,0xD5,0xD6,0xDC,0xDD,0xFE,0}
    };
    int  Zone = 0,hi,low;
    if ((pBuf[0] < Big5Tbl[0][0])|| (pBuf[0] > Big5Tbl[BIGZONENum-1][1])) return 0;
    
    hi = BIGZONENum-1;
    low = 0;
    while (low <= hi)
    {
        Zone = (hi+low+1)/2;
        if (CHARBetween(pBuf[0],Big5Tbl[Zone][0],Big5Tbl[Zone][1])) break;
        if (low == hi) return 0;
        if (pBuf[0] < Big5Tbl[Zone][0]) hi= Zone-1;
        else low = Zone+1;
    }
    for (low=2;;low+=2)
    {
        if (Big5Tbl[Zone][low] == 0) return 0;
        if (CHARBetween(pBuf[1],Big5Tbl[Zone][low],Big5Tbl[Zone][low+1])) return 1;
    }
    return 0;
}



int TL_IsATwiceGB2312Code(unsigned char* pBuf)
{
#define GB2312ZONENum  9
    const unsigned char GB2312Tbl[GB2312ZONENum][10]={
        {0xA1,0xA1,0xFE,0},
        {0xA2,0xB1,0xE2,0xE5,0xEE,0xF1,0xFC,0},
        {0xA3,0xA1,0xFE,0},
        {0xA4,0xA1,0xF3,0},
        {0xA5,0xA1,0xF6,0},
        {0xA6,0xA1,0xB8,0xC1,0xD8,0},
        {0xA7,0xA1,0xC1,0xD1,0xF1,0},
        {0xA8,0xA1,0xBA,0xC5,0xE9,0},
        {0xA9,0xA4,0xEF,0}
    };
    int  Zone,hi,low;
    if ((pBuf[0] < 0xA1)|| (pBuf[0] > 0xF7)) return 0;
    
    hi = GB2312ZONENum-1;
    low = 0;
    while (low <= hi)
    {
        Zone = (hi+low+1)/2;
        if (pBuf[0] == GB2312Tbl[Zone][0])
        {
            for (low=1;;low+=2)
            {
                if (GB2312Tbl[Zone][low] == 0) return 0;
                if (CHARBetween(pBuf[1],GB2312Tbl[Zone][low],GB2312Tbl[Zone][low+1])) return 1;
            }
        }
        if (low == hi) break;
        if (pBuf[0] < GB2312Tbl[Zone][0]) hi= Zone-1;
        else low = Zone+1;
    }
    if ((pBuf[0] == 0xD7) && CHARBetween(pBuf[1],0xFA,0xFE)) return 0;
    if (CHARBetween(pBuf[0],0xB0,0xF7) && CHARBetween(pBuf[1],0xA1,0xFE)) return 1;
    return 0;
}


int    TL_IsATwiceGBKCode(unsigned char* pBuf)
{
    if ((pBuf[0]<0x81)||(pBuf[0]==0xFF)) return 0;
    if ((pBuf[1]<0x40)||(pBuf[1]==0xFF)) return 0;
    if (pBuf[1]==0x7F) return 0;
    return 1;
}

int TL_DetechStreamCode(unsigned char* pBuf,int Len,int* CodeOut,int* ProbalyOut,int* ANSIDetailCode)
{

    int  i,AsciiNum=0,ZeroNum=0,UnKnow=0;
    int  CharNum[10];
    int  CharRate[10],CharRateExpend[10];
    int  TypeMatchNum=0;
    int  LastConsZero=0;
    int  BufCharCode=0,AnsiExType=0,BufCharProbaly=0;
   
    memset(CharNum, 0, sizeof(CharNum));
    memset(CharRate, 0, sizeof(CharRate));
    memset(CharRateExpend, 0, sizeof(CharRateExpend));
    if (CodeOut!=NULL) *CodeOut = 0;
    if (Len<1) return 0;
    for (i=0;i<Len;i++)
    {
        if (pBuf[i]==0)
        {
            ZeroNum++;
            LastConsZero++;
            if (LastConsZero > 5) break;
            continue;
        }
        LastConsZero=0;
        if (pBuf[i]<=0x7F)
        {
            if (((i+1)<Len) && (pBuf[i+1] == 0)) // 先看是否unicode
            {
                CharNum[CODE_UNICODE] += 2;
                i++;
                continue;
            }
            AsciiNum++;
            continue;
        }
        if (CHARBetween(pBuf[i],0xC0,0xDF) && ((i+1)<Len) && CHARBetween(pBuf[i+1],0x80,0xBF))
        {//两字节UTF,110xxx,
            CharNum[CODE_UTF8] += 2;
            i+=1;
            continue;
        }
        if (CHARBetween(pBuf[i],0xE0,0xEF) && ((i+2)<Len) && CHARBetween(pBuf[i+1],0x80,0xBF) && CHARBetween(pBuf[i+2],0x80,0xBF))
        {//三字节UTF
            CharNum[CODE_UTF8] += 3;
            i+=2;
            continue;
        }
        if (CHARBetween(pBuf[i],0x81,0xFE) && ((i+3)<Len) && CHARBetween(pBuf[i+1],0x30,0x39) && CHARBetween(pBuf[i+2],0x81,0xFE)&& CHARBetween(pBuf[i+3],0x30,0x39))
        {//4字节gb18030
            CharNum[CODE_GB18030] += 4;
            i+=3;
            continue;
        }
        TypeMatchNum =0;
        if (((i+2)<Len) && TL_IsATwiceBig5Code(pBuf+i))
        {
            CharNum[CODE_BIG5] += 2;
            TypeMatchNum++;
            
        }
        if (CHARBetween(pBuf[i],0x81,0xFE) && ((i+1)<Len) && CHARBetween(pBuf[i+1],0x40,0xFE) && (pBuf[i+1] !=0x7F))
        { //字节GBK  字符范围 首字节0x81 - 0xFE,低字节0x40 - 0xFE ,剔除 xx7F 一条线  ,包含GB2312
            CharNum[CODE_ANSI] += 2;
            TypeMatchNum+=2;
            
            if ((ANSIDetailCode!=NULL)&&TL_IsATwiceGB2312Code(pBuf+i))  CharNum[0] += 2;
            
        }
        if (TypeMatchNum>0)
        {
            i++;
            continue;
        }
        UnKnow++;
    }

    for (i=1;i<10;i++)
    {
        if (CharNum[i] == 0) continue;
        CharRate[i] = (int)(100*((float)CharNum[i] /(float)(Len-AsciiNum)));
        if (i!=CODE_UNICODE)  CharRateExpend[i] = (int)(100*((float)(CharNum[i]+AsciiNum) /(float)Len));
        else CharRateExpend[i] = (int)(100*((float)(CharNum[i]+UnKnow+CharNum[CODE_ANSI]) /(float)Len));
    }
    for (i=1;i<10;i++)
    {
        if (CharRate[i] < 76)  continue;
        if (BufCharProbaly>CharRate[i]) continue;
        BufCharCode = (int)i;
        BufCharProbaly = CharRate[i];
    }
    if (BufCharCode == 0)
    {
        for (i=1;i<10;i++)
        {
            if (CharRateExpend[i] < 90)  continue;
            if (BufCharProbaly>CharRateExpend[i]) continue;
            BufCharCode = (int)i;
            BufCharProbaly = CharRateExpend[i];
        }
    }

    if ((BufCharCode == CODE_ANSI) && (CharNum[CODE_ANSI] <= CharNum[CODE_BIG5]+2) && (CharNum[CODE_ANSI]>30)) BufCharCode = CODE_BIG5;
    if (AsciiNum == Len)
    {
        BufCharCode = CODE_ANSI;
        AnsiExType = CODE_ANSIASCII;
        BufCharProbaly = 100;
    }
    else if ((ANSIDetailCode!=NULL)&&(BufCharCode == CODE_ANSI)&&(AnsiExType == 0))
    {
        if (CharNum[0] == CharNum[CODE_ANSI]) AnsiExType = CODE_ANSIGB2312;
        else AnsiExType = CODE_ANSIGBK;
    }
    if (CodeOut!=NULL) *CodeOut = BufCharCode;
    if (ProbalyOut!=NULL) *ProbalyOut = BufCharProbaly;
    if ((ANSIDetailCode!=NULL)&& (AnsiExType>0)) *ANSIDetailCode = AnsiExType;
    if (BufCharCode>0) return 1;
    return 0;
}
