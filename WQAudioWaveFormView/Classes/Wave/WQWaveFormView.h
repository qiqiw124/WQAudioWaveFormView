//
//  WQWaveFormView.h
//  TestDemo
//
//  Created by wqq on 2020/7/2.
//  Copyright © 2020 wqq. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN
//展示音频

@protocol WQWaveFormViewDelegate <NSObject>


/// 刷新宽度
/// @param widthChange 宽度
-(void)redrawRuler:(NSNumber *)widthChange;

/// 缩放
/// @param widthChange 缩放之后的宽度
-(void)scaleRuler:(NSNumber*)widthChange;

-(void)beginDrawWave;
-(void)finishDrawWave;

@end
@interface WQWaveFormView : UIView<UIGestureRecognizerDelegate>
@property (nonatomic,strong) UIColor * waveLineColor;//横线颜色 默认黑色
@property (nonatomic,strong) UIColor * waveColor;//音频波颜色 默认蓝色
@property (nonatomic,assign) BOOL showHorLine;//展示横线 默认不展示
@property (nonatomic,assign) BOOL isNeedRedraw;//是否需要重绘
@property (nonatomic,assign) id<WQWaveFormViewDelegate> delegate;
@property (nonatomic,strong) AVURLAsset * audioAsset;

//必须与dialView相同，用于计算图片宽度
@property (assign, nonatomic) float factor;
@property (assign, nonatomic) CGFloat minorTickDistance;
//=====

//是否支持缩放
-(void)enableScale:(BOOL)enable;

-(void)releaseView;
@end

NS_ASSUME_NONNULL_END
