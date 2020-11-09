//
//  SMTWaveFormView.m
//  TestDemo
//
//  Created by 祺祺 on 2020/7/2.
//  Copyright © 2020 祺祺. All rights reserved.
//

#import "SMTWaveFormView.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "SMTAudioPathHeader.h"
#import "SMTSelectAlertView.h"
//#import "SMTwaveImgViewView.h"

#define absX(x) (x<0?0-x:x)
#define minMaxX(x,mn,mx) (x<=mn?mn:(x>=mx?mx:x))
#define decibel(amplitude) (25.0 * log10(absX(amplitude)/32767.0))
#define minimumOverDraw 2

@interface SMTWaveFormView()
{
    CGPoint t1Location;
    CGPoint t2Location;
//    UIImageView *cursorLine;
    int tickHeight;//距离上部的高度
    
    CGFloat _lastScale;
    CGFloat _lastTotalWidth;
    CGFloat _maxWidth;//最大宽度，用于限制缩放最大值
    int noisyFloot;
    
    UIImageView *select1Image;
    UIImageView *select2Image;
    float operationViewWidth;
    
    Float32 maximum;
    
    UInt32 channelCount;
    BOOL isNeedRedrawMarks;
    
    BOOL isMovingCursor;
    
    CGPoint _priorPoint;
    BOOL isEnableScale;
    AVAssetReader *reader;
    
}
@property (nonatomic,strong)NSMutableArray<UIImageView *> * waveImgVArray;//图片数组
@property (nonatomic,strong)NSMutableArray * imgVWidthArray;//图片宽度数组，子线程无法获得frame所以先记录下来，然后直接使用
@property (nonatomic, strong) UIView *clipping;//剪切或者拷贝时显示的覆盖view
@property (nonatomic, assign) unsigned long int totalSamples;
@property (nonatomic,assign) int targetOverDraw;
@property (nonatomic,assign) BOOL isRegionPlay;
@property (nonatomic,strong)NSMutableArray * heightArray;
@property (nonatomic,strong)NSMutableArray * operaArray;

@end


@implementation SMTWaveFormView

#pragma mark 创建
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
    _clipping = [[UIView alloc] initWithFrame:CGRectMake(0, tickHeight-15, self.frame.size.width, self.frame.size.height)];
    _clipping.clipsToBounds = YES;

    [_clipping setBackgroundColor:self.clipViewColor];
    [_clipping setAlpha:0.7];
    [self addSubview:_clipping];
    
    UILabel * cur1 = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 10, 10)];
    cur1.layer.cornerRadius = 5;
    cur1.layer.masksToBounds = YES;
    cur1.backgroundColor = RGBColor(70, 179, 141, 1);
    select1Image = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [select1Image addSubview:cur1];
    [self addSubview:select1Image];
    cur1.center = select1Image.center;
    select1Image.userInteractionEnabled = YES;
    UILabel * cur2 = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 10, 10)];
    cur2.layer.cornerRadius = 5;
    cur2.layer.masksToBounds = YES;
    cur2.backgroundColor = RGBColor(70, 179, 141, 1);
    select2Image = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [select2Image addSubview:cur2];
    cur2.center = select2Image.center;
    [self addSubview:select2Image];
    select2Image.userInteractionEnabled = YES;
    
    UILongPressGestureRecognizer *contextGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureDidFire:)];
    [self addGestureRecognizer:contextGestureRecognizer];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick:)];
    [self addGestureRecognizer:tapGestureRecognizer];
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scaleImage:)];
    [pinchRecognizer setDelegate:self];
    [self addGestureRecognizer:pinchRecognizer];
    
    _isNeedRedraw = YES;
    noisyFloot = -50;
    _targetOverDraw = 1;
    
    [select1Image setHidden:YES];
    [select2Image setHidden:YES];
    
}
-(UIImageView *)createWaveImgViewWithFrame:(CGRect)frame{
    UIImageView * waveImgV = [[UIImageView alloc] initWithFrame:frame];
    waveImgV.contentMode =  UIViewContentModeRedraw;// UIViewContentModeScaleToFill;
    [waveImgV setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    return waveImgV;
}


-(void)setPanProperty{
    UIPanGestureRecognizer *cutPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCut2Pan:)];
    [select2Image addGestureRecognizer:cutPan];

    cutPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCut2Pan:)];
    [select1Image addGestureRecognizer:cutPan];
    
}
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self setAllImgeVFrameWithTotalWidth:self.frame.size.width];
    self.totalSamples   = (unsigned long int) self.tool.audioAsset.duration.value;
    if(self.totalSamples>100000000){
        _targetOverDraw = 5;
    }
    else if(self.totalSamples>10000000){
        _targetOverDraw = 2;
    }
    
    if (self.tool.audioAsset && _isNeedRedraw) {
        _isNeedRedraw = NO;
        CGFloat widthInPixels = self.frame.size.width * _targetOverDraw;
        CGFloat heightInPixels = (self.frame.size.height-tickHeight);
        if(self.delegate && [self.delegate respondsToSelector:@selector(beginDrawWave)]){
            [self.delegate beginDrawWave];
        }
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self renderPNGAudioPictogramLogForAsset:self.tool.audioAsset
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
    
    if(t1Location.x==t2Location.x){
        if(!_isRegionPlay)
            [self.clipping setHidden:YES];
        [select1Image setHidden:YES];
        [select2Image setHidden:YES];
        
    }else{
        [self.clipping setHidden:NO];
        
        float halfCutToolWidth = select1Image.frame.size.width/2;
        
        float clippingLeft = (t1Location.x<t2Location.x?t1Location.x:t2Location.x);
        float clippingRight = fabs(t2Location.x-t1Location.x);
        CGRect clippingFrame = CGRectMake(clippingLeft, tickHeight-15,clippingRight,self.frame.size.height);
        self.clipping.frame = clippingFrame;
        
        CGRect select1Frame = CGRectMake(clippingLeft-halfCutToolWidth, tickHeight-30, 30, 30);
        [select1Image setFrame:select1Frame];
        [select1Image setHidden:NO];
        
        CGRect select2Frame = CGRectMake(clippingLeft+clippingRight-halfCutToolWidth, tickHeight-30, 30, 30);
        [select2Image setFrame:select2Frame];
        [select2Image setHidden:NO];
        CGRect menuFrame = clippingFrame;
        menuFrame.size.width/=5.00;
        menuFrame.size.height/=5.00;
        menuFrame.origin.x = menuFrame.origin.x+(clippingFrame.size.width-menuFrame.size.width)/2;
        menuFrame.origin.y = menuFrame.origin.y+(clippingFrame.size.height-menuFrame.size.height)/2;
        if(t1Location.x>t2Location.x){
            CGRect tmp = select1Image.frame;
            [select1Image setFrame:select2Image.frame];
            [select2Image setFrame:tmp];
        }
    }
    if(self.tool.delegate && [self.tool.delegate respondsToSelector:@selector(refreshBtnStatus:btnStatus:)]){
        self.tool.canCutOrCopy = !select1Image.hidden;
        [self.tool.delegate refreshBtnStatus:EditBtnStatus_CutOrCopy btnStatus:!select1Image.hidden];
        if(self.tool.canPaste == YES && select1Image.hidden){
            [self.tool.delegate refreshBtnStatus:EditBtnStatus_Paste btnStatus:YES];
        }else if (!select1Image.hidden){
            [self.tool.delegate refreshBtnStatus:EditBtnStatus_Paste btnStatus:NO];
        }
    }
}

#pragma mark - menu


-(void)hideClipping:(BOOL)hide{
    if(hide){
        t2Location = t1Location;
        if(self.tool.delegate && [self.tool.delegate respondsToSelector:@selector(refreshBtnStatus:btnStatus:)]){
            [self.tool.delegate refreshBtnStatus:EditBtnStatus_CutOrCopy btnStatus:NO];
            [self.tool.delegate refreshBtnStatus:EditBtnStatus_Paste btnStatus:self.tool.canPaste];
        }
    }
    [self.clipping setHidden:hide];
    select1Image.hidden = hide;
    select2Image.hidden = hide;
}

#pragma mark click

- (void)pasteClickEvent:(void (^)(BOOL, NSError * _Nonnull))block{
    if(t1Location.x!=t2Location.x) return;
    if(!self.tool.audioAsset) return;
    
    float leftX = t1Location.x<t2Location.x?t1Location.x:t2Location.x;
    
    float progress1 = leftX/self.frame.size.width;
    progress1 = progress1 > 1?1:progress1;
    //获取上一次的 self.waveImgView.frame.size.width
    [self.tool saveWaveHeightArray:self.heightArray waveWidth:self.frame.size.width location1:t1Location location2:t2Location];
    [self.tool pasteAudioToLocationRadio:progress1 complitBlock:^(BOOL sucess, NSError * _Nonnull error) {
        if(sucess){
            if(self.delegate && [self.delegate respondsToSelector:@selector(tapClick:)]){
                [self.delegate tapClick:@(0)];
            }else{
                
            }
            NSInteger loc = progress1 * self.heightArray.count;
            NSArray * last = [self.heightArray subarrayWithRange:NSMakeRange(loc, self.heightArray.count - loc)];
            [self.heightArray removeObjectsInRange:NSMakeRange(loc, self.heightArray.count - loc)];
            [self.heightArray addObjectsFromArray:self.operaArray];
            [self.heightArray addObjectsFromArray:last];
            self->_isNeedRedraw = NO;
            
            if(self->_delegate && [self->_delegate respondsToSelector:@selector(redrawRuler:)]){
                [self->_delegate performSelector:@selector(redrawRuler:) withObject:[NSNumber numberWithFloat:self.frame.size.width]];
            }
            [self setAllImgeVFrameWithTotalWidth:self.frame.size.width];
            self->_maxWidth = self.tool.playDuration * self.factor * self.minorTickDistance;
            [self plotLogGraph:self.heightArray mimimumValue:self->noisyFloot done:^(UIImage *imge) {
//                self.waveImgView.image = nil;
//                self.waveImgView.image = imge;
            }];
        }
        
        if(block){
            block(sucess,error);
        }
    }];
    //todo 优化
    
}

-(CGFloat)getAudioWidthForWave{
    CGFloat totalWidth = self.tool.playDuration * self.factor * self.minorTickDistance;
    NSInteger onlyWidth = (20 * 60 * self.factor * self.minorTickDistance);
    //每20分钟进行分割一次
    NSInteger count     = totalWidth / onlyWidth;
    CGFloat remainder   = totalWidth - onlyWidth * count;
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

-(void)setAllImgeVFrameWithTotalWidth:(CGFloat)totalWidth{
    if(_lastTotalWidth == totalWidth){
        return;
    }
    _lastTotalWidth = totalWidth;
    [self.imgVWidthArray removeAllObjects];
    @autoreleasepool {
        CGFloat width = [self getAudioWidthForWave];
        NSInteger onlyWidth     = (20 * 60 * self.factor * self.minorTickDistance);
        CGFloat scale = (float)(totalWidth/width);
        CGFloat scaleOnlyWidth    = scale * onlyWidth;
        NSInteger count = totalWidth/scaleOnlyWidth;
        CGFloat scaleRemainder  = totalWidth - scaleOnlyWidth * count;
        for(int i =0;i < self.waveImgVArray.count;i ++){
            UIImageView * waveImgV = self.waveImgVArray[i];
            waveImgV.frame = CGRectMake(scaleOnlyWidth * i, tickHeight,(i == self.waveImgVArray.count - 1)?scaleRemainder: scaleOnlyWidth, self.frame.size.height-tickHeight);
            [self addSubview:waveImgV];
            [self.imgVWidthArray addObject:@((i == self.waveImgVArray.count - 1)?scaleRemainder: scaleOnlyWidth)];
        }
    }
    
}



- (void)copyClickEvent:(void (^)(BOOL, NSError * _Nonnull))block{
    if(t1Location.x == t2Location.x) return;
    float leftX = t1Location.x<t2Location.x?t1Location.x:t2Location.x;
    float rightX =t1Location.x>t2Location.x?t1Location.x:t2Location.x;
    
    operationViewWidth = fabs(rightX-leftX);
    
    float progress2 = rightX/self.frame.size.width;
    progress2 = progress2 > 1? 1:progress2;
    float progress1 = leftX/self.frame.size.width;
    [self.tool copyAudioWithLeftRatio:progress1 rightRatio:progress2 complitBlock:^(BOOL sucess, NSError * _Nonnull error) {
        if(sucess){
            self.operaArray = nil;
            self.operaArray = [NSMutableArray array];
            NSInteger loc1 = progress1 * self.heightArray.count;
            NSInteger loc2 = progress2 * self.heightArray.count;
            [self.operaArray addObjectsFromArray:[self.heightArray subarrayWithRange:NSMakeRange(loc1, loc2-loc1)]];
        }
        
        if(block){
            block(sucess,error);
        }
    }];
    
    
}
- (void)cutClickEvent:(void (^)(BOOL, NSError * _Nonnull))block{
    if(t1Location.x == t2Location.x) return;
    NSLog(@"begin cut action");
    
    float leftX = t1Location.x<t2Location.x?t1Location.x:t2Location.x;
    float rightX =t1Location.x>t2Location.x?t1Location.x:t2Location.x;
    
    operationViewWidth =  rightX-leftX;
    
    float progress1 = leftX/(self.frame.size.width);
    float progress2 = rightX/(self.frame.size.width);
    progress2 = progress2 > 1? 1:progress2;
    self.operaArray = [NSMutableArray array];
    //获取上一次的
    [self.tool saveWaveHeightArray:self.heightArray waveWidth:self.frame.size.width location1:t1Location location2:t2Location];
    [self.tool cutAudioWithLeftRatio:progress1 rightRatio:progress2 complitBlock:^(BOOL sucess, NSError * _Nonnull error) {
        if(sucess){
            if(self->t1Location.x<self->t2Location.x)
                self->t2Location = self->t1Location;
               else
                   self->t1Location = self->t2Location;
            NSInteger loc1 = progress1 * self.heightArray.count;
            NSInteger loc2 = progress2 * self.heightArray.count;
            [self.operaArray addObjectsFromArray:[self.heightArray subarrayWithRange:NSMakeRange(loc1, loc2-loc1)]];
            [self.heightArray removeObjectsInRange:NSMakeRange(loc1, loc2-loc1)];
            self->_isNeedRedraw = NO;
            
            if(self->_delegate && [self->_delegate respondsToSelector:@selector(redrawRuler:)]){
                [self->_delegate performSelector:@selector(redrawRuler:) withObject:[NSNumber numberWithFloat:self.frame.size.width]];
            }
            [self setAllImgeVFrameWithTotalWidth:self.frame.size.width];
            self->_maxWidth = self.tool.playDuration * self.factor * self.minorTickDistance;
            [self plotLogGraph:self.heightArray mimimumValue:self->noisyFloot done:^(UIImage *imge) {
//                self.waveImgView.image = nil;
//                self.waveImgView.image = imge;
            }];
        }
        if(block){
            block(sucess,error);
        }
    }];
    
   
}
-(void)insertClickEvent{
    //获取上一次的
    [self.tool saveWaveHeightArray:self.heightArray waveWidth:self.frame.size.width location1:t1Location location2:t2Location];
}

// Normally a UIView doesn't want to become a first responder.  This forces the issue.
-(BOOL) canBecomeFirstResponder {
    return YES;
}

#pragma mark - tap click
// First-level of response, filters out some noise
-(void) longPressGestureDidFire:(UILongPressGestureRecognizer*)gestureRecognizer {
    if(gestureRecognizer.state == UIGestureRecognizerStateBegan) { // Only fire once
//        UIMenuController *menuController = [UIMenuController sharedMenuController];
        
        CGPoint location = [gestureRecognizer locationInView:[gestureRecognizer view]];
        CGRect targetFrame = CGRectMake(location.x, location.y, 0.0f, 0.0f);
        t1Location.x = targetFrame.origin.x;
        t2Location = t1Location;
        [self setNeedsLayout];
    }
}


-(void)tapClick:(UILongPressGestureRecognizer*)gestureRecognizer {
    isMovingCursor = NO;
    CGPoint clickPoint =[gestureRecognizer locationInView:[gestureRecognizer view]];
    
    if(clickPoint.y<tickHeight){
        t2Location = clickPoint;
    }
    else{
        _isRegionPlay = NO;
        t2Location =  t1Location =clickPoint;
        
        if(_delegate && [_delegate respondsToSelector:@selector(tapClick:)]){
            NSNumber *pos = [NSNumber numberWithFloat:t1Location.x];
            [_delegate performSelector:@selector(tapClick:) withObject:pos];
        }
    }
    
    [self setNeedsLayout];
}


- (void)scaleImage:(UIPanGestureRecognizer *)sender {
    if(!isEnableScale) return;
    UIPinchGestureRecognizer *gestureRecognizer = (UIPinchGestureRecognizer*)sender;
    if([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        _lastScale = 1.0;
    }else if([gestureRecognizer state]==UIGestureRecognizerStateChanged){
        
        CGFloat scale = 1.0 - (_lastScale - [gestureRecognizer scale]);
        if(self.frame.size.width >= _maxWidth && scale>1.0) return;
        if(self.frame.size.width <= 200 && scale<1.0) return;
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
//        NSLog(@"scale end----->self.frame.width=%f,image width=%f per:%f",self.frame.size.width,self.waveImgView.frame.size.width,self.totalSamples/wd.floatValue);
        if(_delegate && [_delegate respondsToSelector:@selector(scaleRuler:)]){
            [_delegate performSelector:@selector(scaleRuler:) withObject:wd];
        }
    }else if(UIGestureRecognizerStateCancelled==[gestureRecognizer state]){
        NSLog(@"wronnnnnnnn");
    }
}

- (void)handleCut2Pan:(UIPanGestureRecognizer *)gesture
{
    UIView *gView = gesture.view;
    CGPoint translation = [gesture translationInView:gView];
    
    if (gesture.state == UIGestureRecognizerStateBegan){
        _priorPoint = translation;
    }
    else if(gesture.state == UIGestureRecognizerStateChanged) {
        
        float ss = translation.x - _priorPoint.x;
        _priorPoint = translation;
        
        CGRect ff = gView.frame;
        ff.origin.x += ss;
        //selectImage宽度为30，所以要加一半的宽度
        if(ff.origin.x + 15 <= self.frame.size.width && ff.origin.x + 15 >= 0){
            [gView setFrame:ff];
            if([gView isEqual:select2Image]){
                t2Location.x +=ss;
            }else{
                t1Location.x+=ss;
            }
        }
        CGRect cFrame = _clipping.frame;
        cFrame.size.width+=ss;
        if(cFrame.size.width + cFrame.origin.x <= self.frame.size.width){
            [_clipping setFrame:cFrame];
        }
        
        
    }else if (gesture.state == UIGestureRecognizerStateEnded){
        //show menu
        //[self setNeedsLayout];
        
    }
    
}

- (void)handleSelectionPan:(UIPanGestureRecognizer *)gesture
{
//    CGPoint translation = [gesture translationInView:cursorLine];
    
    if (gesture.state == UIGestureRecognizerStateBegan){
//        _priorPoint = translation;
    }
    else if(gesture.state == UIGestureRecognizerStateChanged) {
        
        t2Location = t1Location;
        
    }else if (gesture.state == UIGestureRecognizerStateEnded){
        if(_delegate && [_delegate respondsToSelector:@selector(tapClick:)]){
            NSNumber *pos = [NSNumber numberWithFloat:t1Location.x];
            [_delegate performSelector:@selector(tapClick:) withObject:pos];
        }
    }
}

-(void)drawCursorAtTime:(float)progress{
    t1Location.x = self.frame.size.width*progress;
    [self setPlayCursor:t1Location];
}
/**
 绘制音波
 */
- (void) plotLogGraph:(NSArray *) samples mimimumValue:(Float32) normalizeMin done:(void(^)(UIImage * imge))done{
    // TODO: switch to a synchronous function that paints onto a given context
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
                float allDuration = self.tool.playDuration;
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

                            if(self.tool.pasteRanges.count > 0 && self.pasteColor){
                                for(SMTPasteRangeModel * rangeModel in self.tool.pasteRanges){
                                    CGFloat loc     = rangeModel.location /allDuration *(sampleCount);
                                    CGFloat length  = rangeModel.length /allDuration *(sampleCount);
                                    if(intSample + lastIndex >=loc && intSample + lastIndex <= (loc + length) && length > 0){
                                        CGContextSetStrokeColorWithColor(context, self.pasteColor.CGColor);
                                        break;
                                    }
                                }
                                
                            }
                           
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
                
            });
                
    
        }
        
           
    }
        dispatch_async(dispatch_get_main_queue(), ^{
            //再保存一次
            [self.tool saveWaveHeightArray:self.heightArray waveWidth:self.frame.size.width location1:self->t1Location location2:self->t2Location];
            
            done(nil);
        });
        
    });
}

- (void)renderPNGAudioPictogramLogForAsset:(AVURLAsset *)songAsset
                             widthInPixels:(CGFloat)widthInPixels
                            heightInPixels:(CGFloat)heightInPixels
                                      done:(void(^)(void))done
{
    // TODO: break out subsampling code
//    NSLog(@"self.frame.size.with:%f",self.frame.size.width);
   
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
                                        //     [NSNumber numberWithInt:44100.0],AVSampleRateKey, /*Not Supported*/
                                        //     [NSNumber numberWithInt: 2],AVNumberOfChannelsKey,    /*Not Supported*/
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
    // Something went wrong. Handle it.
    if (reader.status == AVAssetReaderStatusCompleted){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self plotLogGraph:self.heightArray mimimumValue:self->noisyFloot done:^(UIImage *imge) {
//                self.waveImgView.image = nil;
//                self.waveImgView.image = imge;
                done();
            }];
            
        });
    }
    
}



#pragma mark 属性相关

-(void)resetViewHeightArray:(NSArray *)heithArray width:(CGFloat)waveWidth location1:(CGPoint)location1 location2:(CGPoint)location2{
    if(heithArray.count == 0){
        _isNeedRedraw = YES;
        [self setNeedsLayout];
    }else{
        self.heightArray = [NSMutableArray arrayWithArray:heithArray];

        if(self->_delegate && [self->_delegate respondsToSelector:@selector(redrawRuler:)]){
            [self->_delegate performSelector:@selector(redrawRuler:) withObject:[NSNumber numberWithFloat:self.frame.size.width]];
        }
        [self setAllImgeVFrameWithTotalWidth:self.frame.size.width];
        [self plotLogGraph:self.heightArray mimimumValue:self->noisyFloot done:^(UIImage *imge) {
//            self.waveImgView.image = nil;
//            self.waveImgView.image = imge;
        }];
    }
    
}
-(CGRect)playPosition{
    float pos = t1Location.x<t2Location.x?t1Location.x:t2Location.x;
    float length = fabs(t1Location.x-t2Location.x);
    return CGRectMake(pos, 0, length, self.frame.size.height);
}

-(void)setTool:(SMTAudioEditTool *)tool{
    _tool = tool;
    
}
-(void)setPlayCursor:(CGPoint)curPoint{
    if(self.clipping.hidden == YES){
        t2Location = t1Location = curPoint;
    }
    [self setNeedsLayout];
}

-(void)enableScale:(BOOL)enable{
    isEnableScale = enable;
}
-(float)currentCursorPosition{
    return t1Location.x;
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
-(UIColor *)clipViewColor{
    if(!_clipViewColor){
        _clipViewColor = RGBColor(227, 232, 235, 1);
    }
    return _clipViewColor;
}
-(NSMutableArray *)heightArray{
    if(!_heightArray){
        _heightArray = [NSMutableArray array];
    }
    return _heightArray;
}
-(void)dealloc{
    [self.heightArray removeAllObjects];

    [_clipping removeFromSuperview];
    [select1Image removeFromSuperview];
    [select2Image removeFromSuperview];

}
-(void)releaseView{
    [reader cancelReading];
}
//获取左侧local到最左边的宽度
-(CGFloat)getLeftLocationW{
    return t1Location.x;
}
@end
