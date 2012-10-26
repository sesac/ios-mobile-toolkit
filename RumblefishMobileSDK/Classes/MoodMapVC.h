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
#import <AVFoundation/AVFoundation.h>
#import "RFAPI.h"


@interface MoodMapControllerView : UIView

@property (nonatomic, assign) IBOutlet UITableView *tableView;

@end

@interface MoodMapVC : UIViewController<UITableViewDelegate, UITableViewDataSource, NSURLConnectionDelegate> {
    IBOutlet UIImageView *glow, *ring, *selector, *moodmap, *welcome;
    IBOutlet UIButton *doneButton, *playlistButton, *filterButton;
    IBOutlet UITableView *tabView;
    Playlist *playlist;
    int playlistID, selectedCellID;
}

- (IBAction)doneButtonPressed;
- (IBAction)playlistButtonPressed;

@end
