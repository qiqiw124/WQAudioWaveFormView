//
//  WQWaveFormView.m
//  TestDemo
//
//  Created by wqq on 2020/7/2.
//  Copyright © 2020 wqq. All rights reserved.
//

#import "WQWaveFormView.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>

#define absX(x) (x<0?0-x:x)
#define minMaxX(x,mn,mx) (x<=mn?mn:(x>=mx?mx:x))
#define decibel(amplitude) (25.0 * log10(absX(amplitude)/32767.0))

@interface WQWaveFormView()
{
    int tickHeight;//距离上部的高度
    
    CGFloat _lastScale;
    CGFloat _lastTotalWidth;
    CGFloat _maxWidth;//最大宽度，用于限制缩放最大值
    int noisyFloot;
    float operationViewWidth;
    
    Float32 maximum;
    
    UInt32 channelCount;
    BOOL isEnableScale;
    AVAssetReader *reader;
    
}
@property (nonatomic,strong)NSMutableArray<UIImageView *> * waveImgVArray;//图片数组
@property (nonatomic,strong)NSMutableArray * imgVWidthArray;//图片宽度数组，子线程无法获得frame所以先记录下来，然后直接使用
@property (nonatomic, assign) unsigned long int totalSamples;
@property (nonatomic,assign) int targetOverDraw;
@property (nonatomic,strong)NSMutableArray * heightArray;

@end


@implementation WQWaveFormView

#pragma mark 创建

- (id)initWithCoder:(NSCoder *)aCoder
{
    if (self = [super initWithCoder:aCoder])
        [self initialize];
    return self;
}

- (id)initWithFrame:(CGRect)rect
{
    if (self = [super initWithFrame:rect]){
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    tickHeight = 53;
    isEnableScale = YES;
    
    [self setAllImgeVFrameWithTotalWidth:self.frame.size.width];
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scaleImage:)];
    [pinchRecognizer setDelegate:self];
    [self addGestureRecognizer:pinchRecognizer];
    
    _isNeedRedraw = YES;
    noisyFloot = -50;
    _targetOverDraw = 1;
    
    
}
-(UIImageView *)createWaveImgViewWithFrame:(CGRect)frame{
    UIImageView * waveImgV = [[UIImageView alloc] initWithFrame:frame];
    waveImgV.contentMode =  UIViewContentModeRedraw;// UIViewContentModeScaleToFill;
    [waveImgV setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    return waveImgV;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self setAllImgeVFrameWithTotalWidth:self.frame.size.width];
    self.totalSamples   = (unsigned long int) self.audioAsset.duration.value;
    if(self.totalSamples>100000000){
        _targetOverDraw = 5;
    }
    else if(self.totalSamples>10000000){
        _targetOverDraw = 2;
    }
    
    CGFloat widthInPixels = self.frame.size.width * _targetOverDraw;
    CGFloat heightInPixels = (self.frame.size.height-tickHeight);
    if(self.delegate && [self.delegate respondsToSelector:@selector(beginDrawWave)]){
        [self.delegate beginDrawWave];
    }
    if(_isNeedRedraw){
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self renderPNGAudioPictogramLogForAsset:self.audioAsset
                                       widthInPixels:widthInPixels
                                      heightInPixels:heightInPixels
                                                done:^(void) {
                        if(self->_delegate && [self->_delegate respondsToSelector:@selector(redrawRuler:)]){
                            [self->_delegate performSelector:@selector(redrawRuler:) withObject:[NSNumber numberWithFloat:self.frame.size.width]];
                        }
                self->_maxWidth = [self getAudioWidthForWave];
                        if(self.delegate && [self.delegate respondsToSelector:@selector(finishDrawWave)]){
                            [self.delegate finishDrawWave];
                        }
                        
                        NSLog(@"end cut action");
            }];
        });
    }
    _isNeedRedraw = NO;
}


/**
 计算需要几个imgView
 */
-(CGFloat)getAudioWidthForWave{
    CGFloat totalWidth = CMTimeGetSeconds(self.audioAsset.duration) * self.factor * self.minorTickDistance;
    NSInteger onlyWidth = (20 * 60 * self.factor * self.minorTickDistance);
    //每20分钟进行分割一次
    NSInteger count     = totalWidth / onlyWidth;
    CGFloat remainder   = totalWidth - onlyWidth * count;//余数 不到20分钟
    NSMutableArray * imgVs = [NSMutableArray array];
    if(count > 0 && remainder > 0 && count + 1 - self.waveImgVArray.count > 0){
        for(int i = 0;i < count+1 - self.waveImgVArray.count;i ++){
            UIImageView * imgV = [self createWaveImgViewWithFrame:CGRectZero];
            [imgVs addObject:imgV];
        }
        [self.waveImgVArray addObjectsFromArray:imgVs];
    }
    if(remainder>0){
        if(self.waveImgVArray.count > count + 1){
            [self.waveImgVArray removeObjectsInRange:NSMakeRange(count+1, self.waveImgVArray.count - (count + 1))];
        }else if(self.waveImgVArray.count < count + 1){
            UIImageView * imgV = [self createWaveImgViewWithFrame:CGRectZero];
            [self.waveImgVArray addObject:imgV];
        }
    }else{
        if(self.waveImgVArray.count > count){
            NSArray * array = [self.waveImgVArray subarrayWithRange:NSMakeRange(count+1, self.waveImgVArray.count - count)];
            for(UIImageView * imgV in array){
                [imgV removeFromSuperview];
                [self.waveImgVArray removeObject:imgV];
            }
        }
    }
    return totalWidth;
}


/**
 重新设置各个imgView的宽度
 @param totalWidth 总宽度
 */
-(void)setAllImgeVFrameWithTotalWidth:(CGFloat)totalWidth{
    if(_lastTotalWidth == totalWidth){
        return;
    }
    _lastTotalWidth = totalWidth;
    [self.imgVWidthArray removeAllObjects];
    @autoreleasepool {
        CGFloat width           = [self getAudioWidthForWave];
        NSInteger onlyWidth     = (20 * 60 * self.factor * self.minorTickDistance);
        CGFloat scale           = (float)(totalWidth/width);
        CGFloat scaleOnlyWidth  = scale * onlyWidth;
        NSInteger count         = totalWidth/scaleOnlyWidth;
        CGFloat scaleRemainder  = totalWidth - scaleOnlyWidth * count;
        for(int i =0;i < self.waveImgVArray.count;i ++){
            UIImageView * waveImgV = self.waveImgVArray[i];
            waveImgV.frame = CGRectMake(scaleOnlyWidth * i, tickHeight,(i == self.waveImgVArray.count - 1)?scaleRemainder: scaleOnlyWidth, self.frame.size.height-tickHeight);
            [self addSubview:waveImgV];
            [self.imgVWidthArray addObject:@((i == self.waveImgVArray.count - 1)?scaleRemainder: scaleOnlyWidth)];
        }
    }
    
}


// Normally a UIView doesn't want to become a first responder.  This forces the issue.
-(BOOL) canBecomeFirstResponder {
    return YES;
}

#pragma mark - tap click

- (void)scaleImage:(UIPanGestureRecognizer *)sender {
    if(!isEnableScale) return;
    UIPinchGestureRecognizer *gestureRecognizer = (UIPinchGestureRecognizer*)sender;
    if([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        _lastScale = 1.0;
    }else if([gestureRecognizer state]==UIGestureRecognizerStateChanged){
        
        CGFloat scale = 1.0 - (_lastScale - [gestureRecognizer scale]);
        if(self.frame.size.width >= _maxWidth && scale>1.0) return;//最大不超过起始宽度
        if(self.frame.size.width <= 200 && scale<1.0) return;//最小不小于200
        for(UIImageView * imgV in self.waveImgVArray){
            @autoreleasepool {
                float lastImageWidth = imgV.frame.size.width;
                
                CGAffineTransform currentTransform = imgV.transform;
                imgV.transform = CGAffineTransformIdentity;
                
                CGAffineTransform newTransform = CGAffineTransformScale(currentTransform, scale, scale);
                [imgV setTransform:newTransform];
                
                UIScrollView *pscroll = ((UIScrollView*)self.superview);
                float minuxWidth = imgV.frame.size.width-lastImageWidth;
                CGSize cSize = pscroll.contentSize;
                cSize.width += minuxWidth+1;// self.image.frame.size.width+pscroll.superview.frame.size.width/2;
                [pscroll setContentSize:cSize];
                
                CGRect selfFrame = self.frame;
                selfFrame.size.width += minuxWidth;// self.image.frame.size.width;
                [self setFrame:selfFrame];
            }
            
        }
        

        _lastScale = [(UIPinchGestureRecognizer*)sender scale];
        
    }else if(UIGestureRecognizerStateEnded ==[gestureRecognizer state] ){
        NSNumber *wd = [NSNumber numberWithFloat: self.frame.size.width];
        if(_delegate && [_delegate respondsToSelector:@selector(scaleRuler:)]){
            [_delegate performSelector:@selector(scaleRuler:) withObject:wd];
        }
    }else if(UIGestureRecognizerStateCancelled==[gestureRecognizer state]){
        NSLog(@"wronnnnnnnn");
    }
}

/**
 绘制音波
 */
- (void) plotLogGraph:(NSArray *) samples
         mimimumValue:(Float32) normalizeMin
                 done:(void(^)(UIImage * imge))done{
    NSLog(@"begin ploglogGraph");
    NSInteger sampleCount = samples.count;
    CGFloat imageHeight = (self.frame.size.height - tickHeight);
    NSInteger space = 1;//space是每隔space的index从samples中取值进行绘制
    CGFloat supWidth = self.frame.size.width;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    NSInteger lastIndex = 0;
    for(int i=0;i < self.waveImgVArray.count;i ++){
        @autoreleasepool {
            CGFloat imgVWidth = [self.imgVWidthArray[i]floatValue];
            CGFloat imgeWidth = sampleCount * imgVWidth/supWidth;
   
                CGSize imageSize    = CGSizeMake(imgeWidth, imageHeight);
                if(lastIndex + imgeWidth >= sampleCount){
                    imgeWidth = sampleCount - lastIndex;
                }
                NSArray * currentSamples = [samples subarrayWithRange:NSMakeRange(lastIndex, imgeWidth)];
                
                UIGraphicsBeginImageContext(imageSize); // this is leaking memory?
                CGContextRef context = UIGraphicsGetCurrentContext();
                CGContextSetAlpha(context,1.0);
                CGContextSetLineWidth(context, 2.0);

                float halfGraphHeight = (imageHeight / 2);
                float centerLeft = halfGraphHeight;
                float minus =(self->maximum - self->noisyFloot);
                if(minus<=0){
                    minus=0.001;
                }
                float sampleAdjustmentFactor = imageHeight / minus / 4;
                for (NSInteger intSample=0; intSample<currentSamples.count; intSample += space) {
                   
                    @autoreleasepool {
                        if(intSample%3 == 0){
                            Float32 sample = (Float32)([currentSamples[intSample] floatValue]);
                            if(!sample) { NSLog(@"wrong wrong------"); break;}
                            float pixels = (sample - self->noisyFloot) * sampleAdjustmentFactor;
                            CGContextMoveToPoint(context, intSample/space, centerLeft-pixels);
                            CGContextAddLineToPoint(context, intSample/space, centerLeft+pixels);
                            CGContextStrokePath(context);
                            CGContextSetStrokeColorWithColor(context, self.waveColor.CGColor);

                           
                        }
                    }
                }
                lastIndex = lastIndex + currentSamples.count;
                 
                 
                 //draw line
                 if(self.showHorLine){
                     [self.waveLineColor setStroke];
                     float pixels = (-16.0 - self->noisyFloot) * sampleAdjustmentFactor;
                     [[UIColor colorWithWhite:0.8 alpha:1.0] setFill];
                     UIBezierPath *line = [UIBezierPath bezierPath];
                     [line moveToPoint:CGPointMake(0, centerLeft-pixels)];
                     [line addLineToPoint:CGPointMake(imageSize.width, centerLeft-pixels)];
                     [line setLineWidth:1.0];
                     [line stroke];
                     //center line
                     [line moveToPoint:CGPointMake(0, centerLeft)];
                     [line addLineToPoint:CGPointMake(imageSize.width, centerLeft)];
                     [line setLineWidth:1.0];
                     [line stroke];

                     [line moveToPoint:CGPointMake(0, centerLeft+pixels)];
                     [line addLineToPoint:CGPointMake(imageSize.width, centerLeft+pixels)];
                     [line setLineWidth:1.0];
                     [line stroke];
                    
                 }
                 //end draw line
                UIImage *image1 = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            dispatch_async(dispatch_get_main_queue(), ^{
            self.waveImgVArray[i].image = image1;
                done(nil);
            });
                
    
        }
        
           
    }
        
    });
}

- (void)renderPNGAudioPictogramLogForAsset:(AVURLAsset *)songAsset
                             widthInPixels:(CGFloat)widthInPixels
                            heightInPixels:(CGFloat)heightInPixels
                                      done:(void(^)(void))done
{

    if(_heightArray){
        _heightArray = nil;
    }
    NSError *error = nil;
    [reader cancelReading];
    reader = nil;
    reader = [[AVAssetReader alloc] initWithAsset:songAsset error:&error];
    if(songAsset.tracks.count == 0){//读取错误，一般为文件不完整
        done();
        return;
    }
    AVAssetTrack *songTrack = [songAsset.tracks objectAtIndex:0];
    
    NSDictionary *outputSettingsDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                                
                                        [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsNonInterleaved,
                                        nil];
    AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc] initWithTrack:songTrack outputSettings:outputSettingsDict];
    [reader addOutput:output];
    
    NSArray *formatDesc = songTrack.formatDescriptions;
    for(unsigned int i = 0; i < [formatDesc count]; ++i) {
        CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:i];
        const AudioStreamBasicDescription* fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item);
        if (!fmtDesc) return; //!
        channelCount = fmtDesc->mChannelsPerFrame;
    }
//    
    UInt32 bytesPerInputSample = 2 * channelCount;
    maximum = noisyFloot;
    Float64 tally = 0;
    Float32 tallyCount = 0;
    NSInteger downsampleFactor = self.totalSamples / widthInPixels;
    downsampleFactor = downsampleFactor<1 ? 1 : downsampleFactor;

    [reader startReading];
    while (reader.status == AVAssetReaderStatusReading) {
        @autoreleasepool {
            AVAssetReaderTrackOutput * trackOutput = (AVAssetReaderTrackOutput *)[reader.outputs objectAtIndex:0];
            CMSampleBufferRef sampleBufferRef = [trackOutput copyNextSampleBuffer];
            if (sampleBufferRef) {
                CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef);
                size_t bufferLength = CMBlockBufferGetDataLength(blockBufferRef);
                NSMutableData * data = [NSMutableData dataWithLength:bufferLength];
                CMBlockBufferCopyDataBytes(blockBufferRef, 0, bufferLength, data.mutableBytes);

                SInt16 *samples = (SInt16 *)data.mutableBytes;
                long sampleCount = bufferLength / bytesPerInputSample;
                for (int i=0; i<sampleCount; i++) {
                    Float32 sample = (Float32) *samples++;
                    sample = decibel(sample);
                    sample = minMaxX(sample,noisyFloot,0);
                    tally += sample;
                    tallyCount++;

                    if (tallyCount == downsampleFactor) {
                        sample = tally / tallyCount;//平均值
                        maximum = maximum > sample ? maximum : sample;
                        tally = 0;
                        tallyCount = 0;
                        [self.heightArray addObject:@(sample)];
                    }
                }
                CMSampleBufferInvalidate(sampleBufferRef);
                CFRelease(sampleBufferRef);
                data =nil;
            }
        }
    }
    if (reader.status == AVAssetReaderStatusCompleted){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self plotLogGraph:self.heightArray mimimumValue:self->noisyFloot done:^(UIImage *imge) {
                done();
            }];
            
        });
    }
    
}


-(void)enableScale:(BOOL)enable{
    isEnableScale = enable;
}

-(UIColor *)waveLineColor{
    if(!_waveLineColor){
        _waveLineColor = [UIColor blackColor];
    }
    return _waveLineColor;
}
-(UIColor *)waveColor{
    if(!_waveColor){
        _waveColor = [UIColor blueColor];
    }
    return _waveColor;
}

-(void)dealloc{
    [self.heightArray removeAllObjects];

}
-(void)releaseView{
    [reader cancelReading];
}

-(NSMutableArray *)heightArray{
    if(!_heightArray){
        _heightArray = [NSMutableArray array];
    }
    return _heightArray;
}
-(NSMutableArray *)imgVWidthArray{
    if(!_imgVWidthArray){
        _imgVWidthArray = [NSMutableArray array];
    }
    return _imgVWidthArray;
}
-(NSMutableArray<UIImageView *> *)waveImgVArray{
    if(!_waveImgVArray){
        _waveImgVArray = [NSMutableArray array];
    }
    return _waveImgVArray;
}
@end
