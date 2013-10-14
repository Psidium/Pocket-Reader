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
    [self.switchOpenCVOn setOn:dataClass.isOpenCVOn animated:YES];
    if ([dataClass.tesseractLanguage isEqualToString:@"por"]) {
        [self.languageSelectorOne setSelectedSegmentIndex:0];
    } else if ([dataClass.tesseractLanguage isEqualToString:@"eng"]) {
        [self.languageSelectorOne setSelectedSegmentIndex:1];
    } else if ([dataClass.tesseractLanguage isEqualToString:@"spa"]) {
        [self.languageSelectorOne setSelectedSegmentIndex:2];
    } else if ([dataClass.tesseractLanguage isEqualToString:@"deu"]) {
        [self.languageSelectorOne setSelectedSegmentIndex:3];
    } else if ([dataClass.tesseractLanguage isEqualToString:@"fra"]) {
        [self.languageSelectorOne setSelectedSegmentIndex:4];
    }
    
    self.switchOpenCVOn = [[UISwitch alloc] init];
    [self.switchOpenCVOn addTarget:self action:@selector(didChangeIsOpenCVOnValue:) forControlEvents:UIControlEventValueChanged];
    self.findSheetTableCell.accessoryView = self.switchOpenCVOn;
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated {
    [self.switchOpenCVOn setOn:dataClass.isOpenCVOn animated:YES];
    if ([dataClass.tesseractLanguage isEqualToString:@"por"]) {
        [self.languageSelectorOne setSelectedSegmentIndex:0];
    } else if ([dataClass.tesseractLanguage isEqualToString:@"eng"]) {
        [self.languageSelectorOne setSelectedSegmentIndex:1];
    } else if ([dataClass.tesseractLanguage isEqualToString:@"spa"]) {
        [self.languageSelectorOne setSelectedSegmentIndex:2];
    } else if ([dataClass.tesseractLanguage isEqualToString:@"deu"]) {
        [self.languageSelectorOne setSelectedSegmentIndex:3];
    } else if ([dataClass.tesseractLanguage isEqualToString:@"fra"]) {
        [self.languageSelectorOne setSelectedSegmentIndex:4];
    }
}


- (void)didChangeIsOpenCVOnValue:(id)sender {
    dataClass.isOpenCVOn = self.switchOpenCVOn.isOn;
}


- (IBAction)didChangeSegmentLanguage:(UISegmentedControl *)sender {
    dataClass.tesseractLanguageSelector = sender.selectedSegmentIndex;
    if (sender.selectedSegmentIndex == 0) {
        dataClass.tesseractLanguage = @"por";
    }if (sender.selectedSegmentIndex == 1) {
        dataClass.tesseractLanguage = @"eng";
    }if (sender.selectedSegmentIndex == 2) {
        dataClass.tesseractLanguage = @"spa";
    }if (sender.selectedSegmentIndex == 3) {
        dataClass.tesseractLanguage = @"deu";
    }if (sender.selectedSegmentIndex == 4) {
        dataClass.tesseractLanguage = @"fra";
    }
    
    [dataClass.tesseract clear]; //clean the tesseract
    dataClass.tesseract=nil;
    Tesseract *tesseractHolder = [[Tesseract alloc] initWithDataPath:@"tessdata" language:dataClass.tesseractLanguage];
    dataClass.tesseract=tesseractHolder;
    NSLog(@"Mudou pra %@",dataClass.tesseractLanguage);

}


@end
