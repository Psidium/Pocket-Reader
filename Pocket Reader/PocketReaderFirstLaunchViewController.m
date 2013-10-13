//
//  PocketReaderFirstLaunchViewController.m
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 10/13/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//

#import "PocketReaderFirstLaunchViewController.h"
#import "PocketReaderFirstLaunchBackgroundView.h"

@interface PocketReaderFirstLaunchViewController ()

@end

@implementation PocketReaderFirstLaunchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //do aditional sutp
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view = [PocketReaderFirstLaunchBackgroundView new];
 
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
