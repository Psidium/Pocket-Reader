//
//  ViewController.h
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 4/28/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "Tesseract.h"
#import "MBProgressHUD.h"
#import "PocketReaderDataClass.h"
#import "PocketReaderConfigViewController.h"
#import <CoreMotion/CoreMotion.h>

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate> {
    
	AVCaptureSession *captureSession;
    AVCaptureDevice *captureDevice;
    AVCaptureVideoDataOutput* videoOutput;
    AVCaptureVideoPreviewLayer *captureLayer;
    AVCaptureStillImageOutput *stillImage;
    int count;
    int camera;
    NSString *_qualityPreset;
    BOOL captureGrayscale;
    BOOL recognize;
    BOOL isViewAppearing;
    BOOL isTalking;
    BOOL didOneSecondHasPassed;
    PocketReaderDataClass * dataClass;    
    int n_erode_dilate; // Precisa ajustar pro iPhone
    
}

@property (strong, nonatomic) IBOutlet   UIView                     *recordPreview;
@property (strong, nonatomic) IBOutlet   UIImageView                *imageView;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureLayer;
@property (strong, nonatomic) AVCaptureDevice            *captureDevice;
@property (strong, nonatomic) AVCaptureVideoDataOutput   *videoOutput;
@property (strong, nonatomic) AVCaptureSession           *captureSession;
@property (strong, nonatomic) AVCaptureStillImageOutput  *stillImage;
@property (strong, nonatomic) IBOutlet   UIBarButtonItem            *um;
@property (strong, nonatomic) IBOutlet   UIBarButtonItem            *dois;
@property (nonatomic        ) int                        camera;
@property (nonatomic        ) int                        count;
@property (nonatomic        ) BOOL                       didOneSecondHasPassed;
@property (weak, nonatomic  ) NSString * const                      qualityPreset;
@property (nonatomic        ) BOOL                       captureGrayscale;
@property (nonatomic        ) PocketReaderDataClass      * dataClass;
@property (strong, nonatomic) CMMotionManager            *motionManager;

- (IBAction) apertouUm:(id)sender;
- (IBAction) apertouDois:(id)sender;

@end