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

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import <StoreKit/StoreKit.h>

@interface iTellAFriend : NSObject <MFMailComposeViewControllerDelegate, SKStoreProductViewControllerDelegate, UIAlertViewDelegate> {
  NSString *appStoreCountry;
  NSString *applicationName;
  NSString *applicationVersion;
  NSString *applicationGenreName;
  NSString *applicationSellerName;
  NSString *appStoreIconImage;

  NSString *applicationKey;
  NSString *messageTitle;
  NSString *message;
  NSUInteger appStoreID;
  NSURL *appStoreURL;
}

//application details - these are set automatically
@property (nonatomic, copy) NSString *appStoreCountry;
@property (nonatomic, copy) NSString *applicationName;
@property (nonatomic, copy) NSString *applicationVersion;
@property (nonatomic, copy) NSString *applicationGenreName;
@property (nonatomic, copy) NSString *applicationSellerName;
@property (nonatomic, copy) NSString *applicationBundleID;
@property (nonatomic, copy) NSString *appStoreIconImage;

@property (nonatomic, copy) NSString *applicationKey;
@property (nonatomic, copy) NSString *messageTitle;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, assign) NSUInteger appStoreID;
@property (nonatomic, copy) NSURL *appStoreURL;


/**
 * Returns the shared iTellAFriend singleton
 * @return The shared iTellAFriend singleton
 */
+ (iTellAFriend *)sharedInstance;

/**
 * Returns if the app can display the tell a friend email composer
 * @return YES if the app can display the tell a friend email composer
 */
- (BOOL)canTellAFriend;

/**
 * Returns a mail composer navigation view controller with a tell a friend email template
 * @return mail composer view controller with a tell a friend email template
 */
- (UINavigationController *)tellAFriendController;

/**
 * Lanuches the gift app itunes screen
 */
- (void)giftThisApp;

/**
 * Lanuches the gift app itunes screen, with optional informational alert view
 * @param alertView optional informational alert view
 */
- (void)giftThisAppWithAlertView:(BOOL)alertView;

/**
 * Lanuches the app store rate this app screen
 */
- (void)rateThisApp;

/**
 * Lanuches the app store rate this app screen, with optional informational alert view
 * @param alertView optional informational alert view
 */
- (void)rateThisAppWithAlertView:(BOOL)alertView;

@end
