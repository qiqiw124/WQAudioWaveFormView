//
//  WQAudioWaveFormView.h
//  WQAudioWaveFormView_Example
//
//  Created by 祺祺 on 2020/11/9.
//  Copyright © 2020 01810452. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface WQAudioWaveFormView : UIView
-(instancetype)initWithFrame:(CGRect)frame audiAsset:(AVURLAsset *)audioAsset;

-(void)beginDrawView;
@end

NS_ASSUME_NONNULL_END
