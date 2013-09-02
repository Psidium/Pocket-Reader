//
//  PocketReaderConfigViewController.h
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 9/1/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

@interface PocketReaderConfigViewController : UIViewController  {
    
    PocketReaderDataClass * dataClass;
}

@property (strong, nonatomic) IBOutlet UISlider *thresholdSlider;
@property (nonatomic) PocketReaderDataClass * dataClass;
@property (strong, nonatomic) IBOutlet UISwitch *switchOpenCVOn;

- (IBAction)didChngeThresholdValue:(UISlider *)sender;
- (IBAction)didChangeIsOpenCVOnValue:(UISwitch *)sender;

- (IBAction)didBackPressed:(UIButton *)sender;

@end
