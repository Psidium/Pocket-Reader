//
//  PocketReaderShowTextViewController.m
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 10/2/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//

#import "PocketReaderShowTextViewController.h"

@interface PocketReaderShowTextViewController ()

@end

@implementation PocketReaderShowTextViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.textView setEditable:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) setStringOnTextView: (NSString*) textViewString {
    NSLog(@"entrou em setTextView");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.textView setText:textViewString];
    });
}

-(void) setTitleOfNavigationBar: (NSString *) titleOfNavigationBar {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationBarTitle setTitle:titleOfNavigationBar];
    });
}

@end
