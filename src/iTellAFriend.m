//
// Version 1.5.0
//
// Copyright 2011-2012 Kosher Penguin LLC
// Created by Adar Porat (https://github.com/aporat) on 1/16/2012.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//		http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "iTellAFriend.h"


#ifdef DEBUG
// First, check if we can use Cocoalumberjack for logging
#ifdef LOG_VERBOSE
extern int ddLogLevel;
#define ITELLLog(...)  DDLogVerbose(__VA_ARGS__)
#else
#define ITELLLog(...) NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat:__VA_ARGS__])
#endif
#else
#define ITELLLog(...) ((void)0)
#endif

static iTellAFriend *sharedInstance = nil;

static NSString *const iTellAFriendAppIdKey = @"iTellAFriendAppIdKey";
static NSString *const iTellAFriendAppKey = @"iTellAFriendAppKey";
static NSString *const iTellAFriendAppNameKey = @"iTellAFriendAppNameKey";
static NSString *const iTellAFriendAppGenreNameKey = @"iTellAFriendAppGenreNameKey";
static NSString *const iTellAFriendAppSellerNameKey = @"iTellAFriendAppSellerNameKey";
static NSString *const iTellAFriendAppStoreIconImageKey = @"iTellAFriendAppStoreIconImageKey";

static NSString *const iTellAFriendAppLookupURLFormat = @"http://itunes.apple.com/%@/lookup";
static NSString *const iTellAFriendiOSAppStoreURLFormat = @"http://itunes.apple.com/us/app/%@/id%d?mt=8&ls=1";
static NSString *const iTellAFriendRateiOSAppStoreURLFormat = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%d";
static NSString *const iTellAFriendGiftiOSiTunesURLFormat = @"https://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/giftSongsWizard?gift=1&salableAdamId=%d&productType=C&pricingParameter=STDQ";

#define REQUEST_TIMEOUT 60.0

@interface iTellAFriend ()
- (NSString *)messageBody;
- (void)promptIfNetworkAvailable;
@end

@implementation iTellAFriend

@synthesize appStoreCountry;
@synthesize applicationName;
@synthesize applicationVersion;
@synthesize applicationGenreName;
@synthesize applicationSellerName;
@synthesize appStoreIconImage;

@synthesize applicationKey;
@synthesize messageTitle;
@synthesize message;
@synthesize appStoreID;
@synthesize appStoreURL;


+ (void)load
{
    [self performSelectorOnMainThread:@selector(sharedInstance) withObject:nil waitUntilDone:NO];
}

+ (iTellAFriend *)sharedInstance
{
	@synchronized(self) {
		if (sharedInstance == nil) {
			sharedInstance = [[self alloc] init];
		}
	}
	return sharedInstance;
}

- (iTellAFriend *)init
{
    if ((self = [super init]))
    {
        
        // get bundle id from plist
        self.applicationBundleID = [[NSBundle mainBundle] bundleIdentifier];
        
        // get country
        self.appStoreCountry = [(NSLocale *)[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        
        // application version (use short version preferentially)
        self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        if ([applicationVersion length] == 0)
        {
            self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        }
        
        
        [self performSelectorOnMainThread:@selector(applicationLaunched) withObject:nil waitUntilDone:NO];
        
    }
    return self;
}

+ (id)getRootViewController {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(window in windows) {
            if (window.windowLevel == UIWindowLevelNormal) {
                break;
            }
        }
    }
    
    return [[[window subviews] objectAtIndex:0] nextResponder];
}

- (void)applicationLaunched
{
    // app key used to cache the app data
    if (self.appStoreID) {
        self.applicationKey = [NSString stringWithFormat:@"%d-%@", self.appStoreID, self.applicationVersion];
    } else {
        self.applicationKey = [NSString stringWithFormat:@"%@-%@", self.applicationBundleID, self.applicationVersion];
    }
    
    // load the settings info from the app NSUserDefaults, to avoid  http requests
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults objectForKey:iTellAFriendAppKey] isEqualToString:applicationKey]) {
        self.applicationName = [defaults objectForKey:iTellAFriendAppNameKey];
        self.applicationGenreName = [defaults objectForKey:iTellAFriendAppGenreNameKey];
        self.appStoreIconImage = [defaults objectForKey:iTellAFriendAppStoreIconImageKey];
        self.applicationSellerName = [defaults objectForKey:iTellAFriendAppSellerNameKey];
        
        if (!self.appStoreID) {
            self.appStoreID = [[defaults objectForKey:iTellAFriendAppIdKey] integerValue];
        }
    }
    
    // get the application name from the bundle
    if (self.applicationName==nil) {
        self.applicationName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    }
    
    
    
    // check if this is a new version
    if (![[defaults objectForKey:iTellAFriendAppKey] isEqualToString:applicationKey]) {
        [self promptIfNetworkAvailable];
    }
    
}

- (BOOL)canTellAFriend
{
    if ([MFMailComposeViewController canSendMail]) {
        return true;
    }
    
    return false;
    
}

- (UINavigationController *)tellAFriendController
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    [picker setSubject:self.messageTitle];
    [picker setMessageBody:[self messageBody] isHTML:YES];
    
    return picker;
}

- (void)giftThisApp
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:iTellAFriendGiftiOSiTunesURLFormat, self.appStoreID]]];
}

- (void)giftThisAppWithAlertView:(BOOL)alertView
{
    if (alertView==YES) {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Gift This App", @"") message:[NSString stringWithFormat:NSLocalizedString(@"You really enjoy using %@. Your family and friends will love you for giving them this app.", @""), self.applicationName] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"Gift", @""), nil];
        alertView.tag = 1;
        [alertView show];
        
    } else {
        [self giftThisApp];
    }
}

- (void)rateThisApp
{
    ITELLLog(@"Opening %@", [NSString stringWithFormat:iTellAFriendRateiOSAppStoreURLFormat, self.appStoreID]);
    
    SKStoreProductViewController *storeViewController = [[SKStoreProductViewController alloc] init];
    NSNumber *appId = [NSNumber numberWithInteger:self.appStoreID];
    [storeViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier:appId} completionBlock:nil];
    
    storeViewController.delegate = self;
    
    [[iTellAFriend getRootViewController] presentViewController:storeViewController animated:YES completion:^{
        
    }];
    
}

- (void)rateThisAppWithAlertView:(BOOL)alertView
{
    if (alertView==YES) {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Rate This App", @"") message:[NSString stringWithFormat:NSLocalizedString(@"If you enjoy using %@, would you mind taking a moment to rate it? It won't take more than a minute. Thanks for your support!", @""), self.applicationName] delegate:self cancelButtonTitle:NSLocalizedString(@"No, Thanks", @"") otherButtonTitles:NSLocalizedString(@"Rate", @""), nil];
        alertView.tag = 2;
        [alertView show];
        
    } else {
        [self rateThisApp];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag==1 && buttonIndex==1) {
        [self giftThisApp];
    } else if (alertView.tag==2 && buttonIndex==1) {
        [self rateThisApp];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)messageTitle
{
    if (messageTitle)
    {
        return messageTitle;
    }
    return [NSString stringWithFormat:@"Check out %@", applicationName];
}

- (NSString *)message
{
    if (message) {
        return message;
    }
    return @"Check out this application on the App Store:";
}

- (NSString *)messageBody
{
    // if we couldn't fetch the app information, use a simple fallback template
    if (self.applicationSellerName==nil) {
        // Fill out the email body text
        NSMutableString *emailBody = [NSMutableString stringWithFormat:@"<div> \n"
                                      "<p style=\"font:17px Helvetica,Arial,sans-serif\">%@</p> \n"
                                      "<h1 style=\"font:bold 16px Helvetica,Arial,sans-serif\"><a target=\"_blank\" href=\"%@\">%@</a></h1> \n"
                                      "<br> \n"
                                      "<table align=\"center\"> \n"
                                      "<tbody> \n"
                                      "<tr> \n"
                                      "<td valign=\"top\" align=\"center\"> \n"
                                      "<span style=\"font-family:Helvetica,Arial;font-size:11px;color:#696969;font-weight:bold\"> \n"
                                      "</td> \n"
                                      "</tr> \n"
                                      "<tr> \n"
                                      "<td align=\"left\"> \n"
                                      "<span style=\"font-family:Helvetica,Arial;font-size:11px;color:#696969\"> \n"
                                      "Please note that you have not been added to any email lists. \n"
                                      "</span> \n"
                                      "</td> \n"
                                      "</tr> \n"
                                      "</tbody> \n"
                                      "</table> \n"
                                      "</div>",
                                      self.message,
                                      [self.appStoreURL absoluteString],
                                      self.applicationName
                                      ];
        
        return emailBody;
        
    }
    
    // Fill out the email body text
    NSMutableString *emailBody = [NSMutableString stringWithFormat:@"<div> \n"
                                  "<p style=\"font:17px Helvetica,Arial,sans-serif\">%@</p> \n"
                                  "<table border=\"0\"> \n"
                                  "<tbody> \n"
                                  "<tr> \n"
                                  "<td style=\"padding-right:10px;vertical-align:top\"> \n"
                                  "<a target=\"_blank\" href=\"%@\"><img style=\"height: 170px; border-radius: 30px; -moz-border-radius: 30px; -khtml-border-radius: 30px; -webkit-border-radius: 30px;\" src=\"%@\" alt=\"Cover Art\"></a> \n"
                                  "</td> \n"
                                  "<td style=\"vertical-align:top\"> \n"
                                  "<a target=\"_blank\" href=\"%@\" style=\"color: Black;text-decoration:none\"> \n"
                                  "<h1 style=\"font:bold 16px Helvetica,Arial,sans-serif\">%@</h1> \n"
                                  "<p style=\"font:14px Helvetica,Arial,sans-serif;margin:0 0 2px\">%@</p> \n"
                                  "<p style=\"font:14px Helvetica,Arial,sans-serif;margin:0 0 2px\">Category: %@</p> \n"
                                  "</a> \n"
                                  "<p style=\"font:14px Helvetica,Arial,sans-serif;margin:0\"> \n"
                                  "<a target=\"_blank\" href=\"%@\"><img src=\"http://ax.phobos.apple.com.edgesuite.net/email/images_shared/view_item_button.png\"></a> \n"
                                  "</p> \n"
                                  "</td> \n"
                                  "</tr> \n"
                                  "</tbody> \n"
                                  "</table> \n"
                                  "<br> \n"
                                  "<br> \n"
                                  "<table align=\"center\"> \n"
                                  "<tbody> \n"
                                  "<tr> \n"
                                  "<td valign=\"top\" align=\"center\"> \n"
                                  "<span style=\"font-family:Helvetica,Arial;font-size:11px;color:#696969;font-weight:bold\"> \n"
                                  "</td> \n"
                                  "</tr> \n"
                                  "<tr> \n"
                                  "<td align=\"center\"> \n"
                                  "<span style=\"font-family:Helvetica,Arial;font-size:11px;color:#696969\"> \n"
                                  "Please note that you have not been added to any email lists. \n"
                                  "</span> \n"
                                  "</td> \n"
                                  "</tr> \n"
                                  "</tbody> \n"
                                  "</table> \n"
                                  "</div>",
                                  self.message,
                                  [self.appStoreURL absoluteString],
                                  self.appStoreIconImage,
                                  [self.appStoreURL absoluteString],
                                  self.applicationName,
                                  self.applicationSellerName,
                                  self.applicationGenreName,
                                  [self.appStoreURL absoluteString]];
    
    return emailBody;
}

- (NSURL *)appStoreURL
{
    if (appStoreURL) {
        return appStoreURL;
    }
    
    return [NSURL URLWithString:[NSString stringWithFormat:iTellAFriendiOSAppStoreURLFormat, @"app", appStoreID]];
}

- (void)checkForConnectivityInBackground
{
    @synchronized (self)
    {
        NSString *iTunesServiceURL = [NSString stringWithFormat:iTellAFriendAppLookupURLFormat, appStoreCountry];
        
        if (self.appStoreID)
        {
            iTunesServiceURL = [iTunesServiceURL stringByAppendingFormat:@"?id=%u", (unsigned int)self.appStoreID];
        }
        else
        {
            iTunesServiceURL = [iTunesServiceURL stringByAppendingFormat:@"?bundleId=%@", self.applicationBundleID];
        }
        
        ITELLLog(@"Requesting info from iTunes Service %@", iTunesServiceURL);
        
        NSError *error = nil;
        NSURLResponse *response = nil;
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:iTunesServiceURL] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:REQUEST_TIMEOUT];
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (data)
        {
            
            // convert to string
            NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            if (json!=nil && error==nil) {
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                
                NSArray* results = [json objectForKey:@"results"];
                
                if (results==nil || [results count]==0) {
                    ITELLLog(@"Unable to find apple id %@", self.applicationKey);
                    
                    return;
                }
                
                NSDictionary* result = [results objectAtIndex:0];
                
                if (result!=nil) {
                    
                    NSString *trackId = [result valueForKey:@"trackId"];
                    NSString *genreName = [result valueForKey:@"primaryGenreName"];
                    NSString *iconImage = [result valueForKey:@"artworkUrl100"];
                    NSString *appName = [result valueForKey:@"trackName"];
                    NSString *sellerName = [result valueForKey:@"sellerName"];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        // get app id
                        if (!self.appStoreID) {
                            if (trackId!=nil) {
                                NSUInteger appStoreId = [trackId integerValue];
                                self.appStoreID = appStoreId;
                                [defaults setObject:[NSNumber numberWithInteger:appStoreId] forKey:iTellAFriendAppIdKey];
                            }
                        }
                        
                        // get genre
                        if (!applicationGenreName) {
                            if (genreName!=nil) {
                                self.applicationGenreName = genreName;
                                [defaults setObject:genreName forKey:iTellAFriendAppGenreNameKey];
                            }
                        }
                        
                        if (!appStoreIconImage) {
                            if (iconImage!=nil) {
                                self.appStoreIconImage = iconImage;
                                [defaults setObject:iconImage forKey:iTellAFriendAppStoreIconImageKey];
                            }
                        }
                        
                        if (!applicationName) {
                            if (appName!=nil) {
                                self.applicationName = appName;
                                [defaults setObject:appName forKey:iTellAFriendAppNameKey];
                            }
                        }
                        
                        if (!applicationSellerName) {
                            if (sellerName!=nil) {
                                self.applicationSellerName = sellerName;
                                [defaults setObject:sellerName forKey:iTellAFriendAppSellerNameKey];
                            }
                        }
                    });
                    
                    [defaults setObject:applicationKey forKey:iTellAFriendAppKey];
                    ITELLLog(@"Loaded apple id information %@", self.applicationKey);
                }
                
            } else {
                ITELLLog(@"Unable to find apple id %@", self.applicationKey);
            }
        }
    }
}

- (void)promptIfNetworkAvailable
{
    [self performSelectorInBackground:@selector(checkForConnectivityInBackground) withObject:nil];
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}


@end
