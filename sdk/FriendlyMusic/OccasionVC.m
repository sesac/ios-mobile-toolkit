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

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "OccasionVC.h"
#import "SBJson.h"
#import "PlaylistVC.h"

@implementation OccasionVC

NSMutableArray *secondButtons, *thirdButtons;
NSMutableArray *titles, *descriptions, *images;
NSDictionary *firstLevelDic, *secondLevelDic;
int level, sections, plRow, plSection;
bool isPlaying;
NSString *filePath, *srv;
UITableViewCell *selectedCell;
AVPlayer *audioPlayer;
AVPlayerItem *playerItem;
PlaylistVC *playlist;
CGRect thirdRect, secondRect;
bool replaySong;

NSArray *occasionKeys;
NSMutableDictionary *allImagesDict;
NSTimer *rotateImagesTimer;


#pragma mark - View lifecycle

- (void)viewDidLoad
{
//    NSLog(@"start viewDidLoad");
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.145f green:0.145f blue:0.145f alpha:1.0];
    
    sections = 0;
    plRow = -1;
    plSection = -1;
    level = 1;
    table.alpha = 0;
    replaySong = NO;
    
    table.separatorColor = [UIColor colorWithRed:0.08f green:0.08f blue:0.08f alpha:1.0f];
    selectedCell = [[UITableViewCell alloc] init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    filePath = [[NSString alloc] initWithString:[documentsDirectory stringByAppendingPathComponent:@"playlist.plist"]];
    
    UIImageView *titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"friendlymusic_logo.png"]];
    self.navigationItem.titleView = titleView;
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Playlist" style: UIBarButtonItemStyleBordered target:self action:@selector(gotoPlaylist)];
    self.navigationItem.rightBarButtonItem = rightButton;
    
    firstButton = [UIButton buttonWithType:UIButtonTypeCustom];
    firstButton.frame = CGRectMake(0, 0, 320, 35);
    firstButton.alpha = 0;
    firstButton.titleLabel.font = [UIFont systemFontOfSize:32];
    [firstButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [firstButton addTarget:self action:@selector(loadSecondLevel:) forControlEvents:UIControlEventTouchUpInside];
    [firstButton setContentEdgeInsets:UIEdgeInsetsMake(0, 3, 0, 0)];
    [[firstButton layer] setMasksToBounds:YES];
    [[firstButton layer] setBorderWidth:0.5];
    [[firstButton layer] setBorderColor:[[UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:1.0f] CGColor]];
    [self.view addSubview:firstButton];
    
    secondButtons = [[NSMutableArray alloc] init];
    thirdButtons = [[NSMutableArray alloc] init];
    allSongsArray = [[NSMutableArray alloc] init];
    titles = [[NSMutableArray alloc] init];
    descriptions = [[NSMutableArray alloc] init];
    images = [[NSMutableArray alloc] init];
    
    bigSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                  UIActivityIndicatorViewStyleWhiteLarge];
    
    UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];
    bigSpinner.center = topWindow.center;
    [topWindow addSubview:bigSpinner];
    
    occasionKeys = [NSArray arrayWithObjects: 
                        [NSNumber numberWithInt:RFOccasionMood],
                        [NSNumber numberWithInt:RFOccasionCelebration],
                        [NSNumber numberWithInt:RFOccasionThemes],
                        [NSNumber numberWithInt:RFOccasionCurrentEvents],
                        [NSNumber numberWithInt:RFOccasionSports],
                        [NSNumber numberWithInt:RFOccasionHoliday], 
                        nil];
    
    occasionImageCachePath = [documentsDirectory stringByAppendingPathComponent:OCCASION_IMAGE_CACHE_PATH];
    occasionImageDict = [[NSMutableDictionary alloc] init];

    // ensure we have arrays for each of the occasions
    for (NSNumber *occasion in occasionKeys) {
        NSArray *occasionArray = [[NSMutableArray alloc] init];
        [occasionImageDict setObject:occasionArray forKey:occasion];
    }

    [self loadOccasionImages];
        
    rotateImagesTimer = [NSTimer scheduledTimerWithTimeInterval:OCCASION_IMAGE_SWITCH_DELAY target:self selector:@selector(updateOccasionImage) userInfo:nil repeats:YES];
    
    [self performSelectorInBackground:@selector(getOccasionsFromServer) withObject:nil];
    
    // Registers this class as the delegate of the audio session.
    [[AVAudioSession sharedInstance] setDelegate: self];    
    // Allow the app sound to continue to play when the screen is locked.
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
//    NSLog(@"end viewDidLoad");

}

- (void)viewDidUnload
{
//    NSLog(@"start viewDidUnload");

    for (UIButton *b in secondButtons) {
        [b removeFromSuperview];
    }
    for (UIButton *b in thirdButtons) {
        [b removeFromSuperview];
    }
    [allSongsArray removeAllObjects];
    [thirdButtons removeAllObjects];
    [secondButtons removeAllObjects];
    thirdFontColor = nil;
    thirdLevelColor = nil;
    [titles removeAllObjects];
    [descriptions removeAllObjects];
    [images removeAllObjects];
    [super viewDidUnload];
    
//    NSLog(@"end viewDidUnload");
}

- (void)viewWillAppear:(BOOL)animated {
//    NSLog(@"start viewWillAppear");

    [super viewWillAppear:animated];
    [table reloadData];
    
//    NSLog(@"end viewDidUnload");

}

- (void)viewWillDisappear:(BOOL)animated {
//    NSLog(@"start viewWillDisappear");
    [rotateImagesTimer invalidate];

    [super viewWillDisappear:animated];
        
    if (plRow >= 0) {
        [self stop];
    }
    
//    NSLog(@"end viewWillDisappear");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) saveOccasionImages {
    // can't store NSNumbers, so convert them to strings before saving.
    NSMutableDictionary *saveData = [[NSMutableDictionary alloc] init];
    
    for (NSNumber *key in [occasionImageDict allKeys]) {
        [saveData setObject:[occasionImageDict objectForKey:key] forKey:[key stringValue]];
    }
    
    [saveData writeToFile:occasionImageCachePath atomically:YES];
    // NSLog(@"Wrote out: %@, with keys: %@, and result: %@", occasionImageCachePath, [saveData allKeys], saveResult);
}

- (void) loadOccasionImages {
    // first -- check to see if we have a locally saved cache.
    NSDictionary *savedData = [NSDictionary dictionaryWithContentsOfFile:occasionImageCachePath];
    
    if (!savedData) {
        // if not, load from the resource plist.
        NSBundle* bundle = [NSBundle mainBundle];
        NSString* plistPath = [bundle pathForResource:@"occasion_image_cache" ofType:@"plist"];
        NSLog(@"No saved data, attempting to load %@", plistPath);
        savedData = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    }
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    for (NSString *key in [savedData allKeys]) {
        NSMutableArray *imageData = [[NSMutableArray alloc] initWithArray:[savedData objectForKey:key]];
        NSNumber *numericKey = [numberFormatter numberFromString:key];
        
        // NSLog(@"loadOccasionImages occasion: %@ images: %u", numericKey, [imageData count]);
        
        [occasionImageDict setObject:imageData forKey:numericKey];
        [self switchImageForOccasion:[numericKey intValue]];
    }
    
    // NSLog(@"occasionImageDict keys: %@", [occasionImageDict allKeys]);
}

- (void)goBack {
//    NSLog(@"start goBack");

    [audioPlayer pause];
    
    [self.navigationController popViewControllerAnimated:YES];
//    NSLog(@"end goBack");

}

- (IBAction)loadSecondLevel:(UIButton *)button {
//    NSLog(@"start loadSecondLevel");

    if (level == 1) {
        NSArray *children;
        
        switch ([button tag]) {
            case 1:
                firstLevelColor = [UIColor colorWithRed:0.55f green:0.32f blue:0.68f alpha:1.0f];
                secondLevelColor = [UIColor colorWithRed:0.51f green:0.4f blue:0.58f alpha:1.0f];
                thirdLevelColor = [[UIColor alloc] initWithRed:0.506f green:0.45f blue:0.53f alpha:1.0f];
                secondFontColor = [UIColor colorWithRed:0.26f green:0.219f blue:0.278f alpha:1.0f];
                thirdFontColor = [[UIColor alloc] initWithRed:0.26f green:0.223f blue:0.282f alpha:1.0f];
                [firstButton setTitle:@"mood" forState:UIControlStateNormal];
                firstLevelDic = [occasionData objectForKey:[NSNumber numberWithInt:RFOccasionMood]];
                break;
                
            case 2:
                firstLevelColor = [UIColor colorWithRed:0.33f green:0.537f blue:0.156f alpha:1.0f];
                secondLevelColor = [UIColor colorWithRed:0.455f green:0.6f blue:0.33f alpha:1.0f];
                thirdLevelColor = [[UIColor alloc] initWithRed:0.474f green:0.537f blue:0.42f alpha:1.0f];
                secondFontColor = [UIColor colorWithRed:0.235f green:0.337f blue:0.152f alpha:1.0f];
                thirdFontColor = [[UIColor alloc] initWithRed:0.231f green:0.278f blue:0.192f alpha:1.0f];
                [firstButton setTitle:@"celebration" forState:UIControlStateNormal];
                firstLevelDic = [occasionData objectForKey:[NSNumber numberWithInt:RFOccasionCelebration]];
                break;
                
            case 3:
                firstLevelColor = [UIColor colorWithRed:0.66f green:0.576f blue:0.157f alpha:1.0f];
                secondLevelColor = [UIColor colorWithRed:0.71f green:0.64f blue:0.317f alpha:1.0f];
                thirdLevelColor = [[UIColor alloc] initWithRed:0.74f green:0.686f blue:0.435f alpha:1.0f];
                secondFontColor = [UIColor colorWithRed:0.455f green:0.4f blue:0.157f alpha:1.0f];
                thirdFontColor = [[UIColor alloc] initWithRed:0.443f green:0.4f blue:0.21f alpha:1.0f];
                [firstButton setTitle:@"themes" forState:UIControlStateNormal];
                firstLevelDic = [occasionData objectForKey:[NSNumber numberWithInt:RFOccasionThemes]];
                break;
                
            case 4:
                firstLevelColor = [UIColor colorWithRed:0.243f green:0.654f blue:0.63f alpha:1.0f];
                secondLevelColor = [UIColor colorWithRed:0.455f green:0.73f blue:0.713f alpha:1.0f];
                thirdLevelColor = [[UIColor alloc] initWithRed:0.6f green:0.713f blue:0.706f alpha:1.0f];
                secondFontColor = [UIColor colorWithRed:0.28f green:0.46f blue:0.455f alpha:1.0f];
                thirdFontColor = [[UIColor alloc] initWithRed:0.35f green:0.44f blue:0.435f alpha:1.0f];
                [firstButton setTitle:@"current events" forState:UIControlStateNormal];
                firstLevelDic = [occasionData objectForKey:[NSNumber numberWithInt:RFOccasionCurrentEvents]];
                break;
                
            case 5:
                firstLevelColor = [UIColor colorWithRed:0.192f green:0.388f blue:0.63f alpha:1.0f];
                secondLevelColor = [UIColor colorWithRed:0.31f green:0.45f blue:0.627f alpha:1.0f];
                thirdLevelColor = [[UIColor alloc] initWithRed:0.5f green:0.584f blue:0.69f alpha:1.0f];
                secondFontColor = [UIColor colorWithRed:0.168f green:0.282f blue:0.427f alpha:1.0f];
                thirdFontColor = [[UIColor alloc] initWithRed:0.274f green:0.34f blue:0.423f alpha:1.0f];
                [firstButton setTitle:@"sports" forState:UIControlStateNormal];
                firstLevelDic = [occasionData objectForKey:[NSNumber numberWithInt:RFOccasionSports]];
                break;
                
            case 6:
                firstLevelColor = [UIColor colorWithRed:0.647f green:0.2f blue:0.2f alpha:1.0f];
                secondLevelColor = [UIColor colorWithRed:0.745f green:0.32f blue:0.32f alpha:1.0f];
                thirdLevelColor = [[UIColor alloc] initWithRed:0.75f green:0.455f blue:0.455f alpha:1.0f];
                secondFontColor = [UIColor colorWithRed:0.51f green:0.172f blue:0.172f alpha:1.0f];
                thirdFontColor = [[UIColor alloc] initWithRed:0.5f green:0.21f blue:0.21f alpha:1.0f];
                [firstButton setTitle:@"holiday" forState:UIControlStateNormal];
                firstLevelDic = [occasionData objectForKey:[NSNumber numberWithInt:RFOccasionHoliday]];
                break;
        }
                
        children = (NSArray *)[firstLevelDic objectForKey:@"children"];
        
        firstButton.backgroundColor = firstLevelColor;
        firstButton.titleLabel.textColor = [UIColor whiteColor];
        
        for (int i=0; i<[children count]; i++) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.tag = i;
            button.frame = CGRectMake(0, 381+i*129, 320, 129);
            button.alpha = 0;
            button.backgroundColor = secondLevelColor;
            button.titleLabel.font = [UIFont systemFontOfSize:100];
            button.titleLabel.adjustsFontSizeToFitWidth = YES;
            [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [button setContentEdgeInsets:UIEdgeInsetsMake(0, 3, 0, 0)];
            [button setTitleColor:secondFontColor forState:UIControlStateNormal];
            [button setTitle:[[[children objectAtIndex:i] valueForKey:@"name"] lowercaseString] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(showThirdLevel:) forControlEvents:UIControlEventTouchUpInside];
            [[button layer] setMasksToBounds:YES];
            [[button layer] setBorderWidth:0.5];
            [[button layer] setBorderColor:[[UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:1.0f] CGColor]];
            [scroller addSubview:button];
            [secondButtons addObject:button];
        }
        scroller.contentSize = CGSizeMake(320, [children count]*129);
        [self showSecondLevel];
    }
    else {  //opposite direction of level 1
        // stop if playing
        if (plRow >= 0) {
            [self stop];
        }
        
        [UIView animateWithDuration:0.5 animations:^{
            firstButton.alpha = 0;
            table.alpha = 0;
            for (UIButton *b in secondButtons) {
                b.frame = CGRectMake(0, b.frame.origin.y+381, 320, 129);
                b.alpha = 0;
            }
            for (UIButton *b in thirdButtons) {
                b.frame = CGRectMake(0, b.frame.origin.y+346, 320, 56);
                b.alpha = 0;
            }
        }        
        completion:^(BOOL finished){
            scroller.hidden = YES;
            [UIView animateWithDuration:0.5f animations:^{
                //move
                moodButton.frame = CGRectMake(29, 13, 116, 115);    
                celebButton.frame = CGRectMake(175, 13, 116, 115);    
                themeButton.frame = CGRectMake(29, 151, 116, 115);    
                eventButton.frame = CGRectMake(175, 151, 116, 115);     
                sportButton.frame = CGRectMake(29, 289, 116, 115);    
                holidayButton.frame = CGRectMake(175, 289, 116, 115);   
                //blur
                [[moodButton layer] setRasterizationScale:1.0];
                [[celebButton layer] setRasterizationScale:1.0];
                [[themeButton layer] setRasterizationScale:1.0];
                [[eventButton layer] setRasterizationScale:1.0];
                [[sportButton layer] setRasterizationScale:1.0];
                [[holidayButton layer] setRasterizationScale:1.0];
                moodButton.alpha = 1;
                celebButton.alpha = 1;
                themeButton.alpha = 1;
                eventButton.alpha = 1;
                sportButton.alpha = 1;
                holidayButton.alpha = 1;
            }];
            [allSongsArray removeAllObjects];
            sections = 0;
            [thirdButtons removeAllObjects];
            [secondButtons removeAllObjects];
            [table reloadData];
        }];
        level = 1;
    }
//    NSLog(@"end loadSecondLevel");
}


- (void)showSecondLevel {
//    NSLog(@"start showSecondLevel");

    
    [UIView animateWithDuration:0.5f animations:^{
        //move
        moodButton.frame = CGRectMake(-117, -115, 116, 115);    
        celebButton.frame = CGRectMake(320, -115, 116, 115);    
        themeButton.frame = CGRectMake(-117, 151, 116, 115);    
        eventButton.frame = CGRectMake(320, 151, 116, 115);     
        sportButton.frame = CGRectMake(-117, 416, 116, 115);    
        holidayButton.frame = CGRectMake(320, 416, 116, 115);   
        //blur
        [[moodButton layer] setRasterizationScale:0.35];
        [[moodButton layer] setShouldRasterize:YES];
        [[celebButton layer] setRasterizationScale:0.35];
        [[celebButton layer] setShouldRasterize:YES];
        [[themeButton layer] setRasterizationScale:0.35];
        [[themeButton layer] setShouldRasterize:YES];
        [[eventButton layer] setRasterizationScale:0.35];
        [[eventButton layer] setShouldRasterize:YES];
        [[sportButton layer] setRasterizationScale:0.35];
        [[sportButton layer] setShouldRasterize:YES];
        [[holidayButton layer] setRasterizationScale:0.35];
        [[holidayButton layer] setShouldRasterize:YES];
        moodButton.alpha = 0;
        celebButton.alpha = 0;
        themeButton.alpha = 0;
        eventButton.alpha = 0;
        sportButton.alpha = 0;
        holidayButton.alpha = 0;
    } completion:^(BOOL finished){
        scroller.hidden = NO;
        [UIView animateWithDuration:0.5 animations:^{
            firstButton.alpha = 1.0;
            for (UIButton *b in secondButtons) {
                b.alpha = 1.0;
                b.frame = CGRectMake(0, b.frame.origin.y-381, 320, 129);
            }
        }];
    }];
    level = 2;
    
//    NSLog(@"end showSecondLevel");
}

- (void)showThirdLevel:(UIButton *)button {
//    NSLog(@"start showThirdLevel");

    int tag = [button tag];
    
    if (level == 2) {
        replaySong = NO;
        NSArray *parent = (NSArray *)[firstLevelDic objectForKey:@"children"];
        NSDictionary *childDic = (NSDictionary *)[parent objectAtIndex:[button tag]];
        secondLevelDic = childDic;
        NSArray *child = (NSArray *)[childDic objectForKey:@"children"];
        for (int i=0; i<[child count]; i++) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.tag = i;
            button.frame = CGRectMake(0, 381+i*56, 320, 56);
            button.backgroundColor = thirdLevelColor;
            button.titleLabel.font = [UIFont systemFontOfSize:50];
            button.titleLabel.adjustsFontSizeToFitWidth = YES;
            [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [button setContentEdgeInsets:UIEdgeInsetsMake(0, 3, 0, 0)];
            button.alpha = 0;
            [button setTitleColor:thirdFontColor forState:UIControlStateNormal];
            [button setTitle:[[[child objectAtIndex:i] valueForKey:@"name"] lowercaseString] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(loadPlaylist:) forControlEvents:UIControlEventTouchUpInside];
            [[button layer] setMasksToBounds:YES];
            [[button layer] setBorderWidth:0.5];
            [[button layer] setBorderColor:[[UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:1.0f] CGColor]];
            [scroller addSubview:button];
            [thirdButtons addObject:button];
        }
        scroller.contentSize = CGSizeMake(320, 35+[child count]*56);
        
        button.titleLabel.font = [UIFont systemFontOfSize:32];
        [UIView animateWithDuration:0.5 animations:^{
            //move
            secondRect = button.frame;
            button.frame = CGRectMake(0, 0, 320, 35);
            for (UIButton *b in secondButtons) {
                if ([b tag] != tag) {
                    b.frame = CGRectMake(0, b.frame.origin.y+381, 320, 129);
                    b.alpha = 0;
                }
            }
        }completion:^(BOOL finished){
            [UIView animateWithDuration:0.5 animations:^{
                for (UIButton *b in thirdButtons) {
                    b.alpha = 1.0;
                    b.frame = CGRectMake(0, b.frame.origin.y-346, 320, 56);
                }
            }];
        }];
        level = 3;
    }
    else if (level == 3 || level == 4) {  //opposite direction of level 2
        // stop if playing
        if (plRow >= 0) {
            [self stop];
        }
        
        [UIView animateWithDuration:0.5 animations:^{
            table.alpha = 0;
            for (UIButton *b in thirdButtons) {
                b.alpha = 0;
                b.frame = CGRectMake(0, b.frame.origin.y+346, 320, 56);
            }
        }
        completion:^(BOOL finished) {
            for (UIButton *b in thirdButtons) {
                [b removeFromSuperview];
            }
            [UIView animateWithDuration:0.5 animations:^{
                //move
                button.frame = secondRect;
                for (UIButton *b in secondButtons) {
                    if ([b tag] != tag) {
                        b.frame = CGRectMake(0, b.frame.origin.y-381, 320, 129);
                        b.alpha = 1.0;
                    }
                }
                scroller.contentSize = CGSizeMake(320, [secondButtons count]*129);
            }];
            button.titleLabel.font = [UIFont systemFontOfSize:100];
            [allSongsArray removeAllObjects];
            sections = 0;
            [table reloadData];
            [thirdButtons removeAllObjects];
        }];
        level = 2;
    }
//    NSLog(@"end showThirdLevel");

}

- (void)fetchPlaylistsForOccasion:(NSString *)occasionID {
    NSObject *json = [[RFAPI singleton] resource:RFAPIResourceOccasion withID:occasionID];
    
    if (!json) {
        [self alertWithError:@"Could not load playlist. Please try again."];
        NSLog(@"No JSON in response to occasionWithID:%@", occasionID);
        return;
    }
    
    NSDictionary *pl = (NSDictionary *)[json valueForKey:@"occasion"];
    NSArray *plistArray = (NSArray *)[pl objectForKey:@"playlists"];
    
    sections = 0;
    [titles removeAllObjects];
    [descriptions removeAllObjects];
    [images removeAllObjects];
    [allSongsArray removeAllObjects];
    
    for (NSDictionary *plist in plistArray) {            
        NSObject *json = [[RFAPI singleton] resource:RFAPIResourcePlaylist withID:[plist valueForKey:@"id"]];
        
        if (!json) continue;
        
        NSDictionary *pl = (NSDictionary *)[json valueForKey:@"playlist"];
        NSArray *mediaArray = (NSArray *)[pl objectForKey:@"media"];
        sections++;
        NSMutableArray *songsArray = [[NSMutableArray alloc] init];
        for (NSDictionary *media in mediaArray) {
            NSMutableDictionary *song = [[NSMutableDictionary alloc] init];
            
            NSDictionary *album = (NSDictionary *)[media valueForKey:@"album"];
            
            if (album) {
                [song setValue:[album valueForKey:@"title"] forKey:@"album"];
            }
            
            [song setValue:[media valueForKey:@"genre"] forKey:@"genre"];
            [song setValue:[media valueForKey:@"explicit"] forKey:@"explicit"];
            [song setValue:[media valueForKey:@"id"] forKey:@"ID"];
            [song setValue:[media valueForKey:@"title"] forKey:@"title"];
            [song setValue:[media valueForKey:@"preview_url"] forKey:@"url"];
            [songsArray addObject:song];
        }
        
        [allSongsArray addObject:songsArray];
        
        
        // adding title and description
        NSString *title = [plist objectForKey:@"title"];
        if (title != nil) {
            [titles addObject:title];
        }
        else {
            [titles addObject:@""];
        }
        
        NSString *editorial = [plist objectForKey:@"editorial"];
        if (editorial != nil && ![editorial isEqualToString:@""]) {
            NSRange h2range = [editorial rangeOfString:@"<h2>"];
            NSRange h3range = [editorial rangeOfString:@"<h3>"];
            NSRange notFound = NSMakeRange(NSNotFound, 0);
            if (NSEqualRanges(notFound, h2range) || NSEqualRanges(notFound, h3range)) {
                [descriptions addObject:@""];
            }
            else {
                NSString *h2 = [editorial substringFromIndex:h2range.location+4];
                h2 = [h2 substringToIndex:[h2 rangeOfString:@"</h2"].location];
                NSString *h3 = [editorial substringFromIndex:h3range.location+4];
                h3 = [h3 substringToIndex:[h3 rangeOfString:@"</h3"].location];
                [descriptions addObject:[NSString stringWithFormat:@"%@. %@", h2, h3]];
            }
        }
        else {
            [descriptions addObject:@""];
        }
        
        // adding images
        NSString *image_url = [pl objectForKey:@"image_url"];
        if (image_url != nil && ![image_url isEqualToString:@""]) {
            NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[image_url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            [images addObject:imageData];
        }   
        else {
            [images addObject:@""];
        }
    }

}



- (void)loadPlaylist:(UIButton *)button {
//    NSLog(@"start loadPlaylist");

    thirdButton = button;
    int tag = [button tag];
    if (level == 3) {
        NSArray *parent = (NSArray *)[secondLevelDic objectForKey:@"children"];
        NSDictionary *childDic = (NSDictionary *)[parent objectAtIndex:tag];
        
        [self fetchPlaylistsForOccasion:[childDic valueForKey:@"id"]];
                
        [table reloadData];
        
        button.titleLabel.font = [UIFont systemFontOfSize:32];
        [UIView animateWithDuration:0.5 animations:^{
            table.alpha = 1.0;
            //move
            thirdRect = button.frame;
            button.frame = CGRectMake(0, 35, 320, 35);
            for (UIButton *b in thirdButtons) {
                if ([b tag] != tag) {
                    b.frame = CGRectMake(0, b.frame.origin.y+346, 320, 56);
                    b.alpha = 0;
                }
            }
            scroller.contentSize = CGSizeMake(320, 381);
        }];
        level = 4;
        
        // play same song if needed
        if (replaySong && plRow>=0 && plSection>=0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:plRow inSection:plSection];
            [table selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            [table.delegate tableView:table didSelectRowAtIndexPath:indexPath];
        }
    }
    else {  // opposite direction of level 3
        // stop if playing
        if (plRow >= 0) {
            [self stop];
        }
        
        button.titleLabel.font = [UIFont systemFontOfSize:50];
        [UIView animateWithDuration:0.5 animations:^{
            table.alpha = 0;
            //move
            button.frame = thirdRect;
            for (UIButton *b in thirdButtons) {
                if ([b tag] != tag) {
                    b.frame = CGRectMake(0, b.frame.origin.y-346, 320, 56);
                    b.alpha = 1;
                }
            }
        }
        completion:^(BOOL finished) {
            [allSongsArray removeAllObjects];
            sections = 0;
            [table reloadData];
            scroller.contentSize = CGSizeMake(320, 35+[thirdButtons count]*56);
        }];
        level = 3;
    }
    
//    NSLog(@"end loadPlaylist");
}


- (void)addToPlaylist:(UIButton *)button {
//    NSLog(@"start addToPlaylist");

    int row = [[table indexPathForCell:(UITableViewCell *)[[button superview] superview]] row];
    int section = [[table indexPathForCell:(UITableViewCell *)[[button superview] superview]] section];
    NSMutableDictionary *playlistDic = [[NSMutableDictionary alloc] initWithDictionary:[NSMutableDictionary dictionaryWithContentsOfFile:filePath]];
    NSMutableArray *playlistArray = [[NSMutableArray alloc] initWithArray:[playlistDic objectForKey:@"songs"]];
    
    NSArray *songsArray = [allSongsArray objectAtIndex:section];
    [playlistArray addObject:[songsArray objectAtIndex:row]];
    [playlistDic setObject:playlistArray forKey:@"songs"];
    [playlistDic writeToFile:filePath atomically:YES];
        
    button.hidden = YES;
    [[button superview] viewWithTag:8].hidden = NO;
//    NSLog(@"end addToPlaylist");
}

- (void)removeFromPlaylist:(UIButton *)button {
//    NSLog(@"start removeFromPlaylist");

    int row = [[table indexPathForCell:(UITableViewCell *)[[button superview] superview]] row];
    int section = [[table indexPathForCell:(UITableViewCell *)[[button superview] superview]] section];
    NSMutableDictionary *playlistDic = [[NSMutableDictionary alloc] initWithDictionary:[NSMutableDictionary dictionaryWithContentsOfFile:filePath]];
    NSMutableArray *playlistArray = [[NSMutableArray alloc] initWithArray:[playlistDic objectForKey:@"songs"]];
    
    NSArray *songsArray = [allSongsArray objectAtIndex:section];
    [playlistArray removeObject:[songsArray objectAtIndex:row]];
    for (NSDictionary *dic in playlistArray) {
        if ([[dic valueForKey:@"ID"] intValue] == [[[songsArray objectAtIndex:row] valueForKey:@"ID"] intValue]) {
            [playlistArray removeObject:dic];
            break;
        }
    }
    [playlistDic setObject:playlistArray forKey:@"songs"];
    [playlistDic writeToFile:filePath atomically:YES];
    
    button.hidden = YES;
    [[button superview] viewWithTag:5].hidden = NO;
    
//    NSLog(@"end removeFromPlaylist");
}

- (void)gotoPlaylist {
//    NSLog(@"start gotoPlaylist");

    if (plRow >= 0) {
        [self stop];
    }
    if (playlist == nil) {
        playlist = [[PlaylistVC alloc] initWithServer:srv];
    }
    [self.navigationController pushViewController:playlist animated:YES];
//    NSLog(@"end gotoPlaylist");
}

- (void)fetchOccasionImages {
//    NSLog(@"start fetchOccasionImages");
    
    NSDictionary *tmpOccasionData = nil;
    NSMutableArray *tmpImageUrls = nil;
    
    for ( NSNumber *occasion in occasionKeys ) {
//        NSLog(@"-- loadOccasionImages, occasion: %@", occasion);
        
        tmpOccasionData = [occasionData objectForKey:occasion];
        tmpImageUrls = [[NSMutableArray alloc] init];

        // dive down into occasions to retrieve the playlist image URLs for the grandchild occasions.
        NSArray *children = [tmpOccasionData objectForKey:@"children"];

        for (NSDictionary *child in children) {
            NSArray *grandChildren = [child objectForKey:@"children"];
            for (NSDictionary *grandChild in grandChildren) {                
                NSObject *json = [[RFAPI singleton] resource:RFAPIResourceOccasion withID:[grandChild valueForKey:@"id"]];
                NSDictionary *occasion = (NSDictionary *)[json valueForKey:@"occasion"];
                NSArray *playlists = [occasion objectForKey:@"playlists"];
                for (NSDictionary *playlist in playlists) {
                    NSString *image_url = [playlist objectForKey:@"image_url"];
                    if (image_url != nil && ![image_url isEqualToString:@""]) {
                        [tmpImageUrls addObject:[image_url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                    }
                    
                }
            }
        }
        // randomize order of tmpImageUrls
        for (int i = 0; i < [tmpImageUrls count]; i++) {
            
            [tmpImageUrls exchangeObjectAtIndex:i withObjectAtIndex:(arc4random() % ([tmpImageUrls count] - 1))];
        }

        NSMutableArray *tmpImageData = [[NSMutableArray alloc] init];
        
        // retrieve the first OCCASION_IMAGE_DEPTH images
        for (NSString *url in tmpImageUrls) {
            if ([tmpImageData count] >= OCCASION_IMAGE_DEPTH) { break; }
            
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
            if (data) {
                [tmpImageData addObject:data];
            }
        }
        
        // set the images for the occasion
        [occasionImageDict setObject:tmpImageData forKey:occasion];

    }
    
    [self saveOccasionImages];
    
//    NSLog(@"end fetchOccasionImages");
}

- (UIButton *)buttonForOccasion:(RFOccasion)occasion {
    UIButton *targetButton;
    
    switch (occasion) {
        case RFOccasionMood:
            targetButton = moodButton;
            break;
        case RFOccasionCelebration:
            targetButton = celebButton;
            break;
        case RFOccasionThemes:
            targetButton = themeButton;
            break;
        case RFOccasionCurrentEvents:
            targetButton = eventButton;
            break;
        case RFOccasionSports:
            targetButton = sportButton;
            break;
        case RFOccasionHoliday:
            targetButton = holidayButton;
            break;
    }

    return targetButton;
}

- (void)switchImageForOccasion:(RFOccasion)occasion {
    // NSLog(@"start switchImageForOccasion -- %i", occasion);
    
    UIButton *targetButton = [self buttonForOccasion:occasion];
    NSArray *occasionImages = [occasionImageDict objectForKey:[NSNumber numberWithInt:occasion]];

    if ([occasionImages count] > 0) {
        // select a random index from the images available for this occasion
        NSUInteger randomIndex = arc4random() % [occasionImages count];
        
        // assign the image to the button.
        [targetButton setBackgroundImage:[UIImage imageWithData:[occasionImages objectAtIndex:randomIndex]] forState:UIControlStateNormal];
    }
    // NSLog(@"end switchImageForOccasion");
}

- (void)updateOccasionImage {
    // NSLog(@"start updateOccasionImage");
    // select a random occasion
    NSUInteger randomIndex = arc4random() % [occasionKeys count];
    
    // update the image for the occasion
    [self switchImageForOccasion:[[occasionKeys objectAtIndex:randomIndex] intValue]];
    // NSLog(@"end updateOccasionImage");
}


// server API
- (void)getOccasionsFromServer {
//    NSLog(@"start getOccasionsFromServer");
    
    occasionData = [[NSMutableDictionary alloc] init];

    self.view.userInteractionEnabled = NO;
    
    NSObject *json = [[RFAPI singleton] resource:RFAPIResourceOccasion];    
    NSArray *occasions = (NSArray *)[json valueForKey:@"occasions"];
    
    for (NSDictionary *occasion in occasions) {
        NSString *targetName = [occasion valueForKey:@"name"];
        NSNumber *occasionKey = nil;
        
        if ([targetName isEqualToString:@"Celebrations"]) {
            occasionKey = [NSNumber numberWithInt:RFOccasionCelebration];
        }
        else if ([targetName isEqualToString:@"Current Events"]) {
            occasionKey = [NSNumber numberWithInt:RFOccasionCurrentEvents];
        }
        else if ([targetName isEqualToString:@"Holidays"]) {
            occasionKey = [NSNumber numberWithInt:RFOccasionHoliday];
        }
        else if ([targetName isEqualToString:@"Moods"]) {
            occasionKey = [NSNumber numberWithInt:RFOccasionMood];
        }
        else if ([targetName isEqualToString:@"Sports"]) {
            occasionKey = [NSNumber numberWithInt:RFOccasionSports];
        }
        else if ([targetName isEqualToString:@"Themes"]) {
            occasionKey = [NSNumber numberWithInt:RFOccasionThemes];
        }
        
        if (occasionKey) {
            [occasionData setObject:[[NSDictionary alloc] initWithDictionary:occasion] forKey:occasionKey];
        }
    }
    
    [loadingIndicator stopAnimating];
    self.view.userInteractionEnabled = YES;
    
    // DISABLED FOR NOW
    // [self performSelectorInBackground:@selector(fetchOccasionImages) withObject:nil];
    
//    NSLog(@"end getOccasionsFromServer");
}



#pragma mark - TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//    NSLog(@"start numberOfSelectionsInTableView");

    return sections;
    
//    NSLog(@"end numberOfSelectionsInTableView");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    NSLog(@"start tableView: numberOfRowsInSection:");

    return [[allSongsArray objectAtIndex:section] count];
    
//    NSLog(@"end tableView: numberOfRowsInSection:");

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"start tableView: cellForRowAtIndexPath:");

    static NSString *CellIdentifier = @"MoodCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.contentView.backgroundColor = [UIColor colorWithRed:0.1686f green:0.1686f blue:0.1686f alpha:1.0f];
        
        UIImage *horImage = [UIImage imageNamed:@"separator_horizontal.png"];
        UIImageView *horSeparator = [[UIImageView alloc] initWithImage:horImage];
        horSeparator.frame = CGRectMake(0, 0, horImage.size.width, horImage.size.height);
        horSeparator.tag = 1;
        [cell.contentView addSubview:horSeparator];
        
        UIImage *verImage = [UIImage imageNamed:@"separator_vertical.png"];
        UIImageView *verSeparator = [[UIImageView alloc] initWithImage:verImage];
        verSeparator.frame = CGRectMake(45, 1, verImage.size.width, verImage.size.height);
        verSeparator.tag = 2;
        [cell.contentView addSubview:verSeparator];
        
        UILabel *indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 45, 44)];
        indexLabel.tag = 3;
        indexLabel.textColor = [UIColor whiteColor];
        indexLabel.textAlignment = UITextAlignmentCenter;
        indexLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        indexLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:indexLabel];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(49, 0, 232, 44)];
        titleLabel.tag = 4;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        titleLabel.numberOfLines = 2;
        titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        titleLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:titleLabel];
        
        UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
        addButton.tag = 5;
        UIImage *addImage = [UIImage imageNamed:@"btn_add.png"];
        [addButton setImage:addImage forState:UIControlStateNormal];
        [addButton setFrame:CGRectMake(270, 0, 44, 44)];
        [addButton addTarget:self action:@selector(addToPlaylist:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:addButton];
        
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.center = CGPointMake(22.5, 22);
        spinner.hidesWhenStopped = YES;
        spinner.tag = 6;
        [cell.contentView addSubview:spinner];
        
        UIButton *stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
        stopButton.tag = 7;
        UIImage *stopImage = [UIImage imageNamed:@"btn_stop.png"];
        [stopButton setImage:stopImage forState:UIControlStateNormal];
        [stopButton setFrame:CGRectMake(1, 0, 44, 44)];
        [stopButton addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
        stopButton.hidden = YES;
        [cell.contentView addSubview:stopButton];
        
        UIButton *tikButton = [UIButton buttonWithType:UIButtonTypeCustom];
        tikButton.tag = 8;
        UIImage *tikImage = [UIImage imageNamed:@"song_check.png"];
        [tikButton setImage:tikImage forState:UIControlStateNormal];
        [tikButton setFrame:CGRectMake(280, 12, 22, 19)];
        [tikButton addTarget:self action:@selector(removeFromPlaylist:) forControlEvents:UIControlEventTouchUpInside];
        tikButton.hidden = YES;
        [cell.contentView addSubview:tikButton];
        
        UIView *colorBar = [[UIView alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width-5, 0, 5, cell.contentView.frame.size.height)];
        colorBar.tag = 9;
        [cell.contentView addSubview:colorBar];
    }
    
    UILabel *index = (UILabel *)[cell.contentView viewWithTag:3];
    index.text = [NSString stringWithFormat:@"%i", indexPath.row+1];
    UILabel *title = (UILabel *)[cell.contentView viewWithTag:4];
    NSArray *songsArray = [allSongsArray objectAtIndex:indexPath.section];
    title.text = [((NSDictionary *)[songsArray objectAtIndex:indexPath.row]) objectForKey:@"title"];
    
    NSDictionary *playlistDic = [NSDictionary dictionaryWithContentsOfFile:filePath];
    NSMutableArray *playlistArray = [[NSMutableArray alloc] initWithArray:[playlistDic objectForKey:@"songs"]];
    
    [cell.contentView viewWithTag:5].hidden = NO;
    [cell.contentView viewWithTag:8].hidden = YES;
    for (NSDictionary *dic in playlistArray) {
        if ([[dic valueForKey:@"ID"] intValue] == [[[songsArray objectAtIndex:indexPath.row] valueForKey:@"ID"] intValue]) {
            [cell.contentView viewWithTag:5].hidden = YES;
            [cell.contentView viewWithTag:8].hidden = NO;
            break;
        }
    }
    
    if (indexPath.row == plRow && indexPath.section == plSection) {
        [cell.contentView viewWithTag:3].hidden = YES;
        if (isPlaying) {
            [cell.contentView viewWithTag:7].hidden = NO;
            [(UIActivityIndicatorView *)[cell.contentView viewWithTag:6] stopAnimating];
        }
        else {
            [cell.contentView viewWithTag:7].hidden = YES;
            [(UIActivityIndicatorView *)[cell.contentView viewWithTag:6] startAnimating];
        }
    }
    else {
        [cell.contentView viewWithTag:3].hidden = NO;
        [cell.contentView viewWithTag:7].hidden = YES;
        [(UIActivityIndicatorView *)[cell.contentView viewWithTag:6] stopAnimating];
    }

//    NSLog(@"end tableView: cellForRowAtIndexPath:");
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"start tableView: didSelectRowAtIndexPath:");

    // revert previous cell changes
    UILabel *index = (UILabel *)[selectedCell.contentView viewWithTag:3];
    index.hidden = NO;
    if (audioPlayer != nil) {
        [audioPlayer pause];
    }
    UIButton *stop = (UIButton *)[selectedCell.contentView viewWithTag:7];
    stop.hidden = YES;
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[selectedCell.contentView viewWithTag:6];
    [spinner stopAnimating];
    isPlaying = NO;
    
    // change current cell views
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    index = (UILabel *)[cell.contentView viewWithTag:3];
    index.hidden = YES;
    spinner = (UIActivityIndicatorView *)[cell.contentView viewWithTag:6];
    [spinner startAnimating];
    selectedCell = cell;
    plRow = indexPath.row;
    plSection = indexPath.section;
    
    NSArray *songsArray = [allSongsArray objectAtIndex:indexPath.section];
    NSDictionary *song = (NSDictionary *)[songsArray objectAtIndex:indexPath.row];
    playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:[song objectForKey:@"url"]]];
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    audioPlayer = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    [table reloadData];
    
//    NSLog(@"end tableView: didSelectRowAtIndexPath:");
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    NSLog(@"start tableView: viewForHeaderInSection:");

    UIImageView *header = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 60)];
    header.image = [UIImage imageNamed:@"occasion_header_bg.png"];
    UIImageView *art = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    if ([images objectAtIndex:section] != @"") {
        art.image = [UIImage imageWithData:[images objectAtIndex:section]];
    }
    [header addSubview:art];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, 260, 20)];
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:16];
    title.backgroundColor = [UIColor clearColor];
    title.text = [titles objectAtIndex:section];
    [header addSubview:title];

    UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(60, 20, 260, 40)];
    description.textColor = [UIColor whiteColor];
    description.font = [UIFont systemFontOfSize:16];
    description.backgroundColor = [UIColor clearColor];
    description.text = [descriptions objectAtIndex:section];
    description.numberOfLines = 0;
    [header addSubview:description];
    
//    NSLog(@"end tableView: viewForHeaderInSection:");
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    NSLog(@"start and end tableView: heightForHeaderInSection:");

    return 60;
}


- (void)playerItemDidReachEnd:(NSNotification *)notification {
//    NSLog(@"start playerItemDidReachEnd");

    UIButton *stop = (UIButton *)[selectedCell.contentView viewWithTag:7];
    stop.hidden = YES;
    plRow = -1;
    plSection = -1;
    UILabel *index = (UILabel *)[selectedCell.contentView viewWithTag:3];
    index.hidden = NO;
    
    [playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [playerItem removeObserver:self forKeyPath:@"status"];
    playerItem = nil;
    audioPlayer = nil;
    [table reloadData];

//    NSLog(@"end playerItemDidReachEnd");
}

- (void)stop {
//    NSLog(@"start stop -- SHOULD NOT BE REACHED");

    [audioPlayer pause];
    [self playerItemDidReachEnd:nil];
    
//    NSLog(@"end stop");

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    NSLog(@"start observeValueForKeyPath");

    AVPlayerItem *item = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([item status] == AVPlayerItemStatusFailed) {
            UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[selectedCell.contentView viewWithTag:6];
            [spinner stopAnimating];

            UILabel *index = (UILabel *)[selectedCell.contentView viewWithTag:3];
            index.hidden = NO;
            NSLog(@"Error:%@", [item.error description]);
            
            [playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
            [playerItem removeObserver:self forKeyPath:@"status"];
            playerItem = nil;
            audioPlayer = nil;
            [table reloadData];
            
            // reload playlist
            level = 3;
            replaySong = YES;
            [self loadPlaylist:thirdButton];
        }
        return;
    }
    if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {   
        if (item.playbackLikelyToKeepUp) {
            [audioPlayer play];
            UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[selectedCell.contentView viewWithTag:6];
            [spinner stopAnimating];
            isPlaying = YES;
            UIButton *stop = (UIButton *)[selectedCell.contentView viewWithTag:7];
            stop.hidden = NO;
            [table reloadData];
        }
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//    NSLog(@"end observeValueForKeyPath");
}


// Alert delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//    NSLog(@"start alertView");
    if (buttonIndex == 1) {
        [loadingIndicator startAnimating];
        [self performSelectorInBackground:@selector(getOccasionsFromServer) withObject:nil];
    }
//    NSLog(@"end alertView");
}

- (void)alertWithError:(NSString *)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];    
}


@end
