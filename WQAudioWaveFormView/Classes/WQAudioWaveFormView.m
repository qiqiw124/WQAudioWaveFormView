//
//  WQAudioWaveFormView.m
//  WQAudioWaveFormView_Example
//
//  Created by 祺祺 on 2020/11/9.
//  Copyright © 2020 01810452. All rights reserved.
//

#import "WQAudioWaveFormView.h"
#import <WQWaveFormView.h>
#import <WQDialScrollView.h>
@interface WQAudioWaveFormView()<WQWaveFormViewDelegate>
@property(nonatomic,strong)WQDialScrollView * dialView;
@property(nonatomic,strong)WQWaveFormView   * waveform;
@property(nonatomic,strong)AVURLAsset * audioAsset;
@end

@implementation WQAudioWaveFormView

-(instancetype)initWithFrame:(CGRect)frame audiAsset:(nonnull AVURLAsset *)audioAsset{
    if(self = [super initWithFrame:frame]){
        self.audioAsset = audioAsset;
        [self createMainView];
    }
    return self;
}
-(void)createMainView{
    _dialView = [[WQDialScrollView alloc] initWithFrame:self.bounds];
    float duration          = CMTimeGetSeconds(self.audioAsset.duration);
    //计算scrollview中的时间刻度显示
    [self setPropertyWithDuration:duration];
    _dialView.leading       = 20;
    [self addSubview:_dialView];
    
    int width = [_dialView contentSize].width;
    _waveform = [[WQWaveFormView alloc] initWithFrame:CGRectMake(0, 0, width, self.bounds.size.height)];
    _waveform.waveColor     = [UIColor greenColor];
    _waveform.waveLineColor = [UIColor blackColor];
    _waveform.audioAsset    = self.audioAsset;
    _waveform.delegate      = self;
    _waveform.factor        = 10;
    _waveform.minorTickDistance = 10;
    [_waveform enableScale:YES];
    [_dialView insertWaveView:_waveform];
    
}
-(void)beginDrawView{
    [_dialView redrawView];
}



//重新计算scrollview中的时间刻度显示
-(void)setPropertyWithDuration:(float)duration{
    [_dialView initFactor:10];
    [_dialView setDialRangeFrom:0 to:duration];
}

#pragma mark WaveformDelegate
-(void)scaleRuler:(NSNumber *)widthChange{
    [_dialView resetDialViewWidth:[widthChange floatValue]];
    [_dialView redrawView];
}
-(void)redrawRuler:(NSNumber *)widthChange{
    [self setPropertyWithDuration:CMTimeGetSeconds(self.audioAsset.duration)];
    [_dialView redrawView];
    
    float marginLeft = _dialView.leading;
    int width = [_dialView dialViewWidth];
    
    [self.waveform setFrame:CGRectMake(marginLeft,0, width, self.waveform.frame.size.height)];
    [self.waveform setNeedsLayout];

}




@end
