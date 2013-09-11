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
    [self.switchOpenCVOn  setOn:YES animated:YES];
    [self.segmentControlMethodSelector setSelectedSegmentIndex:dataClass.openCVMethodSelector];
    [self.languageSelectorOne setSelectedSegmentIndex:dataClass.tesseractLanguageSelector];
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
    dataClass.isOpenCVOn = self.switchOpenCVOn.isOn;
}

- (IBAction)didChangedSegmentControl:(UISegmentedControl *)sender {    
    dataClass.openCVMethodSelector = sender.selectedSegmentIndex;
}

- (IBAction)didChangeSegmentLanguage:(UISegmentedControl *)sender {
    dataClass.tesseractLanguageSelector = sender.selectedSegmentIndex;
    if (sender.selectedSegmentIndex == 0) {
        dataClass.tesseractLanguage = @"por";
    }
    if (sender.selectedSegmentIndex == 1) {
        dataClass.tesseractLanguage = @"eng";
    }if (sender.selectedSegmentIndex == 2) {
        dataClass.tesseractLanguage = @"spa";
    }if (sender.selectedSegmentIndex == 3) {
        dataClass.tesseractLanguage = @"deu";
    }
}

@end
