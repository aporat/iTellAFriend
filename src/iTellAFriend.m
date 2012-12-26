//
// Version 1.1.0
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

#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif

static iTellAFriend *sharedInstance = nil;

static NSString *const iTellAFriendAppKey = @"iTellAFriendAppKey";
static NSString *const iTellAFriendAppNameKey = @"iTellAFriendAppNameKey";
static NSString *const iTellAFriendAppGenreNameKey = @"iTellAFriendAppGenreNameKey";
static NSString *const iTellAFriendAppSellerNameKey = @"iTellAFriendAppSellerNameKey";
static NSString *const iTellAFriendAppStoreIconImageKey = @"iTellAFriendAppStoreIconImageKey";

static NSString *const iTellAFriendAppLookupURLFormat = @"http://itunes.apple.com/lookup?country=%@&id=%d";
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
        
        // get country
        self.appStoreCountry = [(NSLocale *)[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        
        // application version (use short version preferentially)
        self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        if ([applicationVersion length] == 0)
        {
            self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        }
        
        
        
    }
    return self;
}

- (void)setAppStoreID:(NSUInteger)appStore
{
    
    appStoreID = appStore;
    
    // app key used to cache the app data
    self.applicationKey = [NSString stringWithFormat:@"%d-%@", appStore, applicationVersion];
    
    // load the settings info from the app NSUserDefaults, to avoid  http requests
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults objectForKey:iTellAFriendAppKey] isEqualToString:applicationKey]) {
        self.applicationName = [defaults objectForKey:iTellAFriendAppNameKey];
        self.applicationGenreName = [defaults objectForKey:iTellAFriendAppGenreNameKey];
        self.appStoreIconImage = [defaults objectForKey:iTellAFriendAppStoreIconImageKey];
        self.applicationSellerName = [defaults objectForKey:iTellAFriendAppSellerNameKey];
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
    if ([MFMailComposeViewController canSendMail] && self.applicationSellerName) {
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
    [self giftThisAppWithAlertView:NO];
}

- (void)giftThisAppWithAlertView:(BOOL)alertView
{
    if (alertView==YES) {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Gift This App", @"") message:[NSString stringWithFormat:NSLocalizedString(@"You really enjoy using %@. Your family and friends will love you for giving them this app.", @""), self.applicationName] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"Gift", @""), nil];
        alertView.tag = 1;
        [alertView show];
        
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:iTellAFriendGiftiOSiTunesURLFormat, self.appStoreID]]];
    }
}

- (void)rateThisApp
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:iTellAFriendRateiOSAppStoreURLFormat, self.appStoreID]]];
}

- (void)rateThisAppWithAlertView:(BOOL)alertView
{
    if (alertView==YES) {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Rate This App", @"") message:[NSString stringWithFormat:NSLocalizedString(@"If you enjoy using %@, would you mind taking a moment to rate it? It won't take more than a minute. Thanks for your support!", @""), self.applicationName] delegate:self cancelButtonTitle:NSLocalizedString(@"No, Thanks", @"") otherButtonTitles:NSLocalizedString(@"Rate", @""), nil];
        alertView.tag = 2;
        [alertView show];
        
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:iTellAFriendGiftiOSiTunesURLFormat, self.appStoreID]]];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag==1 && buttonIndex==1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:iTellAFriendGiftiOSiTunesURLFormat, self.appStoreID]]];
    } else if (alertView.tag==2 && buttonIndex==1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:iTellAFriendRateiOSAppStoreURLFormat, self.appStoreID]]];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [controller dismissModalViewControllerAnimated:YES];
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
    // Fill out the email body text
    NSMutableString *emailBody = [NSMutableString stringWithFormat:@"<div> \n"
                                  "<p style=\"font:17px Helvetica,Arial,sans-serif\">%@</p> \n"
                                  "<table border=\"0\"> \n"
                                  "<tbody> \n"
                                  "<tr> \n"
                                  "<td style=\"padding-right:10px;vertical-align:top\"> \n"
                                  "<a target=\"_blank\" href=\"%@\"><img height=\"170\" border=\"0\" src=\"%@\" alt=\"Cover Art\"></a> \n"
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
    if (appStoreURL)
    {
        return appStoreURL;
    }
    
    return [NSURL URLWithString:[NSString stringWithFormat:iTellAFriendiOSAppStoreURLFormat, @"app", appStoreID]];
}

- (void)checkForConnectivityInBackground
{
    @synchronized (self)
    {
        NSString *iTunesServiceURL = [NSString stringWithFormat:iTellAFriendAppLookupURLFormat, appStoreCountry, appStoreID];
        
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
                
                // get genre
                if (!applicationGenreName)
                {
                    NSString *genreName = [json valueForKey:@"primaryGenreName"];
                    [self performSelectorOnMainThread:@selector(setApplicationGenreName:) withObject:genreName waitUntilDone:YES];
                    [defaults setObject:genreName forKey:iTellAFriendAppGenreNameKey];
                }
                
                if (!appStoreIconImage)
                {
                    NSString *iconImage = [json valueForKey:@"artworkUrl100"];
                    [self performSelectorOnMainThread:@selector(setAppStoreIconImage:) withObject:iconImage waitUntilDone:YES];
                    [defaults setObject:iconImage forKey:iTellAFriendAppStoreIconImageKey];
                }
                
                if (!applicationName)
                {
                    NSString *appName = [json valueForKey:@"trackName"];
                    [self performSelectorOnMainThread:@selector(setApplicationName:) withObject:appName waitUntilDone:YES];
                    [defaults setObject:appName forKey:iTellAFriendAppNameKey];
                }
                
                if (!applicationSellerName)
                {
                    NSString *sellerName = [json valueForKey:@"sellerName"];
                    [self performSelectorOnMainThread:@selector(setApplicationSellerName:) withObject:sellerName waitUntilDone:YES];
                    [defaults setObject:sellerName forKey:iTellAFriendAppSellerNameKey];
                }
                
                [defaults setObject:applicationKey forKey:iTellAFriendAppKey];
            }
        }
    }
}

- (void)promptIfNetworkAvailable
{
    [self performSelectorInBackground:@selector(checkForConnectivityInBackground) withObject:nil];
}



@end
