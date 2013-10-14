//
//  PocketReaderConfigViewController.h
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 9/1/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

@interface PocketReaderConfigViewController : UITableViewController {
    
    PocketReaderDataClass * dataClass;
}

@property (nonatomic) PocketReaderDataClass * dataClass;
@property (strong, nonatomic) UISwitch *switchOpenCVOn;
@property (strong, nonatomic) IBOutlet UITableViewCell *findSheetTableCell;
@property (strong, nonatomic) IBOutlet UISegmentedControl *languageSelectorOne;


- (void)didChangeIsOpenCVOnValue:(id)sender;
- (IBAction)didChangeSegmentLanguage:(UISegmentedControl *)sender;

@end
