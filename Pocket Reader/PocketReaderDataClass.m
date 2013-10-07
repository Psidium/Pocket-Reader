//
//  PocketReaderDataClass.m
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 9/1/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//

#import "PocketReaderDataClass.h"

@implementation PocketReaderDataClass

@synthesize isOpenCVOn;
@synthesize tesseractLanguage;
@synthesize tesseractLanguageSelector;
@synthesize speechRateValue;
@synthesize guideFrameOn;
@synthesize tesseract;

static PocketReaderDataClass *instance = nil;

+(PocketReaderDataClass *) getInstance {
    @synchronized(self) {
        if (instance == nil )
            instance = [PocketReaderDataClass new];
    }
    return instance;
}


@end
