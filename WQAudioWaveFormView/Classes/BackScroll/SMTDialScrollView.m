//
//  SMTDialScrollView.m
//  TestDemo
//
//  Created by 祺祺 on 2020/7/2.
//  Copyright © 2020 祺祺. All rights reserved.
//

#import "SMTDialScrollView.h"
#import "SMTDialView.h"

@interface SMTDialScrollView()<UIScrollViewDelegate> {
    
    float _currentValue;
    float factor;
    float _lastScaleRate;//上次缩放比例
}
@property (assign, nonatomic) float min;
@property (assign, nonatomic) float max;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIView *overlayView;
@property (strong, nonatomic) SMTDialView *dialView;
@end

@implementation SMTDialScrollView


- (void)commonInit
{
    _max = 0;
    _min = 0;
    factor = 1;
    float contentHeight = self.bounds.size.height;
    
    _overlayView = [[UIView alloc] initWithFrame:self.bounds];
    [_overlayView setUserInteractionEnabled:NO];
    
    // Set the default frame size
    // Don't worry, we will be changing this later
    _dialView = [[SMTDialView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, contentHeight)];
    _dialView.leading = self.bounds.size.width/2;
    // Don't let the container handle User Interaction
    [_dialView setUserInteractionEnabled:NO];
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    
    // Disable scroll bars
    [_scrollView setShowsHorizontalScrollIndicator:YES];
    [_scrollView setClipsToBounds:YES];
    _scrollView.contentSize = CGSizeMake(_dialView.frame.size.width, contentHeight);
    _scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 3);
    
    
    // Setup the ScrollView
    [_scrollView setBounces:NO];
    [_scrollView setBouncesZoom:NO];
    _scrollView.delegate = self;

    [_scrollView addSubview:_dialView];
    [self addSubview:_scrollView];
    [self addSubview:_overlayView];
    
    // Clips the Dial View to the bounds of this view
    self.clipsToBounds = YES;

}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self commonInit];
    }
    
    return self;
}


- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self) {

        [self commonInit];
    }
    
    return self;
}

#pragma mark - Methods
-(void)initFactor:(float)_factor{
    factor = _factor;
}
- (void)setDialRangeFrom:(float)from to:(float)to {
    
    self.min = from;
    self.max = to*factor;
    [self.dialView initFactor:factor];
    CGFloat width = 0;
    if(_lastScaleRate > 0){//根据上次比率缩放
        width = _lastScaleRate * (self.max-self.min) * self.dialView.minorTickDistance;
    }
    // Update the dial view
    [self.dialView setDialRangeFrom:from to:self.max width:width];
    
    self.scrollView.contentSize = CGSizeMake(self.dialView.frame.size.width, self.bounds.size.height);
}
-(void)redrawView{
    [self.dialView redrawView];
    
}
- (CGPoint)scrollToOffset:(CGPoint)starting {
    
    // Initialize the end point with the starting position
    CGPoint ending = starting;
    
    // Calculate the ending offset
    ending.x = roundf(starting.x / self.minorTickDistance) * self.minorTickDistance;
    
//    NSLog(@"starting=%f, ending=%f", starting.x, ending.x);
    
    return ending;
}

#pragma mark - UIScrollViewDelegate

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([super respondsToSelector:aSelector])
        return YES;
    
    if ([self.delegate respondsToSelector:aSelector])
        return YES;
    
    return NO;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([self.delegate respondsToSelector:aSelector])
        return self.delegate;

    // Always call parent object for default
    return [super forwardingTargetForSelector:aSelector];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {
    
    // Make sure that we scroll to the nearest tick mark on the dial.
    *targetContentOffset = [self scrollToOffset:(*targetContentOffset)];
    
    if ([self.delegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)])
        
        [self.delegate scrollViewWillEndDragging:scrollView
                                    withVelocity:velocity
                             targetContentOffset:targetContentOffset];
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if([self.delegate respondsToSelector:@selector(scrollViewDidScroll:)]){
        [self.delegate scrollViewDidScroll:scrollView];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchBegan");
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesCancelled");
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesEnded");
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesMoved");
}

#pragma mark - Properties

- (void)setMinorTicksPerMajorTick:(NSInteger)minorTicksPerMajorTick
{
    self.dialView.minorTicksPerMajorTick = minorTicksPerMajorTick;
}

- (NSInteger)minorTicksPerMajorTick
{
    return self.dialView.minorTicksPerMajorTick;
}

- (void)setMinorTickDistance:(NSInteger)minorTickDistance
{
    self.dialView.minorTickDistance = minorTickDistance;
}

- (NSInteger)minorTickDistance
{
    return self.dialView.minorTickDistance;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    self.dialView.backColor = backgroundColor;
}

- (UIColor *)backgroundColor
{
    return self.dialView.backColor;
}

- (void)setLabelStrokeColor:(UIColor *)labelStrokeColor
{
    self.dialView.labelStrokeColor = labelStrokeColor;
}

- (UIColor *)labelStrokeColor
{
    return self.dialView.labelStrokeColor;
}

- (void)setLabelFillColor:(UIColor *)labelFillColor
{
    self.dialView.labelFillColor = labelFillColor;
}

- (void)setLabelStrokeWidth:(CGFloat)labelStrokeWidth
{
    self.dialView.labelStrokeWidth = labelStrokeWidth;
}

- (CGFloat)labelStrokeWidth
{
    return self.dialView.labelStrokeWidth;
}

- (UIColor *)labelFillColor
{
    return self.dialView.labelFillColor;
}

- (void)setLabelFont:(UIFont *)labelFont
{
    self.dialView.labelFont = labelFont;
}

- (UIFont *)labelFont
{
    return self.dialView.labelFont;
}

- (void)setMinorTickColor:(UIColor *)minorTickColor
{
    self.dialView.minorTickColor = minorTickColor;
}

- (UIColor *)minorTickColor
{
    return self.dialView.minorTickColor;
}

- (void)setMinorTickLength:(CGFloat)minorTickLength
{
    self.dialView.minorTickLength = minorTickLength;
}

- (CGFloat)minorTickLength
{
    return self.dialView.minorTickLength;
}

- (void)setMinorTickWidth:(CGFloat)minorTickWidth
{
    self.dialView.minorTickWidth = minorTickWidth;
}

- (CGFloat)minorTickWidth
{
    return self.dialView.minorTickWidth;
}

- (void)setMajorTickColor:(UIColor *)majorTickColor
{
    self.dialView.majorTickColor = majorTickColor;
}

- (UIColor *)majorTickColor
{
    return self.dialView.majorTickColor;
}

- (void)setMajorTickLength:(CGFloat)majorTickLength
{
    self.dialView.majorTickLength = majorTickLength;
}

- (CGFloat)majorTickLength
{
    return self.dialView.majorTickLength;
}

- (void)setMajorTickWidth:(CGFloat)majorTickWidth
{
    self.dialView.majorTickWidth = majorTickWidth;
}

- (CGFloat)majorTickWidth
{
    return self.dialView.majorTickWidth;
}

- (void)setShadowColor:(UIColor *)shadowColor
{
    self.dialView.shadowColor = shadowColor;
}

- (UIColor *)shadowColor
{
    return self.dialView.shadowColor;
}

- (void)setShadowOffset:(CGSize)shadowOffset
{
    self.dialView.shadowOffset = shadowOffset;
}

- (CGSize)shadowOffset
{
    return self.dialView.shadowOffset;
}

- (void)setShadowBlur:(CGFloat)shadowBlur
{
    self.dialView.shadowBlur = shadowBlur;
}

- (CGFloat)shadowBlur
{
    return self.dialView.shadowBlur;
}

- (void)setOverlayColor:(UIColor *)overlayColor
{
    self.overlayView.backgroundColor = overlayColor;
}

- (UIColor *)overlayColor
{
    return self.overlayColor;
}

- (void)setCurrentValue:(float)newValue {
    // Check to make sure the value is within the available range
    if ((newValue < _min) || (newValue > _max))
        _currentValue = _min;
    else
        _currentValue = newValue;
//    NSLog(@"current value=%f,new value:%f factor=%f",_currentValue,newValue,factor);
    
    // Update the content offset based on new value
    CGPoint offset = self.scrollView.contentOffset;

    offset.x = (newValue - self.dialView.minimum) * self.dialView.minorTickDistance;

    self.scrollView.contentOffset = offset;
}
-(void)setOffset:(float)offsetx currentValue:(float)newValue{
    if ((newValue < _min) || (newValue > _max))
        _currentValue = _min;
    else
        _currentValue = newValue;    // Update the content offset based on new value
    CGPoint offset = self.scrollView.contentOffset;
    
    offset.x = offsetx;//(newValue - self.dialView.minimum) * self.dialView.minorTickDistance;
//    NSLog(@"offset x=%f",offset.x);
    [self.scrollView setContentOffset:offset animated:NO];
    [self scrollViewDidScroll:self.scrollView];
}


- (float)currentValue
{
    return roundf(self.scrollView.contentOffset.x / self.dialView.minorTickDistance/factor) + self.dialView.minimum;
}

-(void)insertWaveView:(UIView *)waveView{
    CGRect ff = waveView.frame;
    ff.origin.x = self.dialView.leading;
    ff.size.width -=self.dialView.leading * 2;
    waveView.frame = ff;
    [self.scrollView addSubview:waveView];
}
-(CGSize)contentSize{
    return self.scrollView.contentSize;
}
-(CGPoint)contentOffset{
    return self.scrollView.contentOffset;
}
-(NSInteger)leading{
    return self.dialView.leading;
}
-(float)dialViewWidth{
    float ww = self.dialView.frame.size.width-self.dialView.leading*2;

    return ww;
}
-(void)resetDialViewWidth:(float)waveWidth{
//    float minidistance = waveWidth/(self.max-self.min);

//    self.dialView.minorTickDistance = minidistance;
    [self.dialView setDialRangeFrom:self.min to:self.max width:waveWidth];
    //记录此次缩放比率,用于编辑时根据此比率缩放
    _lastScaleRate = (float)(waveWidth/((self.max - self.min) * self.dialView.minorTickDistance));
    self.scrollView.contentSize = CGSizeMake(self.dialView.frame.size.width, self.bounds.size.height);
    [self.dialView setNeedsDisplay];

}
@end
