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

@implementation PlaylistLandscapeVC

NSString *filePath, *srv;
UITableViewCell *selectedCell;
int rowPlay;
AVPlayer *playlistAudioPlayer;
AVPlayerItem *playlistPlayerItem;
bool isPlaying;
NSMutableData *serverData;

@synthesize tabview = _tabview;
@synthesize playlistArray = _playlistArray;
@synthesize playlistDic = _playlistDic;
@synthesize serverConnection = _serverConnection;

- (void)viewDidLoad
{
    NSLog(@"viewDidLoad");

    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
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
    UITableView *localTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, 480, 276) style:UITableViewStylePlain];
    localTableView.delegate = self;
    localTableView.dataSource = self;
    localTableView.separatorColor = [UIColor colorWithRed:0.08f green:0.08f blue:0.08f alpha:1.0f];
    localTableView.backgroundColor = [UIColor colorWithRed:0.125f green:0.125f blue:0.125f alpha:1.0f];
    [self setTabview:localTableView];
    [self.view addSubview:localTableView];

    self.tabview.separatorColor = [UIColor colorWithRed:0.08f green:0.08f blue:0.08f alpha:1.0f];
    self.tabview.backgroundColor = [UIColor colorWithRed:0.1568f green:0.1529f blue:0.1451f alpha:1.0f];
    
    // Registers this class as the delegate of the audio session.
    [[AVAudioSession sharedInstance] setDelegate: self];    
    // Allow the app sound to continue to play when the screen is locked.
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
}

- (void)viewDidUnload
{
    NSLog(@"viewDidUnload");

    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"viewWillAppear");

    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.playlistDic = [[NSMutableDictionary alloc] initWithDictionary:[NSMutableDictionary dictionaryWithContentsOfFile:filePath]];
    self.playlistArray = [[NSMutableArray alloc] initWithArray:[self.playlistDic objectForKey:@"songs"]];
    [self.tabview reloadData];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}


- (void)removeAll {
    NSLog(@"removeAll");
    if (isPlaying && rowPlay >= 0) {
        [self stop];
    }
    rowPlay = -1;
    [self.playlistArray removeAllObjects];
    [self.playlistDic setObject:self.playlistArray forKey:@"songs"];
    [self.playlistDic writeToFile:filePath atomically:YES];
    [self.tabview reloadData];
}

- (void)remove:(UIButton *)button {
    NSLog(@"remove");
    
    int row = [[self.tabview indexPathForCell:(UITableViewCell *)[[button superview] superview]] row];
    if (row == rowPlay) {
        [self stop];
    }
    else if (row <rowPlay) {
        rowPlay--;
    }
    
    [self.playlistArray removeObjectAtIndex:row];
    [self.playlistDic setObject:self.playlistArray forKey:@"songs"];
    [self.playlistDic writeToFile:filePath atomically:YES];
    [self.tabview reloadData];
}

- (void)goBack {
    NSLog(@"goBack");

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
    NSLog(@"tableView");
    return [self.playlistArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"tableView cellForRowAtIndexPath");

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
    
    UILabel *index = (UILabel *)[cell.contentView viewWithTag:3];
    index.text = [NSString stringWithFormat:@"%i", indexPath.row+1];
    UILabel *title = (UILabel *)[cell.contentView viewWithTag:4];
    title.text = [((NSDictionary *)[self.playlistArray objectAtIndex:indexPath.row]) objectForKey:@"title"];
    
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
    NSLog(@"tableView didSelectRowAtIndexPath");

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
    
    NSDictionary *song = (NSDictionary *)[self.playlistArray objectAtIndex:indexPath.row];
    playlistPlayerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:[song objectForKey:@"url"]]];
    [playlistPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [playlistPlayerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playlistPlayerItem];
    playlistAudioPlayer = [[AVPlayer alloc] initWithPlayerItem:playlistPlayerItem];
    [self.tabview reloadData];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    NSLog(@"tableView viewForFooterInSection");

    if ([self numberOfSectionsInTableView:tableView] == section+1){
        return [UIView new];
    }
    return nil;
}


- (void)playerItemDidReachEnd:(NSNotification *)notification {
    NSLog(@"playerItemDidReachEnd");

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
    NSLog(@"play");

    NSDictionary *song = (NSDictionary *)[self.playlistArray objectAtIndex:rowPlay];
    playlistPlayerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:[song objectForKey:@"url"]]];
    [playlistPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [playlistPlayerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playlistPlayerItem];
    playlistAudioPlayer = [[AVPlayer alloc] initWithPlayerItem:playlistPlayerItem];
}

- (void)stop {
    NSLog(@"stop");

    [playlistAudioPlayer pause];
    [self playerItemDidReachEnd:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"observeValueForKeyPath ofObject change context");

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
            [self.tabview reloadData];
            
            // get song's new url and replay
            NSDictionary *song = (NSDictionary *)[self.playlistArray objectAtIndex:rowPlay];
            NSString *ID = [song objectForKey:@"ID"];
            
            self.serverConnection = [[RFAPI singleton] resource:RFAPIResourceMedia withID:ID delegate:self];
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


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"connection didReceiveResponse");

    serverData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"connection didReceiveData");

    [serverData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {    
    NSLog(@"connection didFailWithError");

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Can not load the song. Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[selectedCell.contentView viewWithTag:6];
    [spinner stopAnimating];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    NSLog(@"connectionDidFinishLoading");

    //playlistIsLoading = NO;
    NSString *resultString = [[NSString alloc] initWithData:serverData encoding:NSUTF8StringEncoding];
    SBJsonParser *jsonParser = [SBJsonParser new];
    NSObject *json = [jsonParser objectWithString:resultString error:NULL];
    NSDictionary *media = (NSDictionary *)[json valueForKey:@"media"];
    NSString *newUrl = [media objectForKey:@"preview_url"];
    NSMutableDictionary *song = [[NSMutableDictionary alloc] initWithDictionary:[self.playlistArray objectAtIndex:rowPlay]];
    
    [song setObject:newUrl forKey:@"url"];
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    for (int i=0; i<[self.playlistArray count]; i++) {
        if (i == rowPlay) {
            [tempArray addObject:song];
        }
        else {
            [tempArray addObject:[self.playlistArray objectAtIndex:i]];
        }
    }
    
    [self.playlistDic setObject:tempArray forKey:@"songs"];
    [self.playlistDic writeToFile:filePath atomically:YES];
    [self.playlistArray removeAllObjects];
    self.playlistArray = [[NSMutableArray alloc] initWithArray:tempArray];
    [self play];
}

@end
