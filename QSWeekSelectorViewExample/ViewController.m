//
//  ViewController.m
//  QSWeekSelectorView
//
//  Created by qiusenwei on 15/12/30.
//  Copyright © 2015年 qiushao. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSDate *now = [NSDate date];
    [self updateLabelForDate:now];
    
    self.weekSelector.firstWeekday = 2; // monday
    self.weekSelector.letterTextColor = [UIColor colorWithWhite:.5 alpha:1];
    self.weekSelector.delegate = self;
    self.weekSelector.selectedDate = now;
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateLabelForDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    dateFormatter.dateStyle = NSDateFormatterFullStyle;
    
    self.label.text = [dateFormatter stringFromDate:date];
}

#pragma mark - ASWeekSelectorViewDelegate

- (void)weekSelector:(QSWeekSelectorView *)weekSelector willSelectDate:(NSDate *)date
{
    [self updateLabelForDate:date];
}

#pragma mark UIInterfaceOrientation

-(BOOL)shouldAutorotate{
    return YES;
}

@end
