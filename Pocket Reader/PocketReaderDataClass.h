//
//  PocketReaderDataClass.h
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 9/1/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tesseract.h"

@interface PocketReaderDataClass : NSObject {
    BOOL isOpenCVOn;
    int openCVMethodSelector;
    NSString* tesseractLanguage;
    int tesseractLanguageSelector;
    BOOL speechfterPhotoIsTaken;
    float speechRateValue;
    BOOL guideFrameOn;
    Tesseract *tesseract;
}



@property (nonatomic) NSString* tesseractLanguage;
@property (nonatomic) BOOL guideFrameOn;
@property (nonatomic) BOOL isOpenCVOn;
@property (nonatomic) BOOL speechAfterPhotoIsTaken;
@property (nonatomic) float speechRateValue;
@property (nonatomic) int tesseractLanguageSelector;
@property (strong, nonatomic) Tesseract* tesseract;

+(PocketReaderDataClass*) getInstance;
@end
