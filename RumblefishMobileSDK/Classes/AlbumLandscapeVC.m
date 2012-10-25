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

#import "AlbumLandscapeVC.h"
#import "SBJson/SBJson.h"
#import <AVFoundation/AVFoundation.h>
#import "LocalPlaylist.h"
#import "NSObject+AssociateProducer.h"
#import "UIImage+RumblefishSDKResources.h"

@interface AlbumLandscapeVC ()

@property (nonatomic, strong) Playlist *playlist;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation AlbumLandscapeVC

int playRow;
bool isPlaying;
NSString *srv;
UITableViewCell *selectedCell;
AVPlayer *audioPlayer;
AVPlayerItem *playerItem;

@synthesize playlist;
@synthesize tabview = _tabview;
@synthesize activityIndicator;

- (id)initWithPlaylist:(Playlist *)lePlaylist {
    if (self = [super init]) {
        self.playlist = lePlaylist;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    selectedCell = [[UITableViewCell alloc] init];
    playRow = -1;
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 480, 44)];
    toolbar.tintColor = [UIColor colorWithRed:0.145f green:0.145f blue:0.145f alpha:1.0];
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [toolbar setItems:[NSArray arrayWithObject:closeButton]];
    
    UILabel *title1 = [[UILabel alloc] initWithFrame:CGRectMake(100, 0, 280, 44)];
    title1.text = playlist.title;
    title1.textAlignment = NSTextAlignmentCenter;
    title1.font = [UIFont fontWithName:@"Helvetica-Bold" size:24];
    title1.textColor = [UIColor whiteColor];
    title1.backgroundColor = [UIColor clearColor];
    [toolbar addSubview:title1];
    
    UILabel *title2 = [[UILabel alloc] initWithFrame:CGRectMake(100, 25, 280, 19)];
    title2.text = @"";
    title2.textAlignment = NSTextAlignmentCenter;
    title2.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
    title2.textColor = [UIColor whiteColor];
    title2.backgroundColor = [UIColor clearColor];
    [toolbar addSubview:title2];
    
    [self.view addSubview:toolbar];
    
    if (self.tabview == nil) {
        UITableView *localTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, 480, 276) style:UITableViewStylePlain];
        localTableView.delegate = self;
        localTableView.dataSource = self;
        localTableView.separatorColor = [UIColor colorWithRed:0.08f green:0.08f blue:0.08f alpha:1.0f];
        localTableView.backgroundColor = [UIColor colorWithRed:0.125f green:0.125f blue:0.125f alpha:1.0f];
        [self.view addSubview:localTableView];
        [self setTabview:localTableView];
    }
    
    activityIndicator = [[UIActivityIndicatorView alloc] init];
    [activityIndicator sizeToFit];
    activityIndicator.frame = CGRectMake(
        (self.tabview.frame.size.width - activityIndicator.frame.size.width) / 2, 
        (self.tabview.frame.size.height - activityIndicator.frame.size.height) / 2, 
        activityIndicator.frame.size.width, 
        activityIndicator.frame.size.height);
    [self.view addSubview:activityIndicator];
    
    // Registers this class as the delegate of the audio session.
    [[AVAudioSession sharedInstance] setDelegate: self];    
    // Allow the app sound to continue to play when the screen is locked.
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [self getPlaylistFromServer:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)close {
    if (playRow >= 0) {
        [self stop];
    }
    [self.tabview reloadData];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return playlist.media.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AlbumCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.contentView.backgroundColor = [UIColor colorWithRed:0.1686f green:0.1686f blue:0.1686f alpha:1.0f];
        
        UIImage *horImage = [UIImage imageInResourceBundleNamed:@"separator_horizontal.png"];
        UIImageView *horSeparator = [[UIImageView alloc] initWithImage:horImage];
        horSeparator.frame = CGRectMake(0, 0, 480, horImage.size.height);
        horSeparator.tag = 1;
        [cell.contentView addSubview:horSeparator];
        
        UIImage *verImage = [UIImage imageInResourceBundleNamed:@"separator_vertical.png"];
        UIImageView *verSeparator = [[UIImageView alloc] initWithImage:verImage];
        verSeparator.frame = CGRectMake(45, 1, verImage.size.width, verImage.size.height);
        verSeparator.tag = 2;
        [cell.contentView addSubview:verSeparator];
        
        UILabel *indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 45, 44)];
        indexLabel.tag = 3;
        indexLabel.textColor = [UIColor whiteColor];
        indexLabel.textAlignment = NSTextAlignmentCenter;
        indexLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        indexLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:indexLabel];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(52, 0, 380, 44)];
        titleLabel.tag = 4;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        titleLabel.numberOfLines = 2;
        titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        titleLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:titleLabel];
        
        UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
        addButton.tag = 5;
        UIImage *addImage = [UIImage imageInResourceBundleNamed:@"btn_add.png"];
        [addButton setImage:addImage forState:UIControlStateNormal];
        [addButton setFrame:CGRectMake(435, 0, 44, 44)];
        [addButton addTarget:self action:@selector(addToPlaylist:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:addButton];
        
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.center = CGPointMake(22.5, 22);
        spinner.hidesWhenStopped = YES;
        spinner.tag = 6;
        [cell.contentView addSubview:spinner];
        
        UIButton *stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
        stopButton.tag = 7;
        UIImage *stopImage = [UIImage imageInResourceBundleNamed:@"btn_stop.png"];
        [stopButton setImage:stopImage forState:UIControlStateNormal];
        [stopButton setFrame:CGRectMake(1, 0, 44, 44)];
        [stopButton addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
        stopButton.hidden = YES;
        [cell.contentView addSubview:stopButton];
        
        UIButton *tikButton = [UIButton buttonWithType:UIButtonTypeCustom];
        tikButton.tag = 8;
        UIImage *tikImage = [UIImage imageInResourceBundleNamed:@"song_check.png"];
        [tikButton setImage:tikImage forState:UIControlStateNormal];
        [tikButton setFrame:CGRectMake(445, 12, 22, 19)];
        [tikButton addTarget:self action:@selector(removeFromPlaylist:) forControlEvents:UIControlEventTouchUpInside];
        tikButton.hidden = YES;
        [cell.contentView addSubview:tikButton];
    }
    Media *currentMedia = [playlist.media objectAtIndex:indexPath.row];
    
    UILabel *index = (UILabel *)[cell.contentView viewWithTag:3];
    index.text = [NSString stringWithFormat:@"%i", indexPath.row+1];
    UILabel *title = (UILabel *)[cell.contentView viewWithTag:4];
    title.text = currentMedia.title;
    
    [cell.contentView viewWithTag:5].hidden = NO;
    [cell.contentView viewWithTag:8].hidden = YES;
    
    if ([[LocalPlaylist sharedPlaylist] existsInPlaylist:currentMedia]) {
        [cell.contentView viewWithTag:5].hidden = YES;
        [cell.contentView viewWithTag:8].hidden = NO;
    }
    
    if (indexPath.row == playRow) {
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

// server API
- (void)getPlaylistFromServer:(BOOL)play {
    Producer getPlaylist = [[RFAPI singleton] getPlaylist:playlist.ID];
    [activityIndicator startAnimating];
    
    [self associateProducer:getPlaylist callback:^ (id result) {
        self.playlist = (Playlist *)result;
        
        if (play && playlist.media.count) {
            int row = playRow == -1 ? 0 : playRow;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            [self.tabview selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            [self.tabview.delegate tableView:self.tabview didSelectRowAtIndexPath:indexPath];
            if (row == 0) {
                [self.tabview scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
        }
        [self.tabview reloadData];
        [activityIndicator stopAnimating];
    }];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
    playRow = indexPath.row;

    Media *currentMedia = [playlist.media objectAtIndex:indexPath.row];
    playerItem = [[AVPlayerItem alloc] initWithURL:currentMedia.previewURL];
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    audioPlayer = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    [self.tabview reloadData];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ([self numberOfSectionsInTableView:tableView] == section+1){
        return [UIView new];
    }
    return nil;
}

- (void)addToPlaylist:(UIButton *)button {
    int row = [[self.tabview indexPathForCell:(UITableViewCell *)[[button superview] superview]] row];
    
    Media *currentMedia = [playlist.media objectAtIndex:row];
    [[LocalPlaylist sharedPlaylist] addToPlaylist:currentMedia];
    
    button.hidden = YES;
    [[button superview] viewWithTag:8].hidden = NO;
}

- (void)removeFromPlaylist:(UIButton *)button {
    int row = [[self.tabview indexPathForCell:(UITableViewCell *)[[button superview] superview]] row];
    
    Media *currentMedia = [playlist.media objectAtIndex:row];
    [[LocalPlaylist sharedPlaylist] removeFromPlaylist:currentMedia];
    
    button.hidden = YES;
    [[button superview] viewWithTag:5].hidden = NO;    
}


- (void)stop {
    [audioPlayer pause];
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
            
            [playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
            [playerItem removeObserver:self forKeyPath:@"status"];
            playerItem = nil;
            audioPlayer = nil;
            [self.tabview reloadData];
            [self getPlaylistFromServer:YES];
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
            [self.tabview reloadData];
        }
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    UIButton *stop = (UIButton *)[selectedCell.contentView viewWithTag:7];
    stop.hidden = YES;
    playRow = -1;
    UILabel *index = (UILabel *)[selectedCell.contentView viewWithTag:3];
    index.hidden = NO;
    
    [playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [playerItem removeObserver:self forKeyPath:@"status"];
    playerItem = nil;
    audioPlayer = nil;
    [self.tabview reloadData];
}

@end
