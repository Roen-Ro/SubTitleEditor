//
//  SrtParser.m
//  EnTT
//
//  Created by lolaage on 2016/12/25.
//
//


#import "SubTitleProcess.h"


#define SRT_LINE_RGEXP_NUM @"(\\d+ *\\t*\\r\\n)??" //开头序号
#define SRT_LINE_RGEXP_TIME @"\\d{2}:\\d{2}:\\d{2},\\d{1,3} --> \\d{2}:\\d{2}:\\d{2},\\d{1,3} *\\t*\\r\\n"//时间标签
#define SRT_LINE_RGEXP_LINE @"(.+ *\\t*(\\r\\n|$))+"//台词内容

NSString *lrcTimeRgexp = @"\\[-?(\\d{1,4}):(\\d{2})\\.(\\d{2})\\]";
NSString *timeOffsetTagRgexp =  @"\\[offset:-?\\d*\\]";
NSString *lrcTagRgexp = @"\\[.*?\\]";
NSString *lrcStarMarkRgexp = @"\\[star:\\d+\\]";
NSString *lrcLineRgexp =@"\\[-?(\\d{1,4}):(\\d{2})\\.(\\d{2})\\].*";

//#define SRT_LINE_RGEXP_NUM @"(\\d+ *\\t*\\r??\\n)??" //开头序号
//#define SRT_LINE_RGEXP_TIME @"\\d{2}:\\d{2}:\\d{2},\\d{1,3} --> \\d{2}:\\d{2}:\\d{2},\\d{1,3} *\\t*\\r??\\n"//时间标签
//#define SRT_LINE_RGEXP_LINE @"(.+ *\\t*(\\r??\\n|$))+"//台词内容

@implementation SrtLine

-(instancetype)initWithSrtChunkString:(NSString *)chunkString
{
    self = [super init];
    if(self)
    {
        [self parseFromSrtChunkString:chunkString];
    }
    
    return self;
    
}

-(NSArray *)parseLineContents:(NSArray *)lines
{
    NSMutableArray *mArray = [NSMutableArray arrayWithArray:lines];
    BOOL needModify = NO;
    for(int i=0; i<lines.count; i++)
    {
        NSString *singleLine = [lines objectAtIndex:i];
        if([singleLine hasPrefix:@"{"] && [singleLine hasSuffix:@"{\\r}"])
        {
            needModify = YES;
            NSString *content;
            NSScanner *scanner = [NSScanner scannerWithString:singleLine];
            [scanner scanUpToString:@"}" intoString:nil];
            [scanner scanString:@"}" intoString:nil];
            [scanner scanUpToString:@"{\\r}" intoString:&content];
            
            if(content)
                [mArray replaceObjectAtIndex:i withObject:content];
        }
    }
    
    if(needModify)
        return mArray;
    else
        return lines;
}

-(void)parseFromSrtChunkString:(NSString *)chunkString
{
    NSPredicate *lineNumPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",SRT_LINE_RGEXP_NUM];
    NSPredicate *timePredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",SRT_LINE_RGEXP_TIME];
    NSArray *lines = [chunkString componentsSeparatedByString:@"\r\n"];
    
    NSUInteger timeLineIndex = NSUIntegerMax;
    int i = 0;
    for(NSString *line in lines)
    {
        if(i > timeLineIndex)
        {
            NSArray *lineStrs = [lines subarrayWithRange:NSMakeRange(i, lines.count-i)];
            
            self.lines = [self parseLineContents:lineStrs];
            break;
        }
        else if(i==0 && [lineNumPredicate evaluateWithObject:[line stringByAppendingString:@"\r\n"]])
        {
            self.lineNum = [line integerValue];
        }
        else if([timePredicate evaluateWithObject:[line stringByAppendingString:@"\r\n"]])
        {
            timeLineIndex = i;
            [self pareseTimeTagFromTimeString:line];
        }
        
        i++;
    }
}

-(void)pareseTimeTagFromTimeString:(NSString *)timeString
{
    NSArray *times = [timeString componentsSeparatedByString:@"-->"];
    self.startSecond = [self timeFromLrcTimeTag:times.firstObject];
    self.endSecond = [self timeFromLrcTimeTag:[times objectAtIndex:1]];
}

-(NSTimeInterval)timeFromLrcTimeTag:(NSString *)timeTag
{
    NSScanner *scanner = [[NSScanner alloc]initWithString:timeTag];
    NSString *hour, *minute, *second, *millisecond,*tmp;
    
    [scanner scanUpToString:@":" intoString:&hour];
    [scanner scanString:@":" intoString:&tmp];
    [scanner scanUpToString:@":" intoString:&minute];
    [scanner scanString:@":" intoString:&tmp];
    [scanner scanUpToString:@"," intoString:&second];
    [scanner scanString:@"," intoString:&tmp];
    [scanner scanUpToString:@" " intoString:&millisecond];
    if(!millisecond)
        [scanner scanUpToString:@"" intoString:&millisecond];
    
    NSTimeInterval interval = hour.intValue*3600 + minute.intValue*60 + second.intValue + millisecond.floatValue/1000;
    
    return interval;
}

-(NSString *)convertToLrcLineByRevertingLineOrder:(BOOL)revert addLineSeparator:(NSString *)separator;
{
    if(self.lines.count == 0)
        return nil;
    
    if(!separator)
        separator = @" ";
    
    NSString *timetag =[SubTitleProcess lrcTimeTagStringForTime:self.startSecond];
    NSString *lrcLine;
    if(self.lines.count > 1)
    {
        NSString *line1 = self.lines.firstObject;
        NSString *line2 = [self.lines objectAtIndex:1];
        if(line2.length > 0)
        {
            if(revert)
            {
                line1 = [self.lines objectAtIndex:1];
                line2 = self.lines.firstObject;
            }
            
            lrcLine = [NSString stringWithFormat:@"%@%@%@%@\r\n",timetag,line1,separator,line2];
        }
        else
            lrcLine = [NSString stringWithFormat:@"%@%@\r\n",timetag,self.lines.firstObject];
    }
    else
    {
        lrcLine = [NSString stringWithFormat:@"%@%@\r\n",timetag,self.lines.firstObject];
    }
    
    
    return lrcLine;
}



@end

#pragma mark-

@implementation LrcLine



@end


#pragma mark-
@implementation SubTitleProcess

+(NSString *)readStringFromFile:(NSString *)path
{
    NSStringEncoding encode;
    NSData *data = [NSData dataWithContentsOfFile:path];
    unsigned char charset[4];
    [data getBytes:charset range:NSMakeRange(0, 4)];
    //   NSLog(@"Encode identifier hex:%4X %4X %4X %4X",charset[0],charset[1],charset[2],charset[3]);
    //    NSLog(@"charset:0X%08x",*((uint32_t *)charset));
    if(charset[0]==0xFF && charset[1]==0XFE) // Unicode/UTF-16/UCS-2
        encode = NSUnicodeStringEncoding;
    else if(charset[0]==0xFE&& charset[1]==0XFF) // Unicode/UTF-16/UCS-2 Big edian
        encode = NSUTF16BigEndianStringEncoding;
    else if(charset[0]==0xEF && charset[1]==0XBB && charset[2]==0XBF) //utf-8
        encode = NSUTF8StringEncoding;
    else //if(*((uint32_t *)charset)==0x3A69745B)
        encode = CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000);
    
    NSString *finalString = [[NSString alloc]initWithData:data encoding:encode];
    if(finalString == nil)
    {
        NSLog(@"USE NSUTF8StringEncoding decode.");
        encode = NSUTF8StringEncoding;
        finalString = [[NSString alloc]initWithData:data encoding:encode];
    }

    return finalString;
}

+(NSArray<NSTextCheckingResult *> *)chunksWithRegularExpressionPattern:(NSString *)pattern forString:(NSString *)stringContent
{
    NSError *error;
    NSRegularExpression* regex = [[NSRegularExpression alloc]initWithPattern:pattern options:0 error:&error];
    NSArray* chunks = [regex matchesInString:stringContent options:0 range:NSMakeRange(0, [stringContent length])];
    
    return chunks;
}

+(NSArray<SrtLine *>*)parseSrtString:(NSString *)srtFileString
{
    NSString *srtRegularPattern = [NSString stringWithFormat:@"%@%@%@",SRT_LINE_RGEXP_NUM,SRT_LINE_RGEXP_TIME,SRT_LINE_RGEXP_LINE];
    NSArray* chunks = [self chunksWithRegularExpressionPattern:srtRegularPattern forString:srtFileString];
    
    NSMutableArray *mArray = [NSMutableArray arrayWithCapacity:chunks.count];
    NSInteger i=0;
    for (NSTextCheckingResult* b in chunks)
    {
        @autoreleasepool
        {
            NSString *subStr = [srtFileString substringWithRange:b.range];
            SrtLine *line = [[SrtLine alloc]initWithSrtChunkString:subStr];
            if(line)
                [mArray addObject:line];
        }

        
        i++;

    }
    
    if(mArray.count > 0)
        return [NSArray arrayWithArray:mArray];
    else
        return nil;
}

+(NSString *)convertSrtString2LrcString:(NSString *)srtString revertLineOrder:(BOOL)revert
{
    NSMutableArray *srtLines = [NSMutableArray arrayWithArray:[self parseSrtString:srtString]];
    
    [srtLines sortUsingComparator:^(id obj1, id obj2) {
        SrtLine *line1 = obj1;
        SrtLine *line2 =  obj2;
        return (line1.startSecond > line2.startSecond ? NSOrderedDescending:NSOrderedAscending);
    }];
    
    NSMutableString *mStr = [NSMutableString string];
    
    SrtLine *preLine = nil;
    for(SrtLine *line in srtLines)
    {
        //如果上一句台词结束时间和当前台词开始时间差大于 1 秒，中间插入空行
        if(preLine && (line.startSecond - preLine.endSecond > 0.7))
        {
            [mStr appendFormat:@"%@\r\n",[self lrcTimeTagStringForTime:preLine.endSecond]];
        }
        
        NSString *lrc = [line convertToLrcLineByRevertingLineOrder:revert addLineSeparator:@"<br>"];
        if(lrc)
        {
            [mStr appendString:lrc];
        }
        
        preLine = line;
    }
    
    return mStr;
}

+(NSString *)convertSrtString2LrcStringFromFile:(NSString *)srtFilePath revertLineOrder:(BOOL)revert
{
    return [self convertSrtString2LrcString:[self readStringFromFile:srtFilePath] revertLineOrder:revert];
}

+(NSString *)lrcTimeTagStringForTime:(NSTimeInterval)time
{
    int min = time/60;
    float sec = (time - min*60);
    NSString *timetag = [[NSString alloc] initWithFormat:@"[%02d:%05.2f]",min,sec];
    
    return timetag;
}



#pragma mark- lrc

+(NSTimeInterval )getTimeOffsetFromLrcContent:(NSString *)lrcContent
{
    NSInteger len = [lrcContent length];
    NSRange range = [lrcContent rangeOfString:timeOffsetTagRgexp options:NSRegularExpressionSearch range:NSMakeRange(0, len)];
    if(range.location == NSNotFound || range.length == 0)
    {
        return 0.0;
    }
    NSString *offsetTag = [lrcContent substringWithRange:range];
    
    NSArray* parts = [offsetTag componentsSeparatedByString:@":"];
    NSString *str = [parts objectAtIndex:1];
    NSString *timeStr = [str substringWithRange:NSMakeRange(0,[str length]-1)];
    NSInteger msec = timeStr.integerValue;
    NSTimeInterval offset = (NSTimeInterval)msec/1000;
    return offset;
}

+(NSTimeInterval)timeSecondFromLrcTag:(NSString *)tag
{
    NSArray* parts = [tag componentsSeparatedByString:@":"];
    
    NSString *str1 = [parts objectAtIndex:0];
    NSString *str2 = [parts objectAtIndex:1];
    
    NSString *minString = [str1 substringWithRange:NSMakeRange(1, [str1 length]-1)];
    NSString *secString = [str2 substringWithRange:NSMakeRange(0, [str2 length]-1)];;
    
    int min = [minString intValue];
    float sec = [secString floatValue];
    return (min*60+sec);
}

+(NSArray<LrcLine *> *)parseLrcString:(NSString *)lrcContent
{
    NSString *str1;
    NSTimeInterval offset;
    
    if (lrcContent == nil)
    {
        NSLog(@"can not parse lrc bcs lrc not found");
        return nil;
    }
    
    NSMutableArray *CtrlInfoArray=[NSMutableArray array];
    
    offset = [self getTimeOffsetFromLrcContent:lrcContent];
   // NSLog(@"offset:%f",offset);
    
    NSRegularExpression* regex = [[NSRegularExpression alloc]initWithPattern:lrcLineRgexp options:0 error:nil];
    NSArray* chunks = [regex matchesInString:lrcContent options:0 range:NSMakeRange(0, [lrcContent length])];
    
    NSInteger i=0;
    for (NSTextCheckingResult* b in chunks)
    {
        str1 = [lrcContent substringWithRange:b.range];
        NSArray *array = [self parseLrcLine:str1 withTimeOffset:offset andIndex:i++];
        if(array)
            [CtrlInfoArray addObjectsFromArray:array];
    }
    
    [CtrlInfoArray sortUsingComparator:^NSComparisonResult(LrcLine * obj1, LrcLine * obj2) {
       return (obj1.second > obj2.second ? NSOrderedDescending:NSOrderedAscending);
    }];
    
    return [NSArray arrayWithArray:CtrlInfoArray];
}

//used to parse lines that actually with time tag only
+(NSArray <LrcLine *>*) parseLrcLine:(NSString *)line withTimeOffset:(NSTimeInterval)offset andIndex:(NSInteger)index
{
    NSInteger /*loc = 0,*/ tidx = 0;
    NSInteger len = [line length];
    NSRange range,subrang;
    NSMutableArray *maray = [NSMutableArray arrayWithCapacity:2000];
    NSMutableString *lrcStr=[[NSMutableString alloc]initWithString:line];
    NSString *str1;
    
    while (1)
    {
        range = [lrcStr rangeOfString:lrcTagRgexp options:NSRegularExpressionSearch range:NSMakeRange(0, len)];

        len = len - range.length;
        
        if(range.location == NSNotFound || range.length == 0)
        {
            for(LrcLine *l in maray)
            {
                l.content = lrcStr;
            }
            break;
        }
        
        str1 = [lrcStr substringWithRange:range];
        subrang = [str1 rangeOfString:lrcTimeRgexp options:NSRegularExpressionSearch];
        if(subrang.location!=NSNotFound && subrang.length!=0) //time
        {
            LrcLine *line = [[LrcLine alloc] init];
            NSTimeInterval sec = [self timeSecondFromLrcTag:str1];
            sec+=offset;
            line.second =sec;
            line.timeTagIndex = tidx++;
            line.lineIndex = index;
           
            [maray addObject:line];
        }
        [lrcStr deleteCharactersInRange:range];
    }
    
    return maray;
}

+(nullable NSArray <NSArray<LrcLine *>*>*)splitLrcFromLrcString:(NSString *)lrcString wihtSplitTimePos:(nonnull NSArray <NSNumber *> *)secPoses
{
    NSArray *allLines = [self parseLrcString:lrcString];
    
    if(secPoses.count == 0)
        return allLines;
    
    NSMutableArray *timeSplits = [NSMutableArray arrayWithArray:secPoses];
    [timeSplits sortUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2)
     {
         return (obj1.floatValue > obj2.floatValue ? NSOrderedDescending:NSOrderedAscending);
     }];
    
    NSMutableArray *parts = [NSMutableArray arrayWithCapacity:secPoses.count+1];
    
    NSTimeInterval currentSearchTime = secPoses.firstObject.doubleValue;
    NSTimeInterval lastSplitTime = 0.000;
    NSUInteger idx = 0;
    NSUInteger curPartStartIndex = 0;
    NSUInteger currentPosIdx = 0;
    NSTimeInterval orTime;
    BOOL lastSeg = NO;//最后一段
    for(LrcLine *line in allLines)
    {
        orTime = line.second;
        line.second -= lastSplitTime;
        if(orTime >= currentSearchTime && !lastSeg)
        {
            lastSplitTime = currentSearchTime;
            NSArray *segs;
//            if(fabs(orTime - currentSearchTime) < 0.0001)
//            {
//                segs = [allLines subarrayWithRange:NSMakeRange(curPartStartIndex, idx-curPartStartIndex+1)];
//                curPartStartIndex = idx+1;
//            }
//            else
            {
                segs = [allLines subarrayWithRange:NSMakeRange(curPartStartIndex, idx-curPartStartIndex)];
                curPartStartIndex = idx;
                line.second = orTime - lastSplitTime;
            }
            
            [parts addObject:segs];
            
            
            currentPosIdx++;
            if(currentPosIdx >= secPoses.count)//如果是最后一个分割点
            {
                lastSeg = YES;
            }
            else
            {
                currentSearchTime = [secPoses objectAtIndex:currentPosIdx].doubleValue;
            }
            
        }
        
        idx++;
    }
    
    //如果遍历结束，还没有分割到最后一个时间段，说明有分割时间点大于lrc的最大时间
    if(curPartStartIndex < allLines.count)//其实这里永远都是true
    {
        NSArray *segs = [allLines subarrayWithRange:NSMakeRange(curPartStartIndex, allLines.count-curPartStartIndex)];
        [parts addObject:segs];
    }
    
    return parts;
}
+(NSError *)saveLrcLines:(nonnull NSArray <LrcLine *>*)lrcLines toFile:(nonnull NSString *)path
{
    NSError *error = nil;
    NSMutableString *mStr = [NSMutableString string];
    for(LrcLine *line in lrcLines)
    {
        [mStr appendFormat:@"%@%@\r\n",[self lrcTimeTagStringForTime:line.second],line.content];
    }
    
    if(mStr.length > 0)
    {
        NSData *data = [mStr dataUsingEncoding:NSUTF8StringEncoding];
        [data writeToFile:path options:NSDataWritingAtomic error:&error];
    }
    else
        error = [NSError errorWithDomain:@"lrc数据为空" code:-999 userInfo:nil];
    
    return error;
}

@end
