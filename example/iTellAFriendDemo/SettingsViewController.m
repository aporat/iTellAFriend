//
// Copyright 2011-2012 Kosher Penguin LLC 
// Created by Adar Porat (https://github.com/aporat) on 1/16/2012.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "SettingsViewController.h"
#import "iTellAFriend.h"

@implementation SettingsViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) || (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)doneButtonPressed:(id)sender {
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationItem.title = NSLocalizedString(@"Settings", "");
  
  
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
  
  self.navigationItem.rightBarButtonItem = doneButton;
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
  return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
  }
  
  if (indexPath.row == 0) {
    cell.textLabel.text = NSLocalizedString(@"Tell a Friend", "");
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  } else if (indexPath.row == 1) {
    cell.textLabel.text = NSLocalizedString(@"Gift This App", "");
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  } else if (indexPath.row == 2) {
    cell.textLabel.text = NSLocalizedString(@"Rate in App Store", "");
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  } 
  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == 0) {
    if ([[iTellAFriend sharedInstance] canTellAFriend]) {
      UINavigationController* tellAFriendController = [[iTellAFriend sharedInstance] tellAFriendController];
      [self presentModalViewController:tellAFriendController animated:YES];
    }
  } else if (indexPath.row == 1) {
    [[iTellAFriend sharedInstance] giftThisAppWithAlertView:YES];
  } else if (indexPath.row == 2) {
    [[iTellAFriend sharedInstance] rateThisAppWithAlertView:YES];
  }
  
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
