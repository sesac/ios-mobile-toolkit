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

#import "FriendlyMusic.h"
#import "MoodMapVC.h"
#import "CoverFlowVC.h"
#import "OccasionVC.h"
#import "NSBundle+RumblefishMobileSDKResources.h"
#import "UIImage+RumblefishSDKResources.h"

@implementation FriendlyMusic

@synthesize FMMOODMAP, FMOCCASION, FMEDITORSPICKS;

NSMutableArray *optionArray;

- (id)init {
    self = [super initWithNibName:@"FriendlyMusic" bundle:[NSBundle rumblefishResourcesBundle]];
    if (self) {
        FMMOODMAP = 1;
        FMOCCASION = 2;
        FMEDITORSPICKS = 4;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (optionArray == nil || [optionArray count] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"No option is selected" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    self.navigationController.navigationBarHidden = YES;
    self.navigationItem.title = @"Back";
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];

    tabview.separatorColor = [UIColor colorWithRed:0.08f green:0.08f blue:0.08f alpha:1.0f];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [optionArray removeAllObjects];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)setOptions:(int)options {
    if (optionArray == nil) {
        optionArray = [[NSMutableArray alloc] init];
    } else {
        [optionArray removeAllObjects];
    }
    
    if ((options & FMMOODMAP) == FMMOODMAP) {
        [optionArray addObject:@"moodmap"];
    }
    if ((options & FMOCCASION) == FMOCCASION) {
        [optionArray addObject:@"occasion"];
    }
    if ((options & FMEDITORSPICKS) == FMEDITORSPICKS) {
        [optionArray addObject:@"editorspicks"];
    }
}

- (IBAction)close {
    [self.navigationController popViewControllerAnimated:YES];
}


// Table methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [optionArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"HomeCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
        UIImage *horImage = [UIImage imageInResourceBundleNamed:@"separator_horizontal.png"];
        UIImageView *horSeparator = [[UIImageView alloc] initWithImage:horImage];
        horSeparator.frame = CGRectMake(0, 0, 320, horImage.size.height);
        [cell.contentView addSubview:horSeparator];
        
        if ([[optionArray objectAtIndex:indexPath.row] isEqualToString:@"moodmap"]) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageInResourceBundleNamed:@"moodmap_logo.png"]];
            imageView.frame = CGRectMake(72, (347/[optionArray count]-29)/2, 176, 29);
            [cell.contentView addSubview:imageView];
        }
        else if ([[optionArray objectAtIndex:indexPath.row] isEqualToString:@"occasion"]) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageInResourceBundleNamed:@"occasion_logo.png"]];
            imageView.frame = CGRectMake(86.5, (347/[optionArray count]-71)/2, 147, 71);
            [cell.contentView addSubview:imageView];
        }
        else {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageInResourceBundleNamed:@"editorspick_logo.png"]];
            imageView.frame = CGRectMake(66.5, (347/[optionArray count]-74)/2, 187, 74);
            [cell.contentView addSubview:imageView];
        }
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 347/[optionArray count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[optionArray objectAtIndex:indexPath.row] isEqualToString:@"moodmap"]) {
        MoodMapVC *moodmap = [[MoodMapVC alloc] init];
        [self.navigationController pushViewController:moodmap animated:YES];
    }
    else if ([[optionArray objectAtIndex:indexPath.row] isEqualToString:@"occasion"]) {
        OccasionVC *occasion = [[OccasionVC alloc] init];
        [self.navigationController pushViewController:occasion animated:YES];
    }
    else {
        CoverFlowVC *coverflow = [[CoverFlowVC alloc] init];
        [coverflow setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
        [self.navigationController presentModalViewController:coverflow animated:YES];
    }
}

@end
