//
//  YUSegmentDemo
//  Created by YyGgQq on 2016/12/15.
//  Copyright © 2016年 Yu Guanqun. All rights reserved.
//

#import "ExampleOneViewController.h"
#import <YUSegment/YUSegment.h>

@interface ExampleOneViewController ()

@property (nonatomic, strong) YUSegment *segment1;
@property (nonatomic, strong) YUSegment *segment2;
@property (nonatomic, strong) YUSegment *segment3;
@property (nonatomic, strong) YUSegment *segment4;
@property (nonatomic, strong) YUSegment *segment5;
@property (nonatomic, strong) YUSegment *segment6;

@end

@implementation ExampleOneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *titles1 = @[@"Left", @"Medium", @"Right"];
    NSArray *titles2 = @[@"Left3", @"Left2", @"Left1", @"Medium", @"Right1", @"Right2", @"Right3"];
    NSArray *images = @[[UIImage imageNamed:@"au"], [UIImage imageNamed:@"ca"], [UIImage imageNamed:@"cn"]];
    
    self.segment1 = [[YUSegment alloc] initWithTitles:titles1];
    [self.view addSubview:self.segment1];
    self.segment1.frame = (CGRect){20, 60, [UIScreen mainScreen].bounds.size.width - 40, 44};
    
    self.segment2 = [[YUSegment alloc] initWithTitles:titles1 style:YUSegmentStyleBox];
    [self.view addSubview:self.segment2];
    self.segment2.frame = (CGRect){20, 144, [UIScreen mainScreen].bounds.size.width - 40, 44};
    
    self.segment3 = [[YUSegment alloc] initWithImages:images];
    [self.view addSubview:self.segment3];
    self.segment3.frame = (CGRect){20, 228, [UIScreen mainScreen].bounds.size.width - 40, 44};
    
    self.segment4 = [[YUSegment alloc] initWithImages:images style:YUSegmentStyleBox];
    [self.view addSubview:self.segment4];
    self.segment4.frame = (CGRect){20, 312, [UIScreen mainScreen].bounds.size.width - 40, 44};
    self.segment4.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    self.segment4.indicator.backgroundColor = [UIColor whiteColor];
    
    self.segment5 = [[YUSegment alloc] initWithTitles:titles1 forImages:images];
    [self.view addSubview:self.segment5];
    self.segment5.frame = (CGRect){20, 396, [UIScreen mainScreen].bounds.size.width - 40, 72};
    
    self.segment6 = [[YUSegment alloc] initWithTitles:titles2];
    [self.view addSubview:self.segment6];
    self.segment6.frame = (CGRect){20, 508, [UIScreen mainScreen].bounds.size.width - 40, 44};
    self.segment6.segmentWidth = 88.0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
