//
//  PocketReaderSavedTextViewController.h
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 9/17/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PocketReaderSavedTextCell.h"
#import "PocketReaderShowTextViewController.h"

@interface PocketReaderSavedTextViewController : UITableViewController
@property (nonatomic, strong) NSMutableArray *savedText;

@end
