#import "QSWeekSelectorView.h"

#import "QSDaySelectionView.h"
#import "QSSingleWeekView.h"

#define screenWith [UIScreen mainScreen].bounds.size.width

@interface QSContainerView : UIView
@property(nonatomic, assign, getter=isAccessibilityElement)
    BOOL accessibilityElement;
@end
@implementation QSContainerView
@end

@interface QSWeekSelectorView () <QSSingleWeekViewDelegate>

@property(nonatomic, strong) QSSingleWeekView *singleWeekViews;
@property(nonatomic, weak) QSDaySelectionView *selectionView;
@property(nonatomic, strong) QSDaySelectionView *todayView;
@property(nonatomic, weak) UIView *lineView;

// for animating the selection view
@property(nonatomic, assign) CGFloat preDragSelectionX;
@property(nonatomic, assign) CGFloat preDragOffsetX;
@property(nonatomic, assign) BOOL isAnimating;
@property(nonatomic, assign) BOOL isSettingFrame;

@property(nonatomic, strong) NSDateFormatter *dayNameDateFormatter;
@property(nonatomic, strong) NSDateFormatter *dayNumberDateFormatter;
@property(nonatomic, strong) NSCalendar *gregorian;
@property(nonatomic, strong)
    NSDate *lastToday; // to check when we need to update our 'today' time stamp

// formatting
@property(nonatomic, strong) UIColor *selectorLetterTextColor;
@property(nonatomic, strong) UIColor *selectorBackgroundColor;
@property(nonatomic, strong) UIColor *lineColor;

@end

@implementation QSWeekSelectorView

#pragma mark - Public methods

- (void)setFirstWeekday:(NSUInteger)firstWeekday {
  _firstWeekday = firstWeekday;

  [self rebuildWeeks];
}

- (void)setSelectedDate:(NSDate *)selectedDate {
  [self setSelectedDate:selectedDate animated:NO];
}

- (void)setSelectedDate:(NSDate *)selectedDate animated:(BOOL)animated {
  if (!self.lastToday ||
      ![self date:self.lastToday matchesDateComponentsOfDate:[NSDate date]]) {
    [self rebuildWeeks];
  }

  if (![self date:selectedDate matchesDateComponentsOfDate:_selectedDate]) {
    [self colorLabelForDate:_selectedDate withTextColor:self.numberTextColor];
    _selectedDate = selectedDate;
    self.isAnimating = animated;

    [UIView animateWithDuration:animated ? 0.25f : 0
        animations:^{
          [self rebuildWeeks];
        }
        completion:^(BOOL finished) {
          self.isAnimating = NO;
          [self colorLabelForDate:_selectedDate
                    withTextColor:self.selectorLetterTextColor];
        }];
  }
}

- (void)setLocale:(NSLocale *)locale {
  _locale = locale;
  [self updateDateFormatters];
}

#pragma mark - UIView

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self didInit:YES];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self didInit:YES];
  }
  return self;
}

- (void)setFrame:(CGRect)frame {
  //??? frame's value
  self.isSettingFrame = YES;
  BOOL didChange = !CGRectEqualToRect(frame, self.frame);
  CGRect tmpRect =
      CGRectMake(frame.origin.x, frame.origin.y, screenWith, frame.size.height);
  [super setFrame:tmpRect];

  if (didChange) {
    _selectionView = nil;
    _todayView = nil;
    for (UIView *view in [self subviews]) {
      [view removeFromSuperview];
    }
    [self didInit:NO];
  }
  self.isSettingFrame = NO;
}

#pragma mark - ASSingleWeekViewDelegate

- (UIView *)singleWeekView:(QSSingleWeekView *)singleWeekView
               viewForDate:(NSDate *)date
                 withFrame:(CGRect)frame {
  BOOL isSelection =
      [self date:date matchesDateComponentsOfDate:self.selectedDate];
  if (isSelection) {
    self.selectionView.frame = frame;
  }

  NSDate *today = [NSDate date];
  BOOL isToday = [self date:date matchesDateComponentsOfDate:today];
  if (isToday) {
    self.todayView.frame = frame;
    [singleWeekView insertSubview:self.todayView atIndex:0];
    self.lastToday = today;
  }

  QSContainerView *wrapper = [[QSContainerView alloc] initWithFrame:frame];
  CGFloat width = CGRectGetWidth(frame);

  NSString *weekStr =
      [[self.dayNameDateFormatter stringFromDate:date] uppercaseString];

  NSMutableAttributedString *attrStr =
      [[NSMutableAttributedString alloc] initWithString:weekStr];

  NSRange allRange = [weekStr rangeOfString:weekStr];
  [attrStr addAttribute:NSFontAttributeName
                  value:[UIFont systemFontOfSize:12.0]
                  range:allRange];
  [attrStr addAttribute:NSForegroundColorAttributeName
                  value:[UIColor blackColor]
                  range:allRange];

  CGFloat weekHeight;
  NSStringDrawingOptions options =
      NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
  CGRect rect =
      [attrStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                            options:options
                            context:nil];
  weekHeight = ceilf(rect.size.height);

  CGFloat nameHeight = frame.size.height * 0.6 * 0.5;
  CGFloat topPadding = (frame.size.height * 0.6 * 0.5 - weekHeight) / 2;
  CGRect nameFrame = CGRectMake(0, topPadding, width, weekHeight);
  UILabel *letterLabel = [[UILabel alloc] initWithFrame:nameFrame];
  letterLabel.textAlignment = NSTextAlignmentCenter;
  letterLabel.font = [UIFont systemFontOfSize:12];
  letterLabel.textColor = self.letterTextColor;
  letterLabel.text = weekStr;
  [wrapper addSubview:letterLabel];

  NSString *dayNumberText = [self.dayNumberDateFormatter stringFromDate:date];
  CGRect numberFrame =
      CGRectMake(0, nameHeight, width, CGRectGetHeight(frame) - nameHeight * 2);
  UILabel *numberLabel = [[UILabel alloc] initWithFrame:numberFrame];
  numberLabel.textAlignment = NSTextAlignmentCenter;
  numberLabel.font = [UIFont systemFontOfSize:18];
  numberLabel.textColor = (isSelection && !self.isAnimating)
                              ? self.selectorLetterTextColor
                              : self.numberTextColor;
  numberLabel.text = dayNumberText;
  numberLabel.tag = 100 + [dayNumberText integerValue];
  [wrapper addSubview:numberLabel];

  CGRect lunarFrame =
      CGRectMake(0, CGRectGetMaxY(numberFrame) + topPadding, width, weekHeight);
  UILabel *lunarLabel = [[UILabel alloc] initWithFrame:lunarFrame];
  lunarLabel.textAlignment = NSTextAlignmentCenter;
  lunarLabel.font = [UIFont systemFontOfSize:10];
  lunarLabel.textColor = self.letterTextColor;
  lunarLabel.text = [self LunarForSolarComponent:[self componentOfDate:date]];
  [wrapper addSubview:lunarLabel];

  UIView *lineView =
      [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinY(frame) - 1, 0, 1,
                                               CGRectGetHeight(frame))];
  lineView.backgroundColor = self.lineColor;
  [wrapper addSubview:lineView];

  return wrapper;
}

- (void)singleWeekView:(QSSingleWeekView *)singleWeekView
         didSelectDate:(NSDate *)date
               atFrame:(CGRect)frame {
  [self userWillSelectDate:date];
  [self colorLabelForDate:_selectedDate withTextColor:self.numberTextColor];

  [UIView animateWithDuration:0.25f
      animations:^{
        self.selectionView.frame = frame;
      }
      completion:^(BOOL finished) {
        [self userDidSelectDate:date];
      }];
}

#pragma mark - Private helpers

- (void)didInit:(BOOL)setDefaults {
  if (setDefaults) {
    _letterTextColor = [UIColor colorWithWhite:204.f / 255 alpha:1];
    _numberTextColor = [UIColor colorWithWhite:77.f / 255 alpha:1];
    _lineColor = [UIColor colorWithWhite:245.f / 255 alpha:1];
    _selectorBackgroundColor = [UIColor whiteColor];
    _selectorLetterTextColor = [UIColor whiteColor];
    _preDragOffsetX = MAXFLOAT;
    _preDragSelectionX = MAXFLOAT;
    _locale = [NSLocale autoupdatingCurrentLocale];
    _gregorian = [[NSCalendar alloc]
        initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  }

  CGFloat width = CGRectGetWidth(self.frame);
  CGFloat height = CGRectGetHeight(self.frame);
  UIView *lineView =
      [[UIView alloc] initWithFrame:CGRectMake(0, height, width, 1)];
  lineView.backgroundColor = self.lineColor;
  lineView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self insertSubview:lineView atIndex:0];
  self.lineView = lineView;

  [self updateDateFormatters];
}

- (void)updateDateFormatters {
  self.dayNumberDateFormatter = [[NSDateFormatter alloc] init];
  self.dayNumberDateFormatter.locale = self.locale;
  self.dayNumberDateFormatter.dateFormat = @"d";
  self.dayNameDateFormatter = [[NSDateFormatter alloc] init];
  self.dayNameDateFormatter.locale = self.locale;
  self.dayNameDateFormatter.dateFormat =
      [NSDateFormatter dateFormatFromTemplate:@"E"
                                      options:0
                                       locale:self.locale];

  [self rebuildWeeks];
}

- (void)rebuildWeeks {
  if (!self.selectedDate) {
    return;
  }
  if (self.singleWeekViews) {
    [self.singleWeekViews removeFromSuperview];
  }
  CGFloat width = CGRectGetWidth(self.frame);
  CGFloat height = CGRectGetHeight(self.frame);

  CGRect frame = CGRectMake(0, 0, width, height);
  _singleWeekViews = [[QSSingleWeekView alloc] initWithFrame:frame];
  _singleWeekViews.delegate = self;
  _singleWeekViews.startDate =
      self.selectedDate; // needs to be set AFTER delegate

  [self addSubview:_singleWeekViews];
}

- (NSDate *)dateByAddingDays:(NSInteger)days toDate:(NSDate *)date {
  NSDateComponents *diff = [[NSDateComponents alloc] init];
  diff.day = days;
  return [self.gregorian dateByAddingComponents:diff toDate:date options:0];
}

- (BOOL)date:(NSDate *)date matchesDateComponentsOfDate:(NSDate *)otherDate {
  if (date == otherDate) {
    return YES;
  }
  if (!date || !otherDate) {
    return NO;
  }

  NSUInteger unitFlags =
      NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear;

  NSDateComponents *components =
      [self.gregorian components:unitFlags fromDate:date];
  NSDateComponents *otherComponents =
      [self.gregorian components:unitFlags fromDate:otherDate];
  return [components isEqual:otherComponents];
}

- (void)userWillSelectDate:(NSDate *)date {
  if ([self.delegate
          respondsToSelector:@selector(weekSelector:willSelectDate:)]) {
    [self.delegate weekSelector:self willSelectDate:date];
  }
}

- (void)userDidSelectDate:(NSDate *)date {
  [self colorLabelForDate:_selectedDate withTextColor:self.numberTextColor];
  _selectedDate = date;

  [self animateSelectionToPreDrag];

  if ([self.delegate
          respondsToSelector:@selector(weekSelector:didSelectDate:)]) {
    [self.delegate weekSelector:self didSelectDate:date];
  }
}

- (void)animateSelectionToPreDrag {
  if (self.preDragOffsetX < MAXFLOAT) {
    CGFloat selectionX = self.preDragSelectionX;

    CGRect selectionViewFrame = self.selectionView.frame;
    selectionViewFrame.origin.x = selectionX;

    [UIView animateWithDuration:0.25f
        animations:^{
          self.selectionView.frame = selectionViewFrame;
        }
        completion:^(BOOL finished) {
          [self colorLabelForDate:_selectedDate
                    withTextColor:self.selectorLetterTextColor];
        }];

    self.preDragOffsetX = MAXFLOAT;
  } else {
    [self colorLabelForDate:_selectedDate
              withTextColor:self.selectorLetterTextColor];
  }
}

- (void)colorLabelForDate:(NSDate *)date withTextColor:(UIColor *)textColor {
  NSString *dayNumberText = [self.dayNumberDateFormatter stringFromDate:date];
  NSInteger viewTag = 100 + [dayNumberText integerValue];
  UIView *view = [self.singleWeekViews viewWithTag:viewTag];
  if ([view isKindOfClass:[UILabel class]]) {
    UILabel *label = (UILabel *)view;
    label.textColor = textColor;
    return;
  }
}

#pragma mark - Lazy accessors

- (QSDaySelectionView *)selectionView {
  if (!_selectionView) {
    CGFloat width = CGRectGetWidth(self.frame) / 7;
    CGFloat height = CGRectGetHeight(self.frame);

    QSDaySelectionView *view = [[QSDaySelectionView alloc]
        initWithFrame:CGRectMake(0, 0, width, height)];
    view.backgroundColor = self.selectorBackgroundColor;
    view.fillCircle = YES;
    view.circleCenter = CGPointMake(width / 2, 20 + (height - 40) / 2);
    view.circleColor = self.tintColor;
    view.userInteractionEnabled = NO;
    [self insertSubview:view aboveSubview:self.lineView];
    _selectionView = view;
  }
  return _selectionView;
}

- (QSDaySelectionView *)todayView {
  if (!_todayView) {
    CGFloat width = CGRectGetWidth(self.frame) / 7;
    CGFloat height = CGRectGetHeight(self.frame);

    QSDaySelectionView *view = [[QSDaySelectionView alloc]
        initWithFrame:CGRectMake(0, 0, width, height)];
    view.backgroundColor = [UIColor clearColor];
    view.fillCircle = NO;
    view.circleCenter = CGPointMake(width / 2, 20 + (height - 40) / 2);
    view.circleColor = self.tintColor;
    view.userInteractionEnabled = NO;
    _todayView = view;
  }
  return _todayView;
}

#pragma mark - 农历转换函数

- (NSString *)LunarForSolarComponent:(NSDateComponents *)com {

  NSString *solarYear =
      [self LunarForSolarYear:com.year Month:com.month Day:com.day];

  NSArray *solarYear_arr = [solarYear componentsSeparatedByString:@"-"];

  if ([solarYear_arr[0] isEqualToString:@"正"] &&
      [solarYear_arr[1] isEqualToString:@"初一"]) {

    //正月初一：春节
    return @"春节";

  } else if ([solarYear_arr[0] isEqualToString:@"正"] &&
             [solarYear_arr[1] isEqualToString:@"十五"]) {

    //正月十五：元宵节
    return @"元宵";

  } else if ([solarYear_arr[0] isEqualToString:@"二"] &&
             [solarYear_arr[1] isEqualToString:@"初二"]) {

    //二月初二：春龙节(龙抬头)
    return @"龙抬头";

  } else if ([solarYear_arr[0] isEqualToString:@"五"] &&
             [solarYear_arr[1] isEqualToString:@"初五"]) {

    //五月初五：端午节
    return @"端午";

  } else if ([solarYear_arr[0] isEqualToString:@"七"] &&
             [solarYear_arr[1] isEqualToString:@"初七"]) {

    //七月初七：七夕情人节
    return @"七夕";

  } else if ([solarYear_arr[0] isEqualToString:@"八"] &&
             [solarYear_arr[1] isEqualToString:@"十五"]) {

    //八月十五：中秋节
    return @"中秋";

  } else if ([solarYear_arr[0] isEqualToString:@"九"] &&
             [solarYear_arr[1] isEqualToString:@"初九"]) {

    //九月初九：重阳节、中国老年节（义务助老活动日）
    return @"重阳";

  } else if ([solarYear_arr[0] isEqualToString:@"腊"] &&
             [solarYear_arr[1] isEqualToString:@"初八"]) {

    //腊月初八：腊八节
    return @"腊八";

  } else if ([solarYear_arr[0] isEqualToString:@"腊"] &&
             [solarYear_arr[1] isEqualToString:@"二十四"]) {

    //腊月二十四 小年
    return @"小年";

  } else if ([solarYear_arr[0] isEqualToString:@"腊"] &&
             [solarYear_arr[1] isEqualToString:@"三十"]) {

    //腊月三十（小月二十九）：除夕
    return @"除夕";
  }

  NSString *commonHoliday = [self CommonHoliday:com];
  if (commonHoliday != nil) {
    return commonHoliday;
  }
  return solarYear_arr[1];
}

- (NSString *)CommonHoliday:(NSDateComponents *)calendarDay {
  if (calendarDay.month == 1 && calendarDay.day == 1) {
    return @"元旦";

    // 2.14情人节
  } else if (calendarDay.month == 2 && calendarDay.day == 14) {
    return @"情人节";

    // 3.8妇女节
  } else if (calendarDay.month == 3 && calendarDay.day == 8) {
    return @"妇女节";

    // 5.1劳动节
  } else if (calendarDay.month == 5 && calendarDay.day == 1) {
    return @"劳动节";

    // 6.1儿童节
  } else if (calendarDay.month == 6 && calendarDay.day == 1) {
    return @"儿童节";

    // 8.1建军节
  } else if (calendarDay.month == 8 && calendarDay.day == 1) {
    return @"建军节";

    // 9.10教师节
  } else if (calendarDay.month == 9 && calendarDay.day == 10) {
    return @"教师节";

    // 10.1国庆节
  } else if (calendarDay.month == 10 && calendarDay.day == 1) {
    return @"国庆节";

    // 11.1植树节
  } else if (calendarDay.month == 3 && calendarDay.day == 12) {
    return @"植树节";

    // 11.11光棍节
  } else if (calendarDay.month == 11 && calendarDay.day == 11) {
    return @"光棍节";
  }
  return nil;
}

- (NSString *)LunarForSolarYear:(int)wCurYear
                          Month:(int)wCurMonth
                            Day:(int)wCurDay {

  //农历日期名
  NSArray *cDayName = [NSArray
      arrayWithObjects:@"*", @"初一", @"初二", @"初三", @"初四",
                       @"初五", @"初六", @"初七", @"初八", @"初九",
                       @"初十", @"十一", @"十二", @"十三", @"十四",
                       @"十五", @"十六", @"十七", @"十八", @"十九",
                       @"二十", @"廿一", @"廿二", @"廿三", @"廿四",
                       @"廿五", @"廿六", @"廿七", @"廿八", @"廿九",
                       @"三十", nil];

  //农历月份名
  NSArray *cMonName = [NSArray
      arrayWithObjects:@"*", @"正", @"二", @"三", @"四", @"五", @"六",
                       @"七", @"八", @"九", @"十", @"十一", @"腊", nil];

  //公历每月前面的天数
  const int wMonthAdd[12] = {0,   31,  59,  90,  120, 151,
                             181, 212, 243, 273, 304, 334};

  //农历数据
  const int wNongliData[100] = {
      2635,   333387, 1701,   1748,   267701, 694,    2391,   133423, 1175,
      396438, 3402,   3749,   331177, 1453,   694,    201326, 2350,   465197,
      3221,   3402,   400202, 2901,   1386,   267611, 605,    2349,   137515,
      2709,   464533, 1738,   2901,   330421, 1242,   2651,   199255, 1323,
      529706, 3733,   1706,   398762, 2741,   1206,   267438, 2647,   1318,
      204070, 3477,   461653, 1386,   2413,   330077, 1197,   2637,   268877,
      3365,   531109, 2900,   2922,   398042, 2395,   1179,   267415, 2635,
      661067, 1701,   1748,   398772, 2742,   2391,   330031, 1175,   1611,
      200010, 3749,   527717, 1452,   2742,   332397, 2350,   3222,   268949,
      3402,   3493,   133973, 1386,   464219, 605,    2349,   334123, 2709,
      2890,   267946, 2773,   592565, 1210,   2651,   395863, 1323,   2707,
      265877};

  int nTheDate, nIsEnd, m, k, n, i, nBit;

  //计算到初始时间1921年2月8日的天数：1921-2-8(正月初一)
  nTheDate = (wCurYear - 1921) * 365 + (wCurYear - 1921) / 4 + wCurDay +
             wMonthAdd[wCurMonth - 1] - 38;

  if ((!(wCurYear % 4)) && (wCurMonth > 2))
    nTheDate = nTheDate + 1;

  //计算农历天干、地支、月、日
  nIsEnd = 0;
  m = 0;
  n = 0;
  k = 0;
  while (nIsEnd != 1) {
    if (wNongliData[m] < 4095)
      k = 11;
    else
      k = 12;
    n = k;
    while (n >= 0) {
      //获取wNongliData(m)的第n个二进制位的值
      nBit = wNongliData[m];
      for (i = 1; i < n + 1; i++)
        nBit = nBit / 2;

      nBit = nBit % 2;

      if (nTheDate <= (29 + nBit)) {
        nIsEnd = 1;
        break;
      }

      nTheDate = nTheDate - 29 - nBit;
      n = n - 1;
    }
    if (nIsEnd)
      break;
    m = m + 1;
  }
  wCurYear = 1921 + m;
  wCurMonth = k - n + 1;
  wCurDay = nTheDate;
  if (k == 12) {
    if (wCurMonth == wNongliData[m] / 65536 + 1)
      wCurMonth = 1 - wCurMonth;
    else if (wCurMonth > wNongliData[m] / 65536 + 1)
      wCurMonth = wCurMonth - 1;
  }

  //生成农历月
  NSString *szNongliMonth;
  if (wCurMonth < 1) {
    szNongliMonth = [NSString
        stringWithFormat:@"闰%@",
                         (NSString *)[cMonName objectAtIndex:-1 * wCurMonth]];
  } else {
    szNongliMonth = (NSString *)[cMonName objectAtIndex:wCurMonth];
  }

  //生成农历日
  NSString *szNongliDay = [cDayName objectAtIndex:wCurDay];

  //合并
  NSString *lunarDate =
      [NSString stringWithFormat:@"%@-%@", szNongliMonth, szNongliDay];

  return lunarDate;
}

- (NSDateComponents *)componentOfDate:(NSDate *)date {
  NSDateComponents *com = [_gregorian
      components:NSCalendarUnitWeekday | NSCalendarUnitYear |
                 NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitHour |
                 NSCalendarUnitMinute | NSCalendarUnitSecond
        fromDate:date];
  com.hour = 0;
  com.minute = 0;
  com.second = 0;
  return com;
}
@end
