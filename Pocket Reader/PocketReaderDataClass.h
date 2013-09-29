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
    int binarizeSelector;
    int sheetErrorRange;
    BOOL speechfterPhotoIsTaken;
    float speechRateValue;
}


@property (nonatomic) NSString* tesseractLanguage;
@property (nonatomic) double threshold;
@property (nonatomic) BOOL isOpenCVOn;
@property (nonatomic) BOOL speechAfterPhotoIsTaken;
@property (nonatomic) float speechRateValue;
@property (nonatomic) int openCVMethodSelector;
@property (nonatomic) int tesseractLanguageSelector;
@property (nonatomic) int binarizeSelector;
@property (nonatomic) int sheetErrorRange;

+(PocketReaderDataClass*) getInstance;
@end
