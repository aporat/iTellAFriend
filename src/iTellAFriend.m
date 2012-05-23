//
// Version 1.0.0
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

static iTellAFriend *sharedInstance = nil;

static NSString *const iTellAFriendAppKey = @"iTellAFriendAppKey";
static NSString *const iTellAFriendAppNameKey = @"iTellAFriendAppNameKey";
static NSString *const iTellAFriendAppGenreNameKey = @"iTellAFriendAppGenreNameKey";
static NSString *const iTellAFriendAppSellerNameKey = @"iTellAFriendAppSellerNameKey";
static NSString *const iTellAFriendAppStoreIconImageKey = @"iTellAFriendAppStoreIconImageKey";


static NSString *const iTellAppLookupURLFormat = @"http://itunes.apple.com/lookup?country=%@&id=%d";
static NSString *const iTellAFriendiOSAppStoreURLFormat = @"http://itunes.apple.com/us/app/%@/id%d?mt=8&ls=1";

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
  
  // check if this is a new version
  if (![[defaults objectForKey:iTellAFriendAppKey] isEqualToString:applicationKey]) {
    [self promptIfNetworkAvailable];  
  }

}

- (BOOL)canTellAFriend
{
  if ([MFMailComposeViewController canSendMail] && applicationName) {
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

- (NSString *)valueForKey:(NSString *)key inJSON:(NSString *)json
{
  NSRange keyRange = [json rangeOfString:[NSString stringWithFormat:@"\"%@\"", key]];
  if (keyRange.location != NSNotFound)
  {
    NSInteger start = keyRange.location + keyRange.length;
    NSRange valueStart = [json rangeOfString:@":" options:0 range:NSMakeRange(start, [json length] - start)];
    if (valueStart.location != NSNotFound)
    {
      start = valueStart.location + 1;
      NSRange valueEnd = [json rangeOfString:@"," options:0 range:NSMakeRange(start, [json length] - start)];
      if (valueEnd.location != NSNotFound)
      {
        NSString *value = [json substringWithRange:NSMakeRange(start, valueEnd.location - start)];
        value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        while ([value hasPrefix:@"\""] && ![value hasSuffix:@"\""])
        {
          if (valueEnd.location == NSNotFound)
          {
            break;
          }
          NSInteger newStart = valueEnd.location + 1;
          valueEnd = [json rangeOfString:@"," options:0 range:NSMakeRange(newStart, [json length] - newStart)];
          value = [json substringWithRange:NSMakeRange(start, valueEnd.location - start)];
          value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        
        value = [value stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
        value = [value stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
        value = [value stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
        value = [value stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
        value = [value stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
        value = [value stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
        value = [value stringByReplacingOccurrencesOfString:@"\\t" withString:@"\t"];
        value = [value stringByReplacingOccurrencesOfString:@"\\f" withString:@"\f"];
        value = [value stringByReplacingOccurrencesOfString:@"\\b" withString:@"\f"];
        
        while (YES)
        {
          NSRange unicode = [value rangeOfString:@"\\u"];
          if (unicode.location == NSNotFound)
          {
            break;
          }
          
          uint32_t c = 0;
          NSString *hex = [value substringWithRange:NSMakeRange(unicode.location + 2, 4)];
          NSScanner *scanner = [NSScanner scannerWithString:hex];
          [scanner scanHexInt:&c];
          
          if (c <= 0xffff)
          {
            value = [value stringByReplacingCharactersInRange:NSMakeRange(unicode.location, 6) withString:[NSString stringWithFormat:@"%C", (unichar)c]];
          }
          else
          {
            // convert character to surrogate pair
            uint16_t x = (uint16_t)c;
            uint16_t u = (c >> 16) & ((1 << 5) - 1);
            uint16_t w = (uint16_t)u - 1;
            unichar high = 0xd800 | (w << 6) | x >> 10;
            unichar low = (uint16_t)(0xdc00 | (x & ((1 << 10) - 1)));
            
            value = [value stringByReplacingCharactersInRange:NSMakeRange(unicode.location, 6) withString:[NSString stringWithFormat:@"%C%C", high, low]];
          }
        }
        return value;
      }
    }
  }
  return nil;
}

- (void)checkForConnectivityInBackground
{
  @synchronized (self)
  {
    @autoreleasepool {
      NSString *iTunesServiceURL = [NSString stringWithFormat:iTellAppLookupURLFormat, appStoreCountry, appStoreID];

      NSError *error = nil;
      NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:iTunesServiceURL] options:NSDataReadingUncached error:&error];
      if (data)
      {
        // convert to string
        NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        // get genre
        if (!applicationGenreName)
        {
          NSString *genreName = [self valueForKey:@"primaryGenreName" inJSON:json];
          [self performSelectorOnMainThread:@selector(setApplicationGenreName:) withObject:genreName waitUntilDone:YES];
          [defaults setObject:genreName forKey:iTellAFriendAppGenreNameKey];
        }

        if (!appStoreIconImage)
        {
          NSString *iconImage = [self valueForKey:@"artworkUrl100" inJSON:json];
          [self performSelectorOnMainThread:@selector(setAppStoreIconImage:) withObject:iconImage waitUntilDone:YES];
          [defaults setObject:iconImage forKey:iTellAFriendAppStoreIconImageKey];
        }

        if (!applicationName)
        {
          NSString *appName = [self valueForKey:@"trackName" inJSON:json];
          [self performSelectorOnMainThread:@selector(setApplicationName:) withObject:appName waitUntilDone:YES];
          [defaults setObject:appName forKey:iTellAFriendAppNameKey];
        }

        if (!applicationSellerName)
        {
          NSString *sellerName = [self valueForKey:@"sellerName" inJSON:json];
          [self performSelectorOnMainThread:@selector(setApplicationSellerName:) withObject:sellerName waitUntilDone:YES];
          [defaults setObject:sellerName forKey:iTellAFriendAppSellerNameKey];
        }

        [defaults setObject:applicationKey forKey:iTellAFriendAppKey];
        
#if !__has_feature(objc_arc)
        // release json
        [json release];
#endif
      }

    }
  }
}

- (void)promptIfNetworkAvailable
{
  [self performSelectorInBackground:@selector(checkForConnectivityInBackground) withObject:nil];
}



@end
