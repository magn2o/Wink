@interface UIStatusBarBackgroundView : UIView
@end

@interface UIStatusBarForegroundView : UIView
@end

@interface UIStatusBar : UIView
{
    UIStatusBarBackgroundView *_backgroundView;
    UIStatusBarForegroundView *_foregroundView;
}
@end

@interface UIStatusBarItem : NSObject
@end

@interface UIStatusBarItemView : UIView
@property(readonly, nonatomic) UIStatusBarItem *item; // @synthesize item=_item;
@end

@interface UIApplication ()
- (id)displayIdentifier;
@end
