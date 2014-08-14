//
//  PocketReaderDataClass.h
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 9/1/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tesseract.h"

@interface PocketReaderDataClass : NSObject
 
@property (strong, atomic) NSString  * tesseractLanguage;
@property (atomic        ) BOOL      guideFrameOn;
@property (atomic        ) BOOL      isOpenCVOn;
@property (atomic        ) BOOL      speechAfterPhotoIsTaken;
@property (atomic        ) float     speechRateValue;
@property (atomic        ) int       tesseractLanguageSelector;
@property (atomic        ) float     tolerance;
@property (strong, atomic) Tesseract * tesseract;

+(PocketReaderDataClass*) getInstance;

@end
