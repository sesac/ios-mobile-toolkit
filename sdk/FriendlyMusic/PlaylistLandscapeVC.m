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

#import "PlaylistLandscapeVC.h"
#import "SBJson.h"
#import "LocalPlaylist.h"

@implementation PlaylistLandscapeVC

NSString *filePath, *srv;
UITableViewCell *selectedCell;
int rowPlay;
AVPlayer *playlistAudioPlayer;
AVPlayerItem *playlistPlayerItem;
bool isPlaying;
NSMutableData *serverData;

@synthesize tabview = _tabview;

- (void)viewDidLoad
{    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 480, 44)];
    toolbar.tintColor = [UIColor colorWithRed:0.145f green:0.145f blue:0.145f alpha:1.0];
    rowPlay = -1;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    filePath = [[NSString alloc] initWithString:[documentsDirectory stringByAppendingPathComponent:@"playlist.plist"]];
    
    selectedCell = [[UITableViewCell alloc] init];
    
    UIButton *removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *removeImage = [UIImage imageNamed:@"btn_removeall.png"];
    [removeButton setImage:removeImage forState:UIControlStateNormal];
    removeButton.frame = CGRectMake(390, 8, removeImage.size.width, removeImage.size.height);
    [removeButton addTarget:self action:@selector(removeAll) forControlEvents:UIControlEventTouchUpInside];
    [toolbar addSubview:removeButton];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(200, 0, 120, 44)];
    title.text = @"Playlist";
    title.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
    title.textColor = [UIColor whiteColor];
    title.backgroundColor = [UIColor clearColor];
    [toolbar addSubview:title];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(goBack)];
    [toolbar setItems:[NSArray arrayWithObject:backButton]];
    
    [self.view addSubview:toolbar];

    // set up the table view
    self.tabview = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, 480, 276) style:UITableViewStylePlain];
    self.tabview.delegate = self;
    self.tabview.dataSource = self;
    self.tabview.separatorColor = [UIColor colorWithRed:0.08f green:0.08f blue:0.08f alpha:1.0f];
    self.tabview.backgroundColor = [UIColor colorWithRed:0.125f green:0.125f blue:0.125f alpha:1.0f];
    [self.view addSubview:self.tabview];
    
    // Registers this class as the delegate of the audio session.
    [[AVAudioSession sharedInstance] setDelegate: self];    
    // Allow the app sound to continue to play when the screen is locked.
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}


- (void)removeAll {
    if (isPlaying && rowPlay >= 0) {
        [self stop];
    }
    rowPlay = -1;
    [[LocalPlaylist sharedPlaylist] clear];
    [self.tabview reloadData];
}

- (void)remove:(UIButton *)button {
    int row = [[self.tabview indexPathForCell:(UITableViewCell *)[[button superview] superview]] row];
    if (row == rowPlay) {
        [self stop];
    }
    else if (row <rowPlay) {
        rowPlay--;
    }
    
    [[LocalPlaylist sharedPlaylist] removeAtIndex:row];
    [self.tabview reloadData];
}

- (void)goBack {
    if (rowPlay >= 0) {
        [self stop];
    }
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [LocalPlaylist sharedPlaylist].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PlaylistCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.contentView.backgroundColor = [UIColor colorWithRed:0.1686f green:0.1686f blue:0.1686f alpha:1.0f];
        
        UIImage *horImage = [UIImage imageNamed:@"separator_horizontal.png"];
        UIImageView *horSeparator = [[UIImageView alloc] initWithImage:horImage];
        horSeparator.frame = CGRectMake(0, 0, 480, horImage.size.height);
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
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(52, 0, 380, 44)];
        titleLabel.tag = 4;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        titleLabel.numberOfLines = 2;
        titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        titleLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:titleLabel];
        
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *deleteImage = [UIImage imageNamed:@"btn_remove.png"];
        [deleteButton setImage:deleteImage forState:UIControlStateNormal];
        [deleteButton setFrame:CGRectMake(440, 0, deleteImage.size.width, deleteImage.size.height)];
        [deleteButton addTarget:self action:@selector(remove:) forControlEvents:UIControlEventTouchUpInside];
        deleteButton.tag = 5;
        [cell.contentView addSubview:deleteButton];
        
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.center = CGPointMake(22.5, 22);
        spinner.hidesWhenStopped = YES;
        spinner.tag = 6;
        [cell.contentView addSubview:spinner];
        
        UIButton *stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
        stopButton.tag = 7;
        UIImage *stopImage = [UIImage imageNamed:@"btn_stop.png"];
        [stopButton setImage:stopImage forState:UIControlStateNormal];
        [stopButton setFrame:CGRectMake(1, 0, stopImage.size.width, stopImage.size.height)];
        [stopButton addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
        stopButton.hidden = YES;
        [cell.contentView addSubview:stopButton];
    }
    
    Media *currentMedia = [[LocalPlaylist sharedPlaylist] mediaAtIndex:indexPath.row];
    
    UILabel *index = (UILabel *)[cell.contentView viewWithTag:3];
    index.text = [NSString stringWithFormat:@"%i", indexPath.row+1];
    UILabel *title = (UILabel *)[cell.contentView viewWithTag:4];
    title.text = currentMedia.title;
    
    if (indexPath.row == rowPlay) {
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
    
    return cell;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // revert previous cell changes
    UILabel *index = (UILabel *)[selectedCell.contentView viewWithTag:3];
    index.hidden = NO;
    if (playlistAudioPlayer != nil && rowPlay >= 0) {
        [playlistAudioPlayer pause];
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
    rowPlay = indexPath.row;
    
    Media *currentMedia = [[LocalPlaylist sharedPlaylist] mediaAtIndex:indexPath.row];
    playlistPlayerItem = [[AVPlayerItem alloc] initWithURL:currentMedia.previewURL];
    [playlistPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [playlistPlayerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playlistPlayerItem];
    playlistAudioPlayer = [[AVPlayer alloc] initWithPlayerItem:playlistPlayerItem];
    [self.tabview reloadData];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ([self numberOfSectionsInTableView:tableView] == section+1){
        return [UIView new];
    }
    return nil;
}


- (void)playerItemDidReachEnd:(NSNotification *)notification {
    UIButton *stop = (UIButton *)[selectedCell.contentView viewWithTag:7];
    stop.hidden = YES;
    rowPlay = -1;
    UILabel *index = (UILabel *)[selectedCell.contentView viewWithTag:3];
    index.hidden = NO;
    
    [playlistPlayerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [playlistPlayerItem removeObserver:self forKeyPath:@"status"];
    playlistPlayerItem = nil;
    playlistAudioPlayer = nil;
    [self.tabview reloadData];
}

- (void)play {
    Media *currentMedia = [[LocalPlaylist sharedPlaylist] mediaAtIndex:rowPlay];
    playlistPlayerItem = [[AVPlayerItem alloc] initWithURL:currentMedia.previewURL];
    [playlistPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [playlistPlayerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playlistPlayerItem];
    playlistAudioPlayer = [[AVPlayer alloc] initWithPlayerItem:playlistPlayerItem];
}

- (void)stop {
    [playlistAudioPlayer pause];
    [self playerItemDidReachEnd:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *item = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([item status] == AVPlayerItemStatusFailed) {
            UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[selectedCell.contentView viewWithTag:6];
            [spinner stopAnimating];
            
            UILabel *index = (UILabel *)[selectedCell.contentView viewWithTag:3];
            index.hidden = NO;
            NSLog(@"Error:%@", [item.error description]);
            
            [playlistPlayerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
            [playlistPlayerItem removeObserver:self forKeyPath:@"status"];
        }
        return;
    }
    if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {   
        if (item.playbackLikelyToKeepUp) {
            [playlistAudioPlayer play];
            UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[selectedCell.contentView viewWithTag:6];
            [spinner stopAnimating];
            isPlaying = YES;
            UIButton *stop = (UIButton *)[selectedCell.contentView viewWithTag:7];
            stop.hidden = NO;
            [self.tabview reloadData];
        }
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
