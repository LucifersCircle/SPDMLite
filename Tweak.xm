#import <spawn.h>

@interface NSUserDefaults (SPDMLite)
-(id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
-(void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

@interface FBSystemService : NSObject
+(id)sharedInstance;
- (void)exitAndRelaunch:(bool)arg1;
- (void)shutdownAndReboot:(bool)arg1;
- (void)shutdownWithOptions:(unsigned long long)arg1;
- (void)enterTheSafeMode;
@end

@interface SBPowerDownController : UIViewController
-(void)ldrestart;
-(void)cancel;
@end 

@interface SBLockHardwareButtonActions
-(void)performLongPressActions;
@end

@interface SBDockView : UIView
@end

@interface SBUIPowerDownView : UIView {
    UIButton* _cancelButton;
    UILabel* _cancelLabel;
    UIView* _backdropView;

}
-(void)layoutSubviews;
-(void)_cancelButtonTapped;
@end

@interface SBLockHardwareButton : NSObject
-(void)forceResetSequenceDidBegin;
@end

static NSString *nsDomainString = @"com.idevicehacked.spdmliteprefs";
static NSString *nsNotificationString = @"com.idevicehacked.spdmliteprefs/preferences.changed";

static BOOL Enabled;

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {

NSNumber *e = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"Enabled" inDomain:nsDomainString];
Enabled = (e)? [e boolValue]:YES;

}

%hook SBPowerDownController

-(void)orderFront {

%orig;
if (Enabled) {

    UIAlertController* SPDMOptionView = [UIAlertController alertControllerWithTitle:@"SPDM Lite"
                            message:@"Please select an option."
                            preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* respringAction = [UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action) {
                            	[[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
                            }];
    UIAlertAction* safemodeAction = [UIAlertAction actionWithTitle:@"Safe Mode" style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action) {
                            	[self performSelector:@selector(enterTheSafeMode)];
                            }];
    UIAlertAction* powerDownAction = [UIAlertAction actionWithTitle:@"Power Down" style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action) {
                            	[[%c(FBSystemService) sharedInstance] shutdownWithOptions:0];
                            }];
    UIAlertAction* restartAction = [UIAlertAction actionWithTitle:@"Restart" style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action) {
                                [[%c(FBSystemService) sharedInstance] shutdownAndReboot:YES];
                            }];

    UIAlertAction* ldRestartAction = [UIAlertAction actionWithTitle:@"ldRestart" style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action) {
                                [self performSelector:@selector(ldrestart)];
                            }];

    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                            handler:^(UIAlertAction * action) {
                                [self cancel];
                            }];
    
    [SPDMOptionView addAction:respringAction];
    [SPDMOptionView addAction:safemodeAction];
    [SPDMOptionView addAction:powerDownAction];
    [SPDMOptionView addAction:restartAction];
    [SPDMOptionView addAction:ldRestartAction];
    [SPDMOptionView addAction:cancelAction];
    [cancelAction setValue:[UIColor redColor] forKey:@"titleTextColor"];
    [self presentViewController:SPDMOptionView animated:YES completion:nil];

    }
}

%new
-(void)ldrestart{
    pid_t pid;
    int status;
    const char* args[] = {"ldRun", NULL, NULL, NULL};
    posix_spawn(&pid, "/usr/bin/ldRun", NULL, NULL, (char* const*)args, NULL);
    waitpid(pid, &status, WEXITED);
} 


%end

%hook SBUIPowerDownView

-(void)layoutSubviews {
%orig;
if (Enabled) {

[self setHidden:YES]; 

    }
}

%end

%hook SBLockHardwareButton

-(void)forceResetSequenceDidBegin { 
    %orig;
if (Enabled) {

    SBLockHardwareButtonActions *btn = [%c(SBLockHardwareButtonActions) new];
    [btn performLongPressActions];

    }
}

%end

%ctor {

notificationCallback(NULL, NULL, NULL, NULL, NULL);
CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
NULL,
notificationCallback,
(CFStringRef)nsNotificationString,
NULL,
CFNotificationSuspensionBehaviorCoalesce);

}
