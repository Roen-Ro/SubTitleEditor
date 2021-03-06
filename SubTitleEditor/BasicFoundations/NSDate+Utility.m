//
//  NSDate+BirthDay.m
//  
//
//  Created by 罗亮富 on 12-12-6.
//  Copyright (c) 2012年  All rights reserved.
//

#define SECOND_PER_DAY 86400L


#import "NSDate+Utility.h"

@implementation NSDate (Utility)


-(NSInteger)ageAsBirthDay
{
    NSDate *today = [NSDate date];
    NSCalendar *currentCalendar = [NSCalendar autoupdatingCurrentCalendar];
    unsigned unitFlags = NSYearCalendarUnit;
    NSDateComponents *component= [currentCalendar components:unitFlags fromDate:self toDate:today options:0];
    return component.year;
}

/***************************************
 水瓶座：1月21日 - 2月19日
 双鱼座：2月20日 - 3月20日
 白羊座：3月21日 - 4月20日
 金牛座：4月21日 - 5月21日
 双子座：5月22日 - 6月21日
 巨蟹座：6月22日 - 7月22日
 狮子座：7月23日 - 8月23日
 处女座：8月24日 - 9月23日
 天秤座：9月24日 - 10月23日
 天蝎座：10月24日 - 11月22日
 射手座：11月23日 - 12月21日
 魔羯座：12月22日 - 1月20日
 *************************************/
-(NSString *)constellationAsBirthDay
{
    NSArray *constellations = [NSArray arrayWithObjects:
                               NSLocalizedString(@"水瓶座",nil),
                               NSLocalizedString(@"双鱼座",nil),
                               NSLocalizedString(@"白羊座",nil),
                               NSLocalizedString(@"金牛座",nil),
                               NSLocalizedString(@"双子座",nil),
                               NSLocalizedString(@"巨蟹座",nil),
                               NSLocalizedString(@"狮子座",nil),
                               NSLocalizedString(@"处女座",nil),
                               NSLocalizedString(@"天秤座",nil),
                               NSLocalizedString(@"天蝎座",nil),
                               NSLocalizedString(@"射手座",nil),
                               NSLocalizedString(@"摩羯座",nil),
                               nil];
    
    DateType constellationsStarts[12]={{1,21},{2,20},{3,21},{4,21},{5,22},{6,22},{7.23},{8,24},{9,24},{10,24},{11,23},{12,22}};
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"MMdd"];
    NSString *dateStr = [formatter stringFromDate:self];
    unsigned char tmonth = (unsigned char)[[dateStr substringWithRange:NSMakeRange(0, 2)] integerValue];
    unsigned char tday = (unsigned char)[[dateStr substringWithRange:NSMakeRange(2, 2)] integerValue];
    int i;
    for(i=0; i<12; i++)
    {
        int next = i+1;
        if(next>11)
            next = 0;
        
        if((constellationsStarts[i].month==tmonth && constellationsStarts[i].date<=tday)
           ||(constellationsStarts[next].month==tmonth && constellationsStarts[next].date>tday))
        {
            break;
        }
    }
    return [constellations objectAtIndex:i];
}

-(BOOL)isOtherDayFromDate:(NSDate *)otherDay;
{
    NSInteger fullDay = (NSInteger)[self timeIntervalSinceDate:otherDay]/SECOND_PER_DAY;
    if(fullDay>0)
        return YES;
   
    NSCalendarUnit unit = NSCalendarUnitDay;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *componentsSelf = [calendar components:unit fromDate:self];
    NSDateComponents *componentsOther = [calendar components:unit fromDate:otherDay];
    if([componentsSelf day] != [componentsOther day])
        return YES;
    
    return NO;
}


+(NSDate *)dateFromFormatedString:(NSString *)formatString
{
    NSDate *date;
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:DATE_FORMAT_DEFAULT];
    date = [formatter dateFromString:formatString];
    return date;
}

+(NSDate *)dateFromFormatedString:(NSString *)formatString byFormat:(NSString *)format
{
    NSDate *date;
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:format];
    date = [formatter dateFromString:formatString];
    return date;
}

-(NSString *)dateStringWithFormat:(NSString *)formatString
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:formatString];
    return [formatter stringFromDate:self];
}

-(NSString *)appDateDescription
{
    return [self dateStringWithFormat:TIME_FORMAT_DEFAULT];
}

-(NSString *)defaultDescription
{
    return [self dateStringWithFormat:@"yyyy-MM-dd HH:mm:ss"];
}
-(NSString*)dateStringFromNow
{
    NSString* timeStr;
    NSTimeInterval now  = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval old = [self timeIntervalSince1970];
    NSTimeInterval component =abs( now - old);
    NSInteger speTime = component/(3600*24);
    if ( speTime >=20&&speTime<=24)
    {
        
        timeStr = @"1天以前";
        
    }
    else if ( speTime <20)
    {
        timeStr = [NSString stringWithFormat:@"%lld小时前",speTime+1];
    }
    else if(speTime >24&&speTime<=48)
    {
        timeStr = @"2天以前";
    }
    else if(speTime >48&&speTime<=74)
    {
        timeStr = @"3天以前";
    }
    else if(speTime >74&&speTime<=168)
    {
        timeStr = @"一周以内";
        
    }
    else
    {
        timeStr = @"一个月以内";
        
    }
    return timeStr;
}
-(NSString *)referencedDateDescription
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *date = [NSDate date];
    NSDateComponents *componentsSelf = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                               fromDate:self];
    
    NSDateComponents *componentsNow = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                               fromDate:date];

    if([componentsNow year] - [componentsSelf year]>0)
        return [self dateStringWithFormat:TIME_FORMAT_DEFAULT];
    else if([componentsNow month] - [componentsSelf month] > 0)
        return [self dateStringWithFormat:@"MM-dd H:mm"];
    else if([componentsNow day] - [componentsSelf day] > 2)
        return [self dateStringWithFormat:@"MM-dd H:mm"];
    else if([componentsNow day] - [componentsSelf day] == 2)//前天
    {
        return [NSString stringWithFormat:@"前天 %@",[self dateStringWithFormat:@"H:mm"]];
    }
    else if([componentsNow day] - [componentsSelf day] == 1)//昨天
    {
        return [NSString stringWithFormat:@"昨天 %@",[self dateStringWithFormat:@"H:mm"]];
    }
    else //今天
        return [self dateStringWithFormat:@"H:mm"];
    
    
    return nil;
}

+(NSString *)timeDateFormatter:(NSDate *)date type:(int)_type
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    switch (_type) {
        case 1:
            [dateFormatter setDateFormat:@"yyyy"];
            break;
        case 2:
            [dateFormatter setDateFormat:@"yyyy-MM"];
            break;
        case 3:
            [dateFormatter setDateFormat:@"yyyy-MM-dd"];
            break;
        case 4:
            [dateFormatter setDateFormat:@"hh"];
            break;
        case 5:
            [dateFormatter setDateFormat:@"mm"];
            break;
        case 6:
            [dateFormatter setDateFormat:@"ss"];
            break;
        case 7:
            [dateFormatter setDateFormat:@"a"];
            break;
        case 8:
            [dateFormatter setDateFormat:@"MM"];
            break;
        case 9:
            [dateFormatter setDateFormat:@"dd"];
            break;
        case 10:
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
            break;
        case 11:
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            break;
        case 12:
            [dateFormatter setDateFormat:@"HH:mm:ss"];
            break;
        case 13:
            [dateFormatter setDateFormat:@"yyyy年MM月dd日 HH时mm分"];
            break;
        case 14:
            [dateFormatter setDateFormat:@"yyyy年MM月dd日"];
            break;
        case 15:
            [dateFormatter setDateFormat:@"HH:mm"];
            break;
        case 16:
            [dateFormatter setDateFormat:@"MM月dd日 HH时mm分"];
            break;
        case 17:
            [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
            break;
        default:
            break;
    }
    
    
    NSString *timeString = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
    return timeString;
    
}


-(NSDateComponents *)datePart{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:self];
    return components;
    //    NSInteger hour = [components hour];
    //    NSInteger minute = [components minute];
}


-(NSDateComponents *)timePart{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:self];
    
    return components;
}

+(NSComparisonResult)compareBetweenDate:(NSDate *)date1 andDate:(NSDate *)date2{
    
    NSComparisonResult result;
    
    if ((date1 == nil && date2 == nil) || (date2 != nil && date1 != nil && [date1 compare:date2] == NSOrderedSame)) {
        result = NSOrderedSame;
    }else if((date1 != nil && date2 == nil) || [date1 compare:date2] == NSOrderedDescending){
        result = NSOrderedDescending;
    }else{
        result = NSOrderedAscending;
    }
    return result;
    
}

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate
                 interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSDayCalendarUnit
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}

+(NSDate *)today{
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSUInteger preservedComponents = (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit);
    date = [calendar dateFromComponents:[calendar components:preservedComponents fromDate:date]];
    return date;
}


+ (NSDateComponents *)componetsWithTimeInterval:(NSTimeInterval)timeInterval
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *date1 = [[NSDate alloc] init];
    NSDate *date2 = [[NSDate alloc] initWithTimeInterval:timeInterval sinceDate:date1];
    
    unsigned int unitFlags =
    NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit |
    NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit;
    
    return [calendar components:unitFlags
                       fromDate:date1
                         toDate:date2
                        options:0];
}

+ (NSString *)timeDescriptionOfTimeInterval:(NSTimeInterval)timeInterval
{
    NSDateComponents *components = [self.class componetsWithTimeInterval:timeInterval];
    
    // if (components.hour > 0)
    {
        return [NSString stringWithFormat:@"%02d:%02d:%02d", components.hour, components.minute, components.second];
    }
    
    //    else
    //    {
    //        return [NSString stringWithFormat:@"%02d:%02d", components.minute, components.second];
    //    }
}

+ (NSString *)timeDescription1OfTimeInterval:(NSTimeInterval)timeInterval
{
    NSDateComponents *components = [self.class componetsWithTimeInterval:timeInterval];
    NSMutableString *mStr = [NSMutableString string];
    
    // BOOL hasPreComponents = NO;
    if(components.year>0)
    {
        [mStr appendFormat:@"%d年",components.year];
    }
    if(components.month>0)
    {
        [mStr appendFormat:@"%d月",components.month];
    }
    if(components.day>0)
    {
        [mStr appendFormat:@"%d天",components.day];
    }
    if(components.hour>0)
    {
        [mStr appendFormat:@"%d小时",components.hour];
    }
    if(components.minute>0)
    {
        [mStr appendFormat:@"%d分",components.minute];
    }
    if(components.second>0)
    {
        [mStr appendFormat:@"%d秒",components.second];
    }
    
    return mStr;
}

//传入 dateString 是一个 YYYY-MM-dd HH:mm:ss 格式的字符串
+ (NSDate*)getDateWith:(NSString *)dateString
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"]; // ----------设置你想要的格式,hh与HH的区别:分别表示12小时制,24小时制
    
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    [formatter setTimeZone:timeZone];
    
    NSDate* date = [formatter dateFromString:dateString]; //------------将字符串按formatter转成nsdate
    
    return date;
}


@end
