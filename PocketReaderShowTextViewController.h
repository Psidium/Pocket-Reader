//
//  PocketReaderShowTextViewController.h
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 10/2/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PocketReaderShowTextViewController : UIViewController


@property (strong, nonatomic) IBOutlet UINavigationItem *navigationBarTitle;
@property (strong, nonatomic) IBOutlet UITextView *textView;


-(void) setStringOnTextView: (NSString*) textViewString;
-(void) setTitleOfNavigationBar: (NSString *) titleOfNavigationBar;

@end
