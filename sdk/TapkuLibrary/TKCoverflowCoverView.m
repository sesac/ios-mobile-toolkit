//
//  TKCoverView.m
//  Created by Devin Ross on 1/3/10.
//
/*
 
 tapku.com || http://github.com/devinross/tapkulibrary
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "TKCoverflowCoverView.h"
#import "UIImage+TKCategory.h"
#import "TKGlobal.h"




@implementation TKCoverflowCoverView
@synthesize baseline,gradientLayer, image = _image;


- (id) initWithFrame:(CGRect)frame {
    if(!(self=[super initWithFrame:frame])) return nil;
    
    self.image = nil;
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    self.layer.anchorPoint = CGPointMake(0.5, 0.5);
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [self addSubview:imageView];
    
    reflected =  [[UIImageView alloc] initWithFrame:CGRectZero];
    reflected.transform = CGAffineTransformScale(reflected.transform, 1, -1);
    [self addSubview:reflected];

    gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = [NSArray arrayWithObjects:(id)[UIColor colorWithWhite:0 alpha:0.5].CGColor,(id)[UIColor colorWithWhite:0 alpha:1].CGColor,nil];
    gradientLayer.startPoint = CGPointMake(0,0);
    gradientLayer.endPoint = CGPointMake(0,0.3);
    [self.layer addSublayer:gradientLayer];
    
    return self;
}

- (void)layoutSubviews {
    imageView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.width);
    reflected.frame = CGRectMake(0, self.bounds.size.width, self.bounds.size.width, self.bounds.size.width);
    gradientLayer.frame = CGRectMake(0, self.bounds.size.width, self.bounds.size.width, self.bounds.size.width);
    
	if (self.image) {
        imageView.image = self.image;
        
        float w = self.image.size.width;
        float h = self.image.size.height;
        float factor = self.bounds.size.width / (h>w?h:w);
        h = factor * h;
        w = factor * w;
        float y = baseline - h > 0 ? baseline - h : 0;
        imageView.frame = CGRectMake(0, y, w, h);
        
        gradientLayer.frame = CGRectMake(0, y + h, w, h);
        
        reflected.frame = CGRectMake(0, y + h, w, h);
        reflected.image = self.image;
    }
}

- (void)setImage:(UIImage *)img {
	_image = img;
    if (!img)
        _image = [UIImage imageNamed:@"CoverFlowPlaceholder.png"];
    [self setNeedsLayout];
}

- (void)setBaseline:(float)f {
	baseline = f;
	[self setNeedsDisplay];
}




- (void) dealloc {}


@end
