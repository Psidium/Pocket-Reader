//
//  PocketReaderFirstLaunchBackgroundView.m
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 10/13/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//

#import "PocketReaderFirstLaunchBackgroundView.h"

@implementation PocketReaderFirstLaunchBackgroundView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void) drawRect:(CGRect)rect
{
    NSLog(@"DESENHOU");
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //NSArray *gradientColors = [NSArray arrayWithObjects:(id) [UIColor redColor].CGColor, [UIColor yellowColor].CGColor, nil];
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)
                               [UIColor colorWithRed:233/255.0f green:233/255.0f blue:233/255.0f alpha:1.0].CGColor,
                               [UIColor colorWithRed:172/255.0f green:172/255.0f blue:172/255.0f alpha:1.0].CGColor, nil];
    
    CGFloat gradientLocations[] = {0, 0.50, 1};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) gradientColors, gradientLocations);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGGradientRelease(gradient);
}


@end
