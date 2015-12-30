//
//  ViewController.h
//  QSWeekSelectorView
//
//  Created by qiusenwei on 15/12/30.
//  Copyright © 2015年 qiushao. All rights reserved.
//

#import "QSWeekSelectorView.h"
#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<QSWeekSelectorViewDelegate>

@property(weak, nonatomic) IBOutlet QSWeekSelectorView *weekSelector;
@property(weak, nonatomic) IBOutlet UILabel *label;


@end
