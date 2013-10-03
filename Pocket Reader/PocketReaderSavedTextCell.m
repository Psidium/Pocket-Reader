//
//  PocketReaderSavedTextCell.m
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 9/17/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//

#import "PocketReaderSavedTextCell.h"

@implementation PocketReaderSavedTextCell

@synthesize cellTitleLabel;
@synthesize cellSubTitleLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
