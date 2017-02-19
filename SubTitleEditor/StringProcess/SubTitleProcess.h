//
//  SrtParser.h
//  EnTT
//
//  Created by Roen on 2016/12/25.
//
//

#import <Foundation/Foundation.h>

@interface SrtLine : NSObject

@property (nonatomic, strong) NSArray<NSString *> *lines; //台词内容,这里内容可能有多行，双语字幕就有原文和翻译两行
@property NSTimeInterval startSecond;//开始时间
@property NSTimeInterval endSecond;//结束时间
@property NSUInteger lineNum; //序号 暂时没用到

@end

@interface LrcLine : NSObject
@property (nonatomic, copy) NSString *content;
@property (nonatomic) NSTimeInterval second;
@property (nonatomic) NSUInteger timeTagIndex;
@property (nonatomic) NSUInteger lineIndex;
@end


@interface SubTitleProcess : NSObject

+(NSString *)readStringFromFile:(NSString *)path;

+(NSArray<NSTextCheckingResult *> *)chunksWithRegularExpressionPattern:(NSString *)pattern forString:(NSString *)stringContent;

+(NSArray<SrtLine *>*)parseSrtString:(NSString *)srtString;

+(NSString *)convertSrtString2LrcString:(NSString *)srtString revertLineOrder:(BOOL)revert;

+(NSString *)convertSrtString2LrcStringFromFile:(NSString *)srtFilePath revertLineOrder:(BOOL)revert;



+(NSString *)lrcTimeTagStringForTime:(NSTimeInterval)time;

+(NSArray<LrcLine *> *)parseLrcString:(NSString *)lrcContent;

+(NSArray <NSArray<LrcLine *>*>*)splitLrcFromLrcString:(NSString *)lrcString wihtSplitTimePos:(NSArray <NSNumber *> *)secPoses;

+(NSError *)saveLrcLines:(nonnull NSArray <LrcLine *>*)lrcLines toFile:(nonnull NSString *)path;

@end
