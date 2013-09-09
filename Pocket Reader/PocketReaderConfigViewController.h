//
//  PocketReaderConfigViewController.h
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 9/1/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

@interface PocketReaderConfigViewController : UITableViewController  {
    
    PocketReaderDataClass * dataClass;
}

@property (strong, nonatomic) IBOutlet UISlider *thresholdSlider;
@property (nonatomic) PocketReaderDataClass * dataClass;
@property (strong, nonatomic) IBOutlet UISwitch *switchOpenCVOn;
@property (strong, nonatomic) IBOutlet UINavigationItem *settingsNavigationItem;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentControlMethodSelector;

- (IBAction)didChngeThresholdValue:(UISlider *)sender;
- (IBAction)didChangeIsOpenCVOnValue:(UISwitch *)sender;
- (IBAction)didChangedSegmentControl:(UISegmentedControl *)sender;

@end
