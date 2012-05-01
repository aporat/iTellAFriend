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

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

@interface iTellAFriend : NSObject <MFMailComposeViewControllerDelegate> {
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
@property (nonatomic, copy) NSString *appStoreIconImage;

@property (nonatomic, copy) NSString *applicationKey;
@property (nonatomic, copy) NSString *messageTitle;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, assign) NSUInteger appStoreID;
@property (nonatomic, copy) NSURL *appStoreURL;

+ (iTellAFriend *)sharedInstance;

- (BOOL)canTellAFriend;
- (UINavigationController *)tellAFriendController;

@end
