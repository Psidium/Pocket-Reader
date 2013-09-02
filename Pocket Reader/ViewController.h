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

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, UIAlertViewDelegate> {
    
	AVCaptureSession *captureSession;
    AVCaptureDevice *captureDevice;
    AVCaptureVideoDataOutput* videoOutput;
    AVCaptureVideoPreviewLayer *captureLayer;
    AVCaptureStillImageOutput *stillImage;
    
    Tesseract* tesseract;
    int camera;
    NSString *_qualityPreset;
    BOOL captureGrayscale;
    BOOL recognize;
    PocketReaderDataClass * dataClass;    
    int n_erode_dilate; // Precisa ajustar pro iPhone
   
}

@property (strong, nonatomic) IBOutlet UIView *recordPreview;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureLayer;
@property (strong, nonatomic) AVCaptureDevice *captureDevice;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoOutput;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImage;
@property (strong, nonatomic) Tesseract* tesseract;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *um;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *dois;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *tres;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *handleTap;
@property (nonatomic) int camera;
@property (weak, nonatomic) NSString * const qualityPreset;
@property (nonatomic) BOOL captureGrayscale;
@property (nonatomic) PocketReaderDataClass * dataClass;

- (IBAction) apertouUm:(id)sender;
- (IBAction) apertouDois:(id)sender;
- (IBAction) apertouTres:(id)sender;
- (IBAction)handleRotation:(UIRotationGestureRecognizer *)sender;
- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer;
- (IBAction)handlePinch:(UIPinchGestureRecognizer *)sender;
- (IBAction)handleTap:(UITapGestureRecognizer *)sender;
- (void) setOpenCVOn:(BOOL)openCVState;

@end