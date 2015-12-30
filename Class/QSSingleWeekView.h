#import <UIKit/UIKit.h>

@protocol QSSingleWeekViewDelegate;

@interface QSSingleWeekView : UIView

@property (nonatomic, weak) id<QSSingleWeekViewDelegate> delegate;

/**
 The first date to be shown.
 */
@property (nonatomic, strong) NSDate *startDate;

@end

@protocol QSSingleWeekViewDelegate <NSObject>

- (void)singleWeekView:(QSSingleWeekView *)singleWeekView didSelectDate:(NSDate *)date atFrame:(CGRect)frame;

- (UIView *)singleWeekView:(QSSingleWeekView *)singleWeekView viewForDate:(NSDate *)date withFrame:(CGRect)frame;

@end