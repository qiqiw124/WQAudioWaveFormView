//
//  WQViewController.m
//  WQAudioWaveFormView
//
//  Created by 01810452 on 11/09/2020.
//  Copyright (c) 2020 01810452. All rights reserved.
//

#import "WQViewController.h"
#import <WQAudioWaveFormView.h>
@interface WQViewController ()
@property(nonatomic,strong)WQAudioWaveFormView * waveFormView;
@end

@implementation WQViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL * audioUrl = [[NSBundle mainBundle]URLForResource:@"tempAudio" withExtension:@"caf"];
    AVURLAsset * audioAsset = [[AVURLAsset alloc]initWithURL:audioUrl options:nil];
    
    CGRect showFrame = CGRectMake(0, ([UIScreen mainScreen].bounds.size.height - 200)/2 - 50, [UIScreen mainScreen].bounds.size.width, 200);
    self.waveFormView = [[WQAudioWaveFormView alloc]initWithFrame:showFrame audiAsset:audioAsset];
    [self.view addSubview:self.waveFormView];
    [self.waveFormView beginDrawView];
}







- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
