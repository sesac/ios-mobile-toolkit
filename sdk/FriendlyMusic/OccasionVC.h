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

#import <UIKit/UIKit.h>
#import "RFAPI.h"

#define OCCASION_IMAGE_CACHE_PATH @"occasion_image_cache.plist"
#define OCCASION_IMAGE_DEPTH 4
#define OCCASION_IMAGE_SWITCH_DELAY 2.0 // seconds

typedef enum RFOccasion {
    RFOccasionMood = 0,
    RFOccasionCelebration,
    RFOccasionThemes,
    RFOccasionCurrentEvents,
    RFOccasionSports,
    RFOccasionHoliday
} RFOccasion;

@interface OccasionVC : UIViewController<UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, AVAudioPlayerDelegate> {
    IBOutlet UIButton *moodButton, *celebButton, *themeButton, *eventButton, *sportButton, *holidayButton;
    UIColor *firstLevelColor, *secondLevelColor, *thirdLevelColor, *secondFontColor, *thirdFontColor;
    UIButton *firstButton, *thirdButton;
    IBOutlet UIScrollView *scroller;
    IBOutlet UITableView *table;
    IBOutlet UIActivityIndicatorView *loadingIndicator;
    
    NSArray *occasionKeys;
    NSMutableDictionary *occasionData;
    NSMutableDictionary *occasionImageDict;
    NSTimer *rotateImagesTimer;
    IBOutlet UIActivityIndicatorView *bigSpinner;
    
    NSString *occasionImageCachePath;
    
    NSArray *occasions;
    NSMutableArray *occasionStack;
    Occasion *displayedOccasion;
    NSArray *displayedPlaylists;
    
}

- (IBAction)loadSecondLevel:(UIButton *)button;
- (void)showSecondLevel;
- (void)getOccasionsFromServer;
- (void)showThirdLevel:(UIButton *)button;
- (void)gotoPlaylist;
- (void)stop;
- (void)goBack;

- (void)loadOccasionImages;
- (void)saveOccasionImages;

- (void)updateOccasionImage;
- (void)switchImageForOccasion:(RFOccasion)occasion;
- (UIButton *)buttonForOccasion:(RFOccasion)occasion;

@end
