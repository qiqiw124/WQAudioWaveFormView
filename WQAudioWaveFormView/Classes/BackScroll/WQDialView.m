//
//  WQDialView.m
//  TestDemo
//
//  Created by wqq on 2020/7/2.
//  Copyright © 2020 wqq. All rights reserved.
//

#import "WQDialView.h"
NSString * const kTRSDialViewDefaultFont = @"HelveticaNeue";

const NSInteger kTRSDialViewDefautLabelFontSize = 11;

const CGFloat kTRSDialViewDefaultMinorTickDistance = 10.0f;
const CGFloat kTRSDialViewDefaultMinorTickLength   = 10.0f;
const CGFloat KTRSDialViewDefaultMinorTickWidth    =  1.0f;

const NSInteger kTRSDialViewDefaultMajorTickDivisions = 10;
const CGFloat kTRSDialViewDefaultMajorTickLength      = 15.0f;
const CGFloat kTRSDialViewDefaultMajorTickWidth       = 4.0f;

@interface WQDialView ()
@property(nonatomic,strong)CAShapeLayer * masLayer;
@property(nonatomic,strong)UIBezierPath * bezier;
@property(nonatomic,strong)NSMutableArray * labArray;
@end

@implementation WQDialView
static NSInteger labIndex = 0;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        _minimum = 0;
        _maximum = 0;
        _factor = 1;
        
        _minorTicksPerMajorTick = kTRSDialViewDefaultMajorTickDivisions;
        _minorTickDistance = kTRSDialViewDefaultMinorTickDistance;

        _backColor = [UIColor lightGrayColor];

        _labelStrokeColor = [UIColor colorWithRed:0.482 green:0.008 blue:0.027 alpha:1.000];
        _labelFillColor = [UIColor whiteColor];
        _labelStrokeWidth = 1.0;

        _labelFont = [UIFont fontWithName:kTRSDialViewDefaultFont
                                     size:kTRSDialViewDefautLabelFontSize];

        _minorTickColor = [UIColor colorWithWhite:0.158 alpha:1.000];
        _minorTickLength = kTRSDialViewDefaultMinorTickLength;
        _minorTickWidth = KTRSDialViewDefaultMinorTickWidth;

        _majorTickColor = [UIColor colorWithRed:0.482 green:0.008 blue:0.027 alpha:1.000];
        _majorTickLength = kTRSDialViewDefaultMajorTickLength;
        _majorTickWidth = kTRSDialViewDefaultMajorTickWidth;

        _shadowColor = [UIColor colorWithWhite:1.000 alpha:1.000];
        _shadowOffset = CGSizeMake(1, 1);
        _shadowBlur = 0.9f;

    }

    return self;
}
-(void)initFactor:(float)thefactor{
    self.factor = thefactor;
    
}
- (void)setDialRangeFrom:(float)from to:(float)to width:(CGFloat)width{

    _minimum = from;
    _maximum = to;
    
    // Resize the frame of the view
    CGRect frame = self.frame;
    if(width == 0){
        frame.size.width = (_maximum - _minimum) * _minorTickDistance+ self.leading*2;// self.superview.frame.size.width;
    }else{
        frame.size.width = width+ self.leading*2;// self.superview.frame.size.width;
    }
    
    self.frame = frame;
    
    
}
-(void)redrawView{
    [self.masLayer removeFromSuperlayer];
    self.masLayer = nil;
    if(!self.masLayer){
        self.masLayer = [CAShapeLayer layer];
    }
    
    self.masLayer.frame = self.bounds;
    self.backgroundColor = self.backColor;
    self.masLayer.lineCap = kCALineCapRound;
    self.masLayer.strokeColor = self.majorTickColor.CGColor;
    _bezier = [UIBezierPath bezierPath];
    labIndex = 0;
    for (float i = self.leading; i < self.frame.size.width; i += self.minorTickDistance) {
         // After
        if (i > (self.frame.size.width - self.leading)){
             break;
        }else{
            [self drawTicksWithIndex:labIndex atX:i];
            
        }
           
    }
    if(self.labArray.count >= labIndex){
       NSArray * array = [self.labArray subarrayWithRange:NSMakeRange(labIndex, self.labArray.count - labIndex)];
        for(UILabel * lab in array){
            [lab removeFromSuperview];
        }
        [self.labArray removeObjectsInArray:array];
    }
    self.masLayer.path = _bezier.CGPath;
    [self.layer addSublayer:self.masLayer];
}
#pragma mark - Drawing

- (void)drawLabelWithAtPoint:(CGPoint)point
                        text:(NSString *)text
                   fillColor:(UIColor *)fillColor
                 strokeColor:(UIColor *)strokeColor
                   withIndex:(NSInteger)index {
    
    CGSize boundingBox = [text boundingRectWithSize:CGSizeMake(100, 100)
                                            options:NSStringDrawingUsesLineFragmentOrigin
                                         attributes:@{NSFontAttributeName:self.labelFont}
                                            context:nil].size;
//    // We want the label to be centered on the specified x value
    NSInteger label_x = point.x - (boundingBox.width / 2);
    UILabel * lab;
    if(self.labArray.count > index){
        lab = self.labArray[index];
        lab.frame = CGRectMake(label_x, point.y, boundingBox.width, boundingBox.height);
    }else{
        lab = [[UILabel alloc]initWithFrame:CGRectMake(label_x, point.y, boundingBox.width, boundingBox.height)];
        [self.labArray addObject:lab];
    }
    lab.font = self.labelFont;
    lab.textColor = self.labelStrokeColor;
    lab.textAlignment = NSTextAlignmentCenter;
    lab.text = text;
    [self addSubview:lab];

}

- (void)drawMinorTickWithAtPoint:(CGPoint)point
                       withColor:(UIColor *)color
                           width:(CGFloat)width
                          length:(CGFloat)length {
    [self.bezier moveToPoint:CGPointMake(point.x, point.y + 20)];
    [self.bezier addLineToPoint:CGPointMake(point.x, point.y + 20 + length)];
}

- (void)drawMajorTickWithAtPoint:(CGPoint)point
                       withColor:(UIColor *)color
                           width:(CGFloat)width
                          length:(CGFloat)length {

    // Draw the line
    [_bezier moveToPoint:CGPointMake(point.x, point.y + 20)];
    [_bezier addLineToPoint:CGPointMake(point.x, point.y + 20 + length)];
}

- (void)drawTicksWithIndex:(NSInteger)index atX:(float)x
{

    CGPoint point = CGPointMake(x, 0);
    if ([self isMajorTick:x]) {

        [self drawMajorTickWithAtPoint:point
                             withColor:self.majorTickColor
                                 width:self.majorTickWidth
                                length:self.majorTickLength];

        float value = (point.x - self.leading)/(self.frame.size.width-2 * self.leading) * (_maximum - _minimum) + _minimum;
        NSString *text =@"";
        int seconds = value/self.factor;

        int minute = seconds/60;
        int second = seconds%60;
        if(minute>60){
            int hour = seconds/3600;
            minute = seconds/60%60;
            text =[NSString stringWithFormat:@"%02d:%02d:%02d",hour, minute,second];
        }
        else{
            text = [NSString stringWithFormat:@"%d:%02d", minute,second];
        }
        count++;
        if(count>1000)
            count=0;
        
        if(self.minorTickDistance<5&&count%2==0)
        {
            text = @"";
        }
        [self drawLabelWithAtPoint:point
                              text:text
                         fillColor:self.labelFillColor
                       strokeColor:self.labelStrokeColor
                         withIndex:index];
        labIndex ++;
    } else {

        // Save the current context so we revert some of the changes laster

        [self drawMinorTickWithAtPoint:point
                             withColor:self.minorTickColor
                                 width:self.minorTickWidth
                                length:self.minorTickLength];

        // Restore the context
    }
}

/**
 * Method to check if there is a major tick and the specified point offset
 * @param x [in] the pixel offset
 */
- (BOOL)isMajorTick:(float)x {//在放大缩小操作时，需调整此处，精度问题
    int tick_number = (x - self.leading) / self.minorTickDistance;
    return (tick_number % self.minorTicksPerMajorTick) == 0;
}
-(UIFont *)labelFont{
    if(!_labelFont){
        _labelFont = [UIFont systemFontOfSize:11];
    }
    return _labelFont;
}
-(NSMutableArray *)labArray{
    if(!_labArray){
        _labArray = [NSMutableArray array];
    }
    return _labArray;
}
@end
