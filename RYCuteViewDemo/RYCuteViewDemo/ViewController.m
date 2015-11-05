//
//  ViewController.m
//  RYCuteViewDemo
//
//  Created by billionsfinance-resory on 15/11/5.
//  Copyright © 2015年 Resory. All rights reserved.
//

#import "ViewController.h"
#import "RYCuteView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    RYCuteView *cuteView = [[RYCuteView alloc] initWithFrame:CGRectMake(0, 0, 320, 568)];
    cuteView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:cuteView];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
