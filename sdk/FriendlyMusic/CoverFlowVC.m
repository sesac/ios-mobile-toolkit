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

#import "CoverFlowVC.h"
#import "AlbumLandscapeVC.h"
#import "PlaylistLandscapeVC.h"
#import "SBJson.h"
#import "NSObject+AssociateProducer.h"

@interface CoverflowCoverView : TKCoverflowCoverView

@property (nonatomic, strong) Playlist *playlist;

@end

@implementation CoverflowCoverView

@synthesize playlist = _playlist;

- (void)setPlaylist:(Playlist *)value {
    [self deassociateProducer];
    _playlist = value;
    self.image = nil;
    if (value.imageURL) {
        NSLog(@"Will request image for playlist %@", value.imageURL);
        [self associateProducer:[[RFAPI singleton] getImageAtURL:value.imageURL] callback:^ void (id i) {
            self.image = (UIImage *)i;
        }];
    }
}

@end

@interface CoverFlowVC ()

@property (nonatomic, copy) NSArray *playlists;

@end


@implementation CoverFlowVC

@synthesize playlists;
@synthesize spinner;
@synthesize coverflow;
@synthesize albumLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];             
    self.view.frame = CGRectMake(0, 0, 480, 320);
    self.view.backgroundColor = [UIColor blackColor];
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 480, 44)];
    toolbar.tintColor = [UIColor colorWithRed:0.145f green:0.145f blue:0.145f alpha:1.0];
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(goBack)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    space.width = 112;
    UIImageView *titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"friendlymusic_logo.png"]];
    UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithCustomView:titleView];
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Playlist" style: UIBarButtonItemStyleBordered target:self action:@selector(gotoPlaylist)];
    
    toolbar.items = [NSArray arrayWithObjects:leftButton, space, title, space, rightButton, nil];
    [self.view addSubview:toolbar];

    // coverview
    TKCoverflowView *localCF = [[TKCoverflowView alloc] initWithFrame:CGRectMake(0, 44, 480, 276)];
    localCF.coverflowDelegate = self;
    localCF.dataSource = self;
    
    [self setCoverflow:localCF];
    [self.view addSubview:[self coverflow]];
    

    // label
    UILabel *localLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 290, 480, 20)];
    localLabel.textColor = [UIColor whiteColor];
    localLabel.backgroundColor = [UIColor clearColor];
    localLabel.textAlignment = UITextAlignmentCenter;
    localLabel.font = [UIFont boldSystemFontOfSize:16];
    
    [self setAlbumLabel:localLabel];
    [self.view addSubview:[self albumLabel]];

    
    // spinner
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spinner.center = self.view.center;
    [self.view addSubview:self.spinner];

    
    [self getPlaylistFromServer];
}


- (void)viewDidUnload
{
    self.coverflow = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];                 
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)goBack {
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)gotoPlaylist {
    PlaylistLandscapeVC *playlist = [[PlaylistLandscapeVC alloc] init];
    [playlist setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self presentModalViewController:playlist animated:YES];
}

// Coverflow methods

- (void)coverflowView:(TKCoverflowView*)coverflowView coverAtIndexWasBroughtToFront:(int)index {
	self.albumLabel.text = ((Playlist *)[self.playlists objectAtIndex:index]).title;
}

- (TKCoverflowCoverView*)coverflowView:(TKCoverflowView*)coverflowView coverAtIndex:(int)index {
	CoverflowCoverView *cover = (CoverflowCoverView *)[coverflowView dequeueReusableCoverView];
	
	if(cover == nil) {
		cover = [[CoverflowCoverView alloc] initWithFrame:CGRectMake(0, 0, 224, 300)];
		cover.baseline = 224;
	}
    
	cover.playlist = [self.playlists objectAtIndex:index];
    
	return cover;
}

- (void)coverflowView:(TKCoverflowView*)coverflowView coverAtIndexWasDoubleTapped:(int)index{
    Playlist *playlist = (Playlist *)[playlists objectAtIndex:index];
    
	AlbumLandscapeVC *albumController = [[AlbumLandscapeVC alloc] initWithPlaylist:playlist];
    
    [albumController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self presentModalViewController:albumController animated:YES];
}

- (void)getPlaylistFromServer {
    [self.spinner startAnimating];
    Producer getPlaylists = [[RFAPI singleton] getPlaylistsWithOffset:0];    
    [self associateProducer:getPlaylists callback:^ (id results) {
        self.playlists = (NSArray *)results;
        self.coverflow.numberOfCovers = playlists.count;
        [self.spinner stopAnimating];
    }];
}

@end
