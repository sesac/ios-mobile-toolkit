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

@interface FriendlyMusicCell : UITableViewCell

@property (nonatomic, strong) UIImageView *titleImageView;
@property (nonatomic, strong) UIImageView *separatorView;

@end

@implementation FriendlyMusicCell

@synthesize titleImageView, separatorView;

#define FriendlyMusicCellIdent @"FriendlyMusicCell"

static NSDictionary *titleImages;

+ (void)initialize {
    titleImages = @{
    @"moodmap": [UIImage imageInResourceBundleNamed:@"moodmap_logo.png"],
    @"occasion": [UIImage imageInResourceBundleNamed:@"occasion_logo.png"],
    @"editorspicks": [UIImage imageInResourceBundleNamed:@"editorspick_logo.png"],
    };
}

+ (FriendlyMusicCell *)cellWithTitle:(NSString *)title forTableView:(UITableView *)tableView {
    FriendlyMusicCell *cell = (FriendlyMusicCell *)[tableView dequeueReusableCellWithIdentifier:FriendlyMusicCellIdent];
    
    if (!cell)
        cell = [[FriendlyMusicCell alloc] init];
    
    cell.titleImageView.image = titleImages[title];
    [cell setNeedsLayout];
    
    return cell;
}

- (id)init {
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FriendlyMusicCellIdent]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.separatorView = [[UIImageView alloc] initWithImage:[UIImage imageInResourceBundleNamed:@"separator_horizontal.png"]];
        [self addSubview:separatorView];
        
        self.titleImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:titleImageView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.separatorView.frame = CGRectMake(0, 0, self.bounds.size.width, self.separatorView.frame.size.height);
    [self.titleImageView sizeToFit];
    self.titleImageView.frame = CGRectMake(
        (self.contentView.bounds.size.width - self.titleImageView.frame.size.width) / 2,
        (self.contentView.bounds.size.height - self.titleImageView.frame.size.height) / 2,
        self.titleImageView.frame.size.width,
        self.titleImageView.frame.size.height);
}

@end

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
    
    self.navigationController.navigationBar.tintColor = BAR_TINT_COLOR;
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

// Table methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [optionArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [FriendlyMusicCell cellWithTitle:[optionArray objectAtIndex:indexPath.row] forTableView:tableView];
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
        [self.navigationController pushViewController:coverflow animated:YES];
    }
}

@end
