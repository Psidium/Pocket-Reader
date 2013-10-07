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
    [self.switchOpenCVOn  setOn:YES animated:YES];
    [self.languageSelectorOne setSelectedSegmentIndex:dataClass.tesseractLanguageSelector];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pressedGuideFrameOn:(UISwitch *)sender {
}



- (IBAction)didChangeIsOpenCVOnValue:(UISwitch *)sender {
    dataClass.isOpenCVOn = self.switchOpenCVOn.isOn;
}

- (IBAction)didChangeSpeechOnSwitch:(UISwitch *)sender {
    dataClass.speechAfterPhotoIsTaken = [sender isOn];
}

- (IBAction)didChangeSpeechRateValue:(UISlider *)sender {
    sender.value = round(sender.value);
    if ([AVSpeechSynthesizer class] != nil){
        switch ((int)sender.value) {
            case 1:
                dataClass.speechRateValue = 0;
                break;
            case 2:
                dataClass.speechRateValue = 0.5;
                break;
            case 3:
                dataClass.speechRateValue = 1;
                break;
        }
    }
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
    }
    [dataClass.tesseract clear]; //clean the tesseract
    dataClass.tesseract=nil;
    Tesseract *tesseractHolder = [[Tesseract alloc] initWithDataPath:@"tessdata" language:dataClass.tesseractLanguage];
    dataClass.tesseract=tesseractHolder;
    NSLog(@"Mudou pra %@",dataClass.tesseractLanguage);

}


@end
