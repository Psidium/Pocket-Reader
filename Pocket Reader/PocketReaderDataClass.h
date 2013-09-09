//
//  PocketReaderDataClass.h
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 9/1/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PocketReaderDataClass : NSObject {
    double threshold;
    BOOL isOpenCVOn;
    int openCVMethodSelector;
    NSString* tesseractLanguage;
    int tesseractLanguageSelector;
}


@property (nonatomic) NSString* tesseractLanguage;
@property (nonatomic) double threshold;
@property (nonatomic) BOOL isOpenCVOn;
@property (nonatomic) int openCVMethodSelector;
@property (nonatomic) int tesseractLanguageSelector;

+(PocketReaderDataClass*) getInstance;
@end
