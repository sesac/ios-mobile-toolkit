/*
 Rumblefish Mobile Toolkit for iOS
 
 Copyright 2012 Rumblefish, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may
 not use this file except in compliance with the License. You may obtain
 a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 License for the specific language governing permissions and limitations
 under the License.
 
 Use of the Rumblefish Sandbox in connection with this file is governed by
 the Sandbox Terms of Use found at https://sandbox.rumblefish.com/agreement
 
 Use of the Rumblefish API for any commercial purpose in connection with
 this file requires a written agreement with Rumblefish, Inc.
 */

#import "FilterVC.h"
#import "UIImage+RumblefishSDKResources.h"

@implementation FilterVC

NSString *path;
NSMutableDictionary *playlistDic;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Filters";
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear All" style:UIBarButtonItemStylePlain target:self action:@selector(clearAll)];
    self.navigationItem.rightBarButtonItem = rightButton;
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    self.navigationItem.leftBarButtonItem = leftButton;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor colorWithRed:0.125f green:0.125f blue:0.125f alpha:1.0f];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    path = [[NSString alloc] initWithString:[documentsDirectory stringByAppendingPathComponent:@"playlist.plist"]];
    playlistDic = [[NSMutableDictionary alloc] initWithDictionary:[NSMutableDictionary dictionaryWithContentsOfFile:path]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)clearAll {
    [playlistDic setValue:[NSNumber numberWithBool:NO] forKey:@"instrumental"];
    [playlistDic setValue:[NSNumber numberWithBool:NO] forKey:@"vocal"];
    [playlistDic setValue:[NSNumber numberWithBool:NO] forKey:@"classical"];
    [playlistDic setValue:[NSNumber numberWithBool:NO] forKey:@"country"];
    [playlistDic setValue:[NSNumber numberWithBool:NO] forKey:@"electronic"];
    [playlistDic setValue:[NSNumber numberWithBool:NO] forKey:@"jazz"];
    [playlistDic setValue:[NSNumber numberWithBool:NO] forKey:@"rock/pop"];
    [playlistDic setValue:[NSNumber numberWithBool:NO] forKey:@"urban"];
    [playlistDic setValue:[NSNumber numberWithBool:NO] forKey:@"explicit"];
    [self.tableView reloadData];
}

- (void)setSwitch:(UISwitch *)uiswitch {
    [playlistDic setValue:[NSNumber numberWithBool:uiswitch.on] forKey:@"explicit"];
}

- (void)setFilter:(UIButton *)button {
    NSString *key;
    switch ([button tag]) {
        case 1:
            key = @"instrumental";
            break;
        case 2:
            key = @"vocal";
            break;
        case 3:
            key = @"classical";
            break;
        case 4:
            key = @"country";
            break;
        case 5:
            key = @"electronic";
            break;
        case 6:
            key = @"jazz";
            break;
        case 7:
            key = @"rock/pop";
            break;
        case 8:
            key = @"urban";
            break;
    }
    
    BOOL on = [[playlistDic objectForKey:key] boolValue];
    [playlistDic setValue:[NSNumber numberWithBool:!on] forKey:key];
    [button setImage: on ? [UIImage imageInResourceBundleNamed:@"btn_check_OFF.png"] : [UIImage imageInResourceBundleNamed:@"btn_check_ON.png"] forState:UIControlStateNormal];
}

- (void)close {
    [playlistDic writeToFile:path atomically:YES];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }
    else if (section == 1) {
        return 2;
    }
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FilterCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
    }
    
    UIImage *on = [UIImage imageInResourceBundleNamed:@"btn_check_ON.png"];
    UIImage *off = [UIImage imageInResourceBundleNamed:@"btn_check_OFF.png"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, off.size.width, off.size.height);
    [button addTarget:self action:@selector(setFilter:) forControlEvents:UIControlEventTouchUpInside];
    
    if (indexPath.section == 0) {
        cell.textLabel.text = @"Filter Explicit";
        UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(200, 5, 50, 20)];
        sw.on = [[playlistDic valueForKey:@"explicit"] boolValue] ? YES : NO;
        [sw addTarget:self action:@selector(setSwitch:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Instrumental";
            [button setImage:[[playlistDic valueForKey:@"instrumental"] boolValue] ? on : off forState:UIControlStateNormal];
            button.tag = 1;
            cell.accessoryView = button;
        }
        else {
            cell.textLabel.text = @"Vocal";
            [button setImage:[[playlistDic valueForKey:@"vocal"] boolValue] ? on : off forState:UIControlStateNormal];
            button.tag = 2;
            cell.accessoryView = button;
        }
    }
    else if (indexPath.row == 0) {
        cell.textLabel.text = @"Classical";
        [button setImage:[[playlistDic valueForKey:@"classical"] boolValue] ? on : off forState:UIControlStateNormal];
        button.tag = 3;
        cell.accessoryView = button;
    }
    else if (indexPath.row == 1) {
        cell.textLabel.text = @"Country";
        [button setImage:[[playlistDic valueForKey:@"country"] boolValue] ? on : off forState:UIControlStateNormal];
        button.tag = 4;
        cell.accessoryView = button;
    }
    else if (indexPath.row == 2) {
        cell.textLabel.text = @"Electronic";
        [button setImage:[[playlistDic valueForKey:@"electronic"] boolValue] ? on : off forState:UIControlStateNormal];
        button.tag = 5;
        cell.accessoryView = button;
    }
    else if (indexPath.row == 3) {
        cell.textLabel.text = @"Jazz";
        [button setImage:[[playlistDic valueForKey:@"jazz"] boolValue] ? on : off forState:UIControlStateNormal];
        button.tag = 6;
        cell.accessoryView = button;
    }
    else if (indexPath.row == 4) {
        cell.textLabel.text = @"Rock/Pop";
        [button setImage:[[playlistDic valueForKey:@"rock/pop"] boolValue] ? on : off forState:UIControlStateNormal];
        button.tag = 7;
        cell.accessoryView = button;
    }
    else if (indexPath.row == 5) {
        cell.textLabel.text = @"Urban";
        [button setImage:[[playlistDic valueForKey:@"urban"] boolValue] ? on : off forState:UIControlStateNormal];
        button.tag = 8;
        cell.accessoryView = button;
    }
    
    return cell;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return nil;
    }
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    headerView.backgroundColor = [UIColor colorWithRed:0.137f green:0.137f blue:0.137f alpha:1.0f];
    UILabel *label = [[UILabel alloc] initWithFrame:headerView.frame];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor colorWithRed:0.51f green:0.8 blue:0.29f alpha:1.0f];
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
    if (section == 1) {
        label.text = @"Type";
        
    }
    else {
        label.text = @"Genre";
    }
    [headerView addSubview:label];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

@end
