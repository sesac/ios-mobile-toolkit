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

@implementation CoverFlowVC

@synthesize albumArray = _albumArray;
@synthesize coverflow = _coverflow;
@synthesize coverImages = _coverImages;
@synthesize loaderThread = _loaderThread;
@synthesize albumLabel = _albumLabel;
@synthesize spinner = _spinner;

- (void)viewDidLoad
{
    NSLog(@"viewDidLoad");
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
    
    // set up the data arrays and coverFlow object to stick playlists into.
    [self setAlbumArray:[[NSMutableArray alloc] init]];
    [self setCoverImages:[[NSMutableArray alloc] init]];

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

    [self performSelectorInBackground:@selector(getPlaylistFromServer) withObject:nil];    
    [self.spinner startAnimating];
    
    NSLog(@"viewDidLoad end");
}


- (void)viewDidUnload
{
    self.coverflow = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"viewWillAppear");
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];                 
    
    NSLog(@"viewWillAppear end");
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
    NSLog(@"gotoPlaylist");
    PlaylistLandscapeVC *playlist = [[PlaylistLandscapeVC alloc] init];
    [playlist setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self presentModalViewController:playlist animated:YES];
}



// Coverflow methods

- (void)coverflowView:(TKCoverflowView*)coverflowView coverAtIndexWasBroughtToFront:(int)index {
	self.albumLabel.text = [[self.albumArray objectAtIndex:index] objectForKey:@"title"];
}

- (TKCoverflowCoverView*)coverflowView:(TKCoverflowView*)coverflowView coverAtIndex:(int)index {
	TKCoverflowCoverView *cover = [coverflowView dequeueReusableCoverView];
	
	if(cover == nil){
		BOOL phone = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
		CGRect rect = phone ? CGRectMake(0, 0, 224, 300) : CGRectMake(0, 0, 300, 600);
		cover = [[TKCoverflowCoverView alloc] initWithFrame:rect];
		cover.baseline = 224;
	}
	cover.image = [self.coverImages objectAtIndex:index];
	return cover;
}

- (void)coverflowView:(TKCoverflowView*)coverflowView coverAtIndexWasDoubleTapped:(int)index{
	AlbumLandscapeVC *album = [[AlbumLandscapeVC alloc] init];
    album.albumInfo = [self.albumArray objectAtIndex:index];
    [album setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self presentModalViewController:album animated:YES];
}


// server API
- (void)getPlaylistFromServer {
    NSLog(@"getPlaylistFromServer");
    // go get the results!
    
    int playlistSetMax = 50; // will be updated after the first query to the full set; commented out below!
    int playlistSetSize = 25;
    
    for (int set = 0; set <= playlistSetMax; set += playlistSetSize) {
        NSLog(@"Playlist Hunk: %d", set);
        
        NSMutableDictionary *playlistParams = [[NSMutableDictionary alloc] init];
        [playlistParams setObject:[NSString stringWithFormat:@"%i", set] forKey:@"start"];
        
        NSObject *json = [[RFAPI singleton] resource:RFAPIResourcePlaylist withParams:playlistParams];
        if (!json) {
            [self alertWithError:@"Playlists not available."];
        }
                
        NSArray *playlistsArray = (NSArray *)[json valueForKey:@"playlists"];
        for (NSDictionary *album in playlistsArray) {
            
            NSString *image_url = [album objectForKey:@"image_url"];
            
            if (image_url == nil || [image_url isEqualToString:@""]) {
                // NSLog(@"No image found.");
                // no image, we'll ignore it for the sake of this demo.
            } else {
                // NSLog(@"Image found.");
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[image_url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
                UIImage *image = [UIImage imageWithData:imageData];
                
                [self.coverImages addObject:image];
                [self.albumArray addObject:album];
            
                self.coverflow.numberOfCovers = [self.albumArray count];
            }
        }
                
        NSLog(@"Playlist Completed Hunk: %d of %d", set, playlistSetMax);
    }
    
    [self.spinner stopAnimating];
}


// Alert delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self.spinner startAnimating];
        [self performSelectorInBackground:@selector(getPlaylistFromServer) withObject:nil];
    }
}

- (void)alertWithError:(NSString *)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];    
}

@end
