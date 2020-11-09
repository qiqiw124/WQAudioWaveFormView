//
//  SMTWaveFormView.h
//  TestDemo
//
//  Created by 祺祺 on 2020/7/2.
//  Copyright © 2020 祺祺. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "SMTAudioEditTool.h"
#import "SMTAudioEditTool+Path.h"
NS_ASSUME_NONNULL_BEGIN
//展示音频，以及对音频进行展示插入操作的view

@protocol SMTWaveFormViewDelegate <NSObject>

//-(void)tapToPlayPositionFrom:(NSNumber*)left to:(NSNumber*)right;

/// 刷新宽度
/// @param widthChange 宽度
-(void)redrawRuler:(NSNumber *)widthChange;

/// 点击
/// @param viewPosition 点击的位置 x
-(void)tapClick:(NSNumber *)viewPosition;

/// 缩放
/// @param widthChange 缩放之后的宽度
-(void)scaleRuler:(NSNumber*)widthChange;

-(void)beginDrawWave;
-(void)finishDrawWave;

@end
@interface SMTWaveFormView : UIView<UIGestureRecognizerDelegate>
@property (nonatomic,strong) UIColor * waveLineColor;//横线颜色 默认黑色
@property (nonatomic,strong) UIColor * waveColor;//音频波颜色 默认蓝色
@property (nonatomic,strong) UIColor * clipViewColor;//剪切view的颜色
@property (nonatomic,strong) UIColor * pasteColor;//粘贴的部分波纹的颜色
@property (nonatomic,assign) BOOL showHorLine;//展示横线 默认不展示
@property (nonatomic,assign) BOOL isNeedRedraw;//是否需要重绘
@property (nonatomic,assign) id<SMTWaveFormViewDelegate> delegate;
@property (nonatomic,strong) SMTAudioEditTool * tool;//音频编辑工具

//必须与dialView相同，用于计算图片宽度
@property (assign, nonatomic) float factor;
@property (assign, nonatomic) CGFloat minorTickDistance;
//=====


-(void)setPanProperty;
-(void)setPlayCursor:(CGPoint)curPoint;
-(void)drawCursorAtTime:(float)progress;
-(CGRect)playPosition;

//-(void)addMark;
-(float)currentCursorPosition;
//是否支持缩放
-(void)enableScale:(BOOL)enable;

-(void)hideClipping:(BOOL)hide;
//重绘
-(void)resetViewHeightArray:(NSArray *)heithArray width:(CGFloat)waveWidth location1:(CGPoint)location1 location2:(CGPoint)location2;
//粘贴
- (void)pasteClickEvent:(void(^)(BOOL sucess,NSError * error))block;
//复制
- (void)copyClickEvent:(void(^)(BOOL sucess,NSError * error))block;
//剪切
- (void)cutClickEvent:(void(^)(BOOL sucess,NSError * error))block;
//插入音频
- (void)insertClickEvent;

-(void)releaseView;
//获取左侧local到最左边的宽度
-(CGFloat)getLeftLocationW;
@end

NS_ASSUME_NONNULL_END
