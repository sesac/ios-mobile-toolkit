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

#import "PlaylistVC.h"
#import "SBJson.h"
#import "LocalPlaylist.h"

@implementation PlaylistVC

UITableViewCell *selectedCell;
int rowPlaying = -1;
AVPlayer *playlistAudioPlayer;
AVPlayerItem *playlistPlayerItem;
bool isPlaying;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Playlist";
    
    UIButton *removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *removeImage = [UIImage imageNamed:@"btn_removeall.png"];
    [removeButton setImage:removeImage forState:UIControlStateNormal];
    removeButton.frame = CGRectMake(0, 0, removeImage.size.width, removeImage.size.height);
    [removeButton addTarget:self action:@selector(removeAll) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithCustomView:removeButton];
    self.navigationItem.rightBarButtonItem = rightButton;
    
    self.tableView.separatorColor = [UIColor colorWithRed:0.08f green:0.08f blue:0.08f alpha:1.0f];
    self.tableView.backgroundColor = [UIColor colorWithRed:0.1568f green:0.1529f blue:0.1451f alpha:1.0f];
    
    selectedCell = [[UITableViewCell alloc] init];
    
    // Registers this class as the delegate of the audio session.
    [[AVAudioSession sharedInstance] setDelegate: self];    
    // Allow the app sound to continue to play when the screen is locked.
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
    else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (rowPlaying >= 0) {
        [self stop];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isLandscape"];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        [self.tableView reloadData];
    }
    else if (toInterfaceOrientation == UIInterfaceOrientationPortrait) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isLandscape"];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [self.tableView reloadData];
    }
}

- (void)removeAll {
    if (rowPlaying >= 0 && isPlaying) {
        [self stop];
    }
    rowPlaying = -1;
    [[LocalPlaylist sharedPlaylist] clear];
    [self.tableView reloadData];
}

- (void)remove:(UIButton *)button {
    int row = [[self.tableView indexPathForCell:(UITableViewCell *)[[button superview] superview]] row];
    if (row == rowPlaying) {
        [self stop];
    }
    else if (row <rowPlaying) {
        rowPlaying--;
    }
    
    [[LocalPlaylist sharedPlaylist] removeAtIndex:row];
    [self.tableView reloadData];
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
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(49, 0, 232, 44)];
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
        [deleteButton setFrame:CGRectMake(280, 0, 44, 44)];
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
    
    UILabel *index = (UILabel *)[cell.contentView viewWithTag:3];
    index.text = [NSString stringWithFormat:@"%i", indexPath.row+1];
    UILabel *title = (UILabel *)[cell.contentView viewWithTag:4];
    
    title.text = [[LocalPlaylist sharedPlaylist] mediaAtIndex:indexPath.row].title;
    
    if (indexPath.row == rowPlaying) {
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
    
    // handle orientation
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft) {
        [cell.contentView viewWithTag:5].frame = CGRectMake(436, 0, 44, 44);
    } else {
        [cell.contentView viewWithTag:5].frame = CGRectMake(276, 0, 44, 44);
    }
    
    return cell;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // revert previous cell changes
    UILabel *index = (UILabel *)[selectedCell.contentView viewWithTag:3];
    index.hidden = NO;
    if (playlistAudioPlayer != nil && rowPlaying >= 0) {
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
    rowPlaying = indexPath.row;
    [self.tableView reloadData];
    [self play];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ([self numberOfSectionsInTableView:tableView] == section+1){
        return [UIView new];
    }
    return [super tableView:tableView viewForFooterInSection:section];
}

- (void)play {
    Media *media = [[LocalPlaylist sharedPlaylist] mediaAtIndex:rowPlaying];
    
    playlistPlayerItem = [[AVPlayerItem alloc] initWithURL:media.previewURL];
    [playlistPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [playlistPlayerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playlistPlayerItem];
    playlistAudioPlayer = [[AVPlayer alloc] initWithPlayerItem:playlistPlayerItem];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    UIButton *stop = (UIButton *)[selectedCell.contentView viewWithTag:7];
    stop.hidden = YES;
    rowPlaying = -1;
    UILabel *index = (UILabel *)[selectedCell.contentView viewWithTag:3];
    index.hidden = NO;
    
    [playlistPlayerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [playlistPlayerItem removeObserver:self forKeyPath:@"status"];
    playlistPlayerItem = nil;
    playlistAudioPlayer = nil;
    [self.tableView reloadData];
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
            
            [playlistPlayerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
            [playlistPlayerItem removeObserver:self forKeyPath:@"status"];
            [self.tableView reloadData];
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
            [self.tableView reloadData];
        }
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
