#import "AppDelegate.h"
#import "ViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <Speech/Speech.h>

@interface NSData (NSData_hexadecimalString)

- (NSString *)hexadecimalString;

@end

@implementation NSData (NSData_hexadecimalString)

- (NSString *)hexadecimalString {
	const unsigned char *dataBuffer = (const unsigned char *)[self bytes];
	if (!dataBuffer) return [NSString string];
	
	NSUInteger          dataLength  = [self length];
	NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
	
	for (int i = 0; i < dataLength; ++i)
		[hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
	
	return [NSString stringWithString:hexString];
}

@end

@interface AppDelegate () <UNUserNotificationCenterDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	self.window = [UIWindow new];
	self.window.rootViewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
	[self.window makeKeyAndVisible];

	UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
	center.delegate = self;
	UNAuthorizationOptions authOpts = UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge;
	[center requestAuthorizationWithOptions:authOpts completionHandler:^(BOOL granted, NSError * _Nullable error) {
		if (!error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[[UIApplication sharedApplication] registerForRemoteNotifications];
			});
		}
	}];

	[SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
		switch (status) {
			case SFSpeechRecognizerAuthorizationStatusAuthorized:
				NSLog(@"Authorized");
				break;
			case SFSpeechRecognizerAuthorizationStatusDenied:
				NSLog(@"Denied");
				break;
			case SFSpeechRecognizerAuthorizationStatusNotDetermined:
				NSLog(@"Not Determined");
				break;
			case SFSpeechRecognizerAuthorizationStatusRestricted:
				NSLog(@"Restricted");
				break;
			default:
				break;
		}
	}];

	return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	NSLog(@"Push token: %@", [deviceToken hexadecimalString]);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"Error");
}

@end
