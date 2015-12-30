#import "QSDaySelectionView.h"

@implementation QSDaySelectionView

#pragma mark - UIView

- (void)drawRect:(CGRect)rect
{
  CGContextRef context = UIGraphicsGetCurrentContext();

  // Draw circle.
  CGRect circleRect = [self circleRect];
  if (self.fillCircle) {
    CGContextSetFillColorWithColor(context, self.circleColor.CGColor);
    CGContextFillEllipseInRect(context, circleRect);
  } else {
    CGContextSetStrokeColorWithColor(context, self.circleColor.CGColor);
    CGContextStrokeEllipseInRect(context, circleRect);
  }
}

#pragma mark - Private helpers

- (CGRect)circleRect
{
  CGFloat diameterFromWidth  = CGRectGetWidth(self.frame) * .66;
  CGFloat diameterFromHeight = CGRectGetHeight(self.frame) * .4;
  
  CGFloat diameter = MIN(diameterFromWidth, diameterFromHeight);
  CGFloat xOffset = self.circleCenter.x - diameter / 2;
  CGFloat yOffset = self.circleCenter.y - diameter / 2;
  return CGRectMake(xOffset, yOffset, diameter, diameter);
}
@end
