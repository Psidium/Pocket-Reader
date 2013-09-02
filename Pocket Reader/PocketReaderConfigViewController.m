//
//  PocketReaderConfigViewController.m
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 9/1/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//

#import "PocketReaderConfigViewController.h"

@interface PocketReaderConfigViewController ()

@end


@implementation PocketReaderConfigViewController

@synthesize dataClass;

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
    dataClass = [PocketReaderDataClass getInstance];
    [self.thresholdSlider setValue:dataClass.threshold animated:YES];
    [self.switchOpenCVOn  setOn:dataClass.isOpenCVOn   animated:YES];
    dataClass.isOpenCVOn = NO;
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didChngeThresholdValue:(UISlider *)sender {
    dataClass.threshold = self.thresholdSlider.value;
}

- (IBAction)didChangeIsOpenCVOnValue:(UISwitch *)sender {
}

- (IBAction)didBackPressed:(UIButton *)sender {
    dataClass.isOpenCVOn = self.switchOpenCVOn.isOn;
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end
