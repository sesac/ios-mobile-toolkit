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
#import "SBJson/SBJson.h"
#import "NSObject+AssociateProducer.h"
#import "Sequence.h"
#import "UIImage+RumblefishSDKResources.h"
#import "NSBundle+RumblefishMobileSDKResources.h"

@interface CoverflowCoverView : TKCoverflowCoverView

@property (nonatomic, strong) Playlist *playlist;

@end

@implementation CoverflowCoverView

@synthesize playlist = _playlist;

- (void)setImage:(UIImage *)value {
    if (!value)
        value = [UIImage imageInResourceBundleNamed:@"CoverFlowPlaceholder.png"];
    [super setImage:value];
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.image = nil; // force placeholder to appear
    }
    return self;
}

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

- (void)layoutSubviews {
    self.imageView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.width);
    self.reflected.frame = CGRectMake(0, self.bounds.size.width, self.bounds.size.width, self.bounds.size.height);
    self.gradientLayer.frame = CGRectMake(0, self.bounds.size.width, self.bounds.size.width, self.bounds.size.height);
    
	if (self.image) {
        self.imageView.image = self.image;
        
        float w = self.image.size.width;
        float h = self.image.size.height;
        float factor = self.bounds.size.width / (h>w?h:w);
        h = factor * h;
        w = factor * w;
        float y = self.baseline - h > 0 ? self.baseline - h : 0;
        self.imageView.frame = CGRectMake(0, y, w, h);
        
        self.gradientLayer.frame = CGRectMake(0, y + h, w, h);
        
        self.reflected.frame = CGRectMake(0, y + h, w, h);
        self.reflected.image = self.image;
    }
}

@end

@interface NSObject (CoverFlowVCViewDelegate)

- (void)backTapped;
- (void)playlistTapped;

@end

@interface CoverFlowVCView : UIView

@property (nonatomic, assign) id delegate;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) TKCoverflowView *coverFlowView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation CoverFlowVCView

@synthesize toolbar, coverFlowView, label, activityIndicator;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
        
        self.coverFlowView = [[TKCoverflowView alloc] initWithFrame:CGRectZero];
        [self addSubview:coverFlowView];
        
        self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
        toolbar.tintColor = [UIColor colorWithRed:0.145f green:0.145f blue:0.145f alpha:1.0];
        UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(backTapped)];
        UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIImageView *titleView = [[UIImageView alloc] initWithImage:[UIImage imageInResourceBundleNamed:@"friendlymusic_logo.png"]];
        UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithCustomView:titleView];
        UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Playlist" style: UIBarButtonItemStyleBordered target:self action:@selector(playlistTapped)];
        
        toolbar.items = [NSArray arrayWithObjects:leftButton, space, title, space, rightButton, nil];
        [self addSubview:toolbar];
        
        self.label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:16];
        [self addSubview:label];
        
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:activityIndicator];
    }
    return self;
}

- (void)layoutSubviews {
    [toolbar sizeToFit];
    toolbar.frame = CGRectMake(0, 0, self.bounds.size.width, toolbar.frame.size.height);
    NSLog(@"laid out toolbar at %@", NSStringFromCGRect(toolbar.frame));
    
    [label sizeToFit];
    label.frame = CGRectMake(0, self.bounds.size.height - (label.frame.size.height + 20), self.bounds.size.width, label.font.lineHeight);
    NSLog(@"laid out label at %@", NSStringFromCGRect(label.frame));
    
    activityIndicator.center = self.center;
    
    coverFlowView.frame = self.bounds;
}

- (void)backTapped {
    [self.delegate backTapped];
}

- (void)playlistTapped {
    [self.delegate playlistTapped];
}

@end

@interface CoverFlowVC ()

@property (nonatomic, copy) NSArray *playlists;
@property (nonatomic, strong) CoverFlowVCView *coverFlowVCView;

@end


@implementation CoverFlowVC

@synthesize coverFlowVCView, playlists;

- (void)loadView {
    self.coverFlowVCView = [[CoverFlowVCView alloc] initWithFrame:CGRectZero];
    self.coverFlowVCView.delegate = self;
    self.coverFlowVCView.coverFlowView.coverflowDelegate = self;
    self.coverFlowVCView.coverFlowView.dataSource = self;
    self.view = self.coverFlowVCView;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self getPlaylistFromServer];
    [self.view layoutIfNeeded];
}

- (void)backTapped {
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)playlistTapped {
    PlaylistLandscapeVC *playlistController = [[PlaylistLandscapeVC alloc] init];
    [playlistController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self presentViewController:playlistController animated:YES completion:nil];
}

// Coverflow methods

- (void)coverflowView:(TKCoverflowView*)coverflowView coverAtIndexWasBroughtToFront:(int)index {
	self.coverFlowVCView.label.text = ((Playlist *)[self.playlists objectAtIndex:index]).title;
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
    [self presentViewController:albumController animated:YES completion:nil];
}

- (void)getPlaylistFromServer {
    [self.coverFlowVCView.activityIndicator startAnimating];
    Producer getPlaylists = [[RFAPI singleton] getPlaylistsWithOffset:0];    
    [self associateProducer:getPlaylists callback:^ (id results) {
        self.playlists = [(NSArray *)results filter:^ BOOL (id p) { return ((Playlist *)p).imageURL != NULL; }];
        self.coverFlowVCView.coverFlowView.numberOfCovers = playlists.count;
        [self.coverFlowVCView.activityIndicator stopAnimating];
    }];
}

@end
