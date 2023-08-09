#import "headers.h"

#define kAnimationDuration 0.4

static int transitionInStyle  = 5 << 20;
static int transitionOutStyle = 5 << 20;

static CGFloat displayDuration = 3;

static BOOL isEnabled = YES;
static BOOL alwaysShowTime = NO;

static BOOL availableItemVisibility[21];

static NSTimer *timer = nil;

static NSMutableDictionary *settings;

static BOOL isBlacklisted;

@interface UIStatusBar (Wink)
- (void)hideStatusBar;
- (void)showStatusBar;
@end

@interface NSString (NSAddition)
-(NSString *)stringBetweenString:(NSString *)start andString:(NSString *)end;
@end

@implementation NSString (NSAddition)
-(NSString *)stringBetweenString:(NSString *)start andString:(NSString *)end
{
    NSScanner* scanner = [NSScanner scannerWithString:self];

    [scanner setCharactersToBeSkipped:nil];
    [scanner scanUpToString:start intoString:NULL];

    if ([scanner scanString:start intoString:NULL])
    {
        NSString* result = nil;
        
        if ([scanner scanUpToString:end intoString:&result])
        {
            return result;
        }
    }
    
    return nil;
}
@end

static BOOL isItemStatic(UIStatusBarItem *item)
{
    NSMutableDictionary *availableItemsWithVisibility = [NSMutableDictionary dictionaryWithCapacity:21];
    
    if(NSString *itemName = [[item description] stringBetweenString:@"[" andString:@"]"])
    {
        NSArray *availableItemNames = [NSArray arrayWithObjects:@"Activity (Left/Right)", @"AirplaneMode:Airplane (Left)", @"Battery (Right)", @"BatteryPercent (Right)", @"Bluetooth (Right)", @"BluetoothBattery (Right)", @"DataNetwork (Left)", @"Indicator:AirPlay (Right)", @"Indicator:Alarm (Right)", @"Indicator:CallForward (Left/Right)", @"Indicator:RotationLock", @"Indicator:Siri", @"Indicator:TTY (Right)", @"Indicator:VPN (Left/Right)", @"Location (Right)", @"NotCharging (Right)", @"QuietMode:QuietMode (Right)", @"Service (Left)", @"SignalStrength (Left)", @"ThermalColor (Left/Right)", @"Time (Center)", nil];
        
        for(int i = 0; i < 21; i++)
        {
            [availableItemsWithVisibility setObject:[NSNumber numberWithBool:availableItemVisibility[i]] forKey:availableItemNames[i]];
        }
        
        id object = [availableItemsWithVisibility objectForKey:itemName];

        return [object boolValue];
    }
    
    return NO;
}

%hook UIStatusBarItemView
- (id)initWithItem:(id)item data:(id)data actions:(id)actions style:(id)style
{
    UIStatusBarItemView *itemView = %orig;
    
    if(isEnabled && !isBlacklisted)
    {
        if(alwaysShowTime)
        {
            itemView.hidden = !isItemStatic(item);
        }
        else
        {
            itemView.hidden = YES;
        }
    }

    return itemView;
}
%end

%hook UIStatusBar
- (id)initWithFrame:(struct CGRect)frame showForegroundView:(BOOL)showForegroundView inProcessStateProvider:(id)provider
{
    UIStatusBar *_statusBar = %orig;

    if(isEnabled)
    {
        isBlacklisted = [[settings objectForKey:[@"Blacklist-" stringByAppendingString:[[%c(UIApplication) sharedApplication] displayIdentifier]]] boolValue];

        if(!isBlacklisted)
        {
            _statusBar.userInteractionEnabled = YES;
            
            UITapGestureRecognizer *statusBarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showStatusBar)];
            [_statusBar addGestureRecognizer:statusBarTap];
            [statusBarTap release];
        }
    }
    
    return _statusBar;
}

%new
- (void)showStatusBar
{
    if(![timer isValid])
    {
        if(UIStatusBarForegroundView *foregroundView = MSHookIvar<UIStatusBarForegroundView *>(self, "_foregroundView"))
        {
            if(NSArray *gestureRecognizers = [self gestureRecognizers])
            {
                for(UIGestureRecognizer *gesture in gestureRecognizers)
                {
                    if([[gesture description] rangeOfString:@"showStatusBar"].location != NSNotFound)
                    {
                        [self removeGestureRecognizer:gesture];
                    }
                }
            }
            
            [UIView transitionWithView:foregroundView
                              duration:kAnimationDuration
                               options:transitionInStyle
                            animations:^(void) {
                                for(UIView *view in [foregroundView subviews])
                                {
                                    if(view.hidden) view.hidden = NO;
                                }
                            }
                            completion:^(BOOL finished) {
                                timer = [[NSTimer scheduledTimerWithTimeInterval:displayDuration target:self selector:@selector(hideStatusBar) userInfo:nil repeats:NO] retain];
                            }];
            
//            foregroundView.hidden = NO;
        }
    }
}

%new
- (void)hideStatusBar
{
    if(UIStatusBarForegroundView *foregroundView = MSHookIvar<UIStatusBarForegroundView *>(self, "_foregroundView"))
    {
        [UIView transitionWithView:foregroundView
                          duration:kAnimationDuration
                           options:transitionOutStyle
                        animations:^(void) {
                            for(UIStatusBarItemView *view in [foregroundView subviews])
                            {
                                if(!view.hidden)
                                {
                                    if(alwaysShowTime)
                                    {
                                        view.hidden = !isItemStatic([view item]);
                                    }
                                    else
                                    {
                                        view.hidden = YES;
                                    }
                                }
                            }
                        }
                        completion:^(BOOL finished) {
                            [timer invalidate];
                            timer = nil;
                        }];
        
//        foregroundView.hidden = YES;
        
        UITapGestureRecognizer *statusBarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showStatusBar)];
        [self addGestureRecognizer:statusBarTap];
        [statusBarTap release];
    }
}
%end

static void loadSettings()
{
    settings = [[[NSMutableDictionary alloc] initWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.fortysixandtwo.wink.plist"] retain];
    
    if([settings objectForKey:@"isEnabled"]) isEnabled = [[settings objectForKey:@"isEnabled"] boolValue];
    if([settings objectForKey:@"alwaysShowTime"]) alwaysShowTime = [[settings objectForKey:@"alwaysShowTime"] boolValue];
    if([settings objectForKey:@"transitionInStyle"]) transitionInStyle = [[settings objectForKey:@"transitionInStyle"] intValue] << 20;
    if([settings objectForKey:@"transitionOutStyle"]) transitionOutStyle = [[settings objectForKey:@"transitionOutStyle"] intValue] << 20;
    if([settings objectForKey:@"displayDuration"]) displayDuration = [[settings objectForKey:@"displayDuration"] floatValue];

    NSString *key = nil;
    for(int i = 0; i < 21; i++)
    {
        key = [NSString stringWithFormat:@"item_%d", i];
        availableItemVisibility[i] = [settings objectForKey:key] ? [[settings objectForKey:key] boolValue] : NO;
    }
    
    if([[settings objectForKey:@"blacklistSpringBoard"] boolValue])
        [settings setObject:@YES forKey:@"Blacklist-com.apple.springboard"];
}

static void reloadPrefsNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    loadSettings();
}

%ctor
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    %init;
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)&reloadPrefsNotification, CFSTR("com.fortysixandtwo.wink/settingschanged"), NULL, 0);
    
    loadSettings();
    [pool drain];
}