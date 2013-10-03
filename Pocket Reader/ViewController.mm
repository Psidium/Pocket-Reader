//
//  ViewController.m
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 4/28/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//
//  Using part of code created by Robin Summerhill on 02/09/2011.
//  Copyright 2011 Aptogo Limited. All rights reserved.
//
//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//
//
#import "UIImage+OpenCV.h"
#import "ViewController.h"
#import "text_detect.h"

@interface ViewController () {
    cv::Rect padrao;
    
    std::vector<cv::Vec4i> lines;
}
@end

@implementation ViewController


@synthesize camera;
@synthesize captureGrayscale;
@synthesize captureSession;
@synthesize qualityPreset;
@synthesize captureDevice;
@synthesize captureLayer;
@synthesize videoOutput;
@synthesize stillImage;
@synthesize tesseract;
@synthesize dataClass;
@synthesize count;
@synthesize motionManager;

#pragma mark - Default:
- (void)viewDidLoad
{
    [super viewDidLoad];
    dataClass.isRunningiOS7 = ([[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7); //don't know if work anymore
    NSLog(dataClass.isRunningiOS7? @"is running iOS 7" : @"is not running ios 7");
    padrao.x = 50;
    padrao.y = 70;
    padrao.width = 233; //Create a rectangle for guide
    padrao.height = 319; // Note: "padrao" is portuguese for "default"
    self.qualityPreset = AVCaptureSessionPresetPhoto; //maximum quality
    captureGrayscale = NO; //Set color capture
    self.camera = -1; //Set back camera
    recognize = NO; //clean Recognize text flag
    [self timerFireMethod:nil]; // prints a red rectangle on the screen for DEBUG
    [self setTorch:NO]; //turn flash off
    dataClass = [PocketReaderDataClass getInstance];
    dataClass.isOpenCVOn = NO;
    dataClass.binarizeSelector=0;
    dataClass.sheetErrorRange = 10;
    dataClass.tesseractLanguage =  NSLocalizedString(@"first",nil);
    dataClass.threshold = 150;
    n_erode_dilate = 1;
    dataClass.openCVMethodSelector = 3;
    dataClass.speechRateValue = 0.5;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(announcementFinished:)
                                                 name:UIAccessibilityAnnouncementDidFinishNotification
                                               object:nil];
    if (!UIAccessibilityIsVoiceOverRunning()) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"VoiceOver inactive",nil) message: NSLocalizedString(@"Warning: VoiceOver is currently off. Pocket Reader is meant to be used with VoiceOver feature turned on.", nil) delegate:self cancelButtonTitle: NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [message show];
    }
    
    [self createCaptureSessionForCamera:camera qualityPreset:qualityPreset grayscale:captureGrayscale]; //set camera and it view
    [captureSession startRunning]; //start the camera capturing
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    dataClass.isOpenCVOn = NO; //disable OpenCV processing and let ARC clean the memory
    [self performSelector:@selector(timerFireMethod:) withObject:nil afterDelay:2.0]; //after 2 seconds turn openCV on again
    
    // Dispose of any resources that can be recreated.
    
}

#pragma mark - Buttons:

- (IBAction)apertouUm:(id)sender
{
    [self setTorch:![captureDevice isTorchActive]]; //Invert the flash state
}

// When an announcement finishes this will get called.
- (void)announcementFinished:(NSNotification *)notification {
    // Get the text and if it succeded (read the entire thing) or not
    //NSString *announcment = notification.userInfo[UIAccessibilityAnnouncementKeyStringValue];
    BOOL wasSuccessful = [notification.userInfo[UIAccessibilityAnnouncementKeyWasSuccessful] boolValue];
    
    if (wasSuccessful) {
        isTalking=NO;
    } else {
        isTalking=NO;
    }
}

#pragma mark - Tesseract:

- (IBAction)apertouDois:(id)sender
{
    [self.tesseract clear]; //clean the tesseract
    self.tesseract=nil;
    Tesseract *tesseractHolder = [[Tesseract alloc] initWithDataPath:@"tessdata" language:dataClass.tesseractLanguage];
    self.tesseract=tesseractHolder;
    NSLog(@"Mudou pra %@",dataClass.tesseractLanguage);
    recognize=YES;
}

- (void) setTorch:(BOOL)torchState {
    if ([captureDevice hasTorch]){
        if(torchState){
            NSError *__autoreleasing* errores = NULL;
            [captureDevice lockForConfiguration:errores];
            [captureDevice setTorchMode:AVCaptureTorchModeOn];
            
            [captureDevice unlockForConfiguration];
        } else {
            NSError *__autoreleasing* errores = NULL;
            [captureDevice lockForConfiguration:errores];
            [captureDevice setTorchMode:AVCaptureTorchModeOff];
            
            [captureDevice unlockForConfiguration];
        }
    }
    
}

- (void)timerFireMethod:(NSTimer*)theTimer {
    dataClass.isOpenCVOn = YES;
}

#pragma mark - Image processing:
// this does the trick to have tesseract accept the UIImage.
-(UIImage *) gs_convert_image:(UIImage *)src_img {
    CGColorSpaceRef d_colorSpace = CGColorSpaceCreateDeviceRGB();
    /*
     * Note we specify 4 bytes per pixel here even though we ignore the
     * alpha value; you can't specify 3 bytes per-pixel.
     */
    size_t d_bytesPerRow = src_img.size.width * 4;
    unsigned char * imgData = (unsigned char*)malloc(src_img.size.height*d_bytesPerRow);
    CGContextRef context =  CGBitmapContextCreate(imgData, src_img.size.width,
                                                  src_img.size.height,
                                                  8, d_bytesPerRow,
                                                  d_colorSpace,
                                                  kCGImageAlphaNoneSkipFirst);
    
    UIGraphicsPushContext(context);
    // These next two lines 'flip' the drawing so it doesn't appear upside-down.
    CGContextTranslateCTM(context, 0.0, src_img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    // Use UIImage's drawInRect: instead of the CGContextDrawImage function, otherwise you'll have issues when the source image is in portrait orientation.
    [src_img drawInRect:CGRectMake(0.0, 0.0, src_img.size.width, src_img.size.height)];
    UIGraphicsPopContext();
    
    /*
     * At this point, we have the raw ARGB pixel data in the imgData buffer, so
     * we can perform whatever image processing here.
     */
    
    
    // After we've processed the raw data, turn it back into a UIImage instance.
    CGImageRef new_img = CGBitmapContextCreateImage(context);
    UIImage * convertedImage = [[UIImage alloc] initWithCGImage:
                                new_img];
    
    CGImageRelease(new_img);
    CGContextRelease(context);
    CGColorSpaceRelease(d_colorSpace);
    free(imgData);
    return convertedImage;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //MARK: Most Important Method
    
    if(dataClass.isOpenCVOn && isViewAppearing) {
        
        if(dataClass.openCVMethodSelector==0){NSArray *sublayers = [NSArray arrayWithArray:[self.recordPreview.layer sublayers]];
            int sublayersCount = [sublayers count];
            int currentSublayer = 0;
            
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            
            // hide all the face layers
            for (CALayer *layer in sublayers) {
                NSString *layerName = [layer name];
                if ([layerName isEqualToString:@"DefaultLayer"])
                    [layer setHidden:YES];
            }
            
            // Create transform to convert from vide frame coordinate space to view coordinate space
            CGAffineTransform t = [self affineTransformForVideoFrame:self.recordPreview.bounds orientation:AVCaptureVideoOrientationPortrait];
            
            CGRect faceRect = CGRectMake(padrao.x/1.0f, padrao.y/1.0f, padrao.width/1.0f, padrao.height/1.0f);
            
            faceRect = CGRectApplyAffineTransform(faceRect, t);
            
            CALayer *featureLayer = nil;
            
            while (!featureLayer && (currentSublayer < sublayersCount)) {
                CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
                if ([[currentLayer name] isEqualToString:@"DefaultLayer"]) {
                    featureLayer = currentLayer;
                    [currentLayer setHidden:NO];
                }
            }
            
            if (!featureLayer) {
                // Create a new feature marker layer
                featureLayer = [[CALayer alloc] init];
                featureLayer.name = @"DefaultLayer";
                featureLayer.borderColor = [[UIColor redColor] CGColor];
                featureLayer.borderWidth = 1.0f;
                [self.recordPreview.layer addSublayer:featureLayer];
            }
            
            
            
            featureLayer.frame = faceRect;
            
            [CATransaction commit];
        }
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CGRect videoRect = CGRectMake(0.0f, 0.0f, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
        AVCaptureVideoOrientation videoOrientation = AVCaptureVideoOrientationPortrait;
        
        
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        CIContext *temporaryContext = [CIContext contextWithOptions:nil];
        CGImageRef videoImage = [temporaryContext
                                 createCGImage:ciImage
                                 fromRect:videoRect];
        
        UIImage *imageBebug = [UIImage imageWithCGImage:videoImage];
        CGImageRelease(videoImage);
        
        
        cv::Mat mat = [imageBebug CVMat];
        
        
        [self processFrame:mat videoRect:videoRect videoOrientation:videoOrientation];
        
        mat.release();
        
        
    } else {
        NSArray *sublayers = [NSArray arrayWithArray:[self.recordPreview.layer sublayers]];
        for (CALayer *layer in sublayers) {
            if ([[layer name] isEqualToString:@"DefaultLayer"])
                [layer setHidden:YES];
            if ([[layer name] isEqualToString:@"SheetLayer"])
                [layer setHidden:YES];
        }
    }
    
    if(recognize){
        BOOL torchPreviousState = [captureDevice isTorchActive];
        BOOL openCVOnPreviousState = dataClass.isOpenCVOn;
        dataClass.isOpenCVOn = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];});
        NSLog(@"%@",[stillImage description]);
        AVCaptureConnection *vc = [stillImage connectionWithMediaType:AVMediaTypeVideo];
        [stillImage captureStillImageAsynchronouslyFromConnection:vc completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            [self setTorch:NO];
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *img = [[UIImage alloc] initWithData:imageData];
            img=[self gs_convert_image:img];
            if (img!=nil) {
                [self.tesseract setImage:img];
                [self.tesseract recognize];
                NSString *textoReconhecido = [self.tesseract recognizedText];
                [self.tesseract clear];
                NSLog(@"%@", textoReconhecido);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
                if (UIAccessibilityIsVoiceOverRunning()) {
                    isTalking=YES;
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                                    textoReconhecido);
                } else if (dataClass.speechAfterPhotoIsTaken){
                    if ([AVSpeechSynthesizer class] != nil){
                        AVSpeechSynthesizer *synthesizer = [AVSpeechSynthesizer new];
                        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:textoReconhecido];
                        utterance.rate = dataClass.speechRateValue;
                        [synthesizer speakUtterance:utterance];
                    }
                }
                /* UIAlertView *message = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Texto reconhecido:",nil) message:textoReconhecido delegate:nil cancelButtonTitle: NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
                 [message show];*/
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"AddToHistory"
                 object:textoReconhecido];
                [self.tabBarController setSelectedIndex:1];
                [self setTorch:torchPreviousState];
                dataClass.isOpenCVOn =openCVOnPreviousState;
            }
        }];
        recognize=false;
    }
}

-(void) recognizeText:(UIImage*)img {
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];});
    img=[self gs_convert_image:img];
    
    if (img!=nil) {
        
        NSLog(@"saiu uimage");
        [self.tesseract setImage:img];
        NSLog(@"começa a reconhecer");
        NSLog([self.tesseract recognize] ? @"Reconheceu" : @"não reconheceu");
        NSLog(@"terminou");
        NSLog(@"%@",[self.tesseract description]);
        NSString *textoReconhecido = [self.tesseract recognizedText];
        [self.tesseract clear];
        
        NSLog(@"%@", textoReconhecido);
        NSLog(@"deveria ter mostrado");
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }); /*
        if (UIAccessibilityIsVoiceOverRunning()) {
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                            textoReconhecido);
        }
        UIAlertView *message = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Texto reconhecido:",nil) message:textoReconhecido delegate:nil cancelButtonTitle: NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [message show];*/
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"AddToHistory"
         object:textoReconhecido];
        [self.tabBarController setSelectedIndex:1];
    }
    
}

-(void) viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    isViewAppearing = YES;
}

-(void) viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    isViewAppearing = NO;
    
}

- (void) usePicker {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    [picker setDelegate:self];
    [picker setAllowsEditing:YES];
    [picker setSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    
    [self presentViewController:picker animated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    // Dismiss the picker
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
    
    // Get the image from the result
    [self recognizeText:[info valueForKey:@"UIImagePickerControllerOriginalImage"]];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Implementation of FaceTracker:
- (void)processFrame:(cv::Mat &)mat videoRect:(CGRect)rect videoOrientation:(AVCaptureVideoOrientation)videOrientation
{
    // Shrink video frame to 320X240
    cv::resize(mat, mat, cv::Size(), 0.5f, 0.5f, CV_INTER_LINEAR);
    rect.size.width /= 2.0f;
    rect.size.height /= 2.0f;
    
    // Rotate video frame by 90deg to portrait by combining a transpose and a flip
    // Note that AVCaptureVideoDataOutput connection does NOT support hardware-accelerated
    // rotation and mirroring via videoOrientation and setVideoMirrored properties so we
    // need to do the rotation in software here.
    cv::transpose(mat, mat);
    CGFloat temp = rect.size.width;
    rect.size.width = rect.size.height;
    rect.size.height = temp;
    
    if (videOrientation == AVCaptureVideoOrientationLandscapeRight)
    {
        // flip around y axis for back camera
        cv::flip(mat, mat, 1);
    }
    else {
        // Front camera output needs to be mirrored to match preview layer so no flip is required here
    }
    cv::flip(mat, mat, 1);
    
    
    // Detect faces
    cv::Rect sheet;
    cv::vector<cv::Rect> vectorText;
    // MARK: Here comes the OpenCV methods
    if (dataClass.openCVMethodSelector == 0 || dataClass.openCVMethodSelector == 2) {
        if (dataClass.openCVMethodSelector == 0)
            sheet = [self contornObjectOnView:mat];
        else if (dataClass.openCVMethodSelector == 2){
            //commented: Turn the image by 90 degrees because when the text is taken turned it is better recognized
            /*double angle = 90;  // or 270
             cv::Size src_sz = mat.size();
             cv::Size dst_sz(src_sz.height, src_sz.width);
             
             int len = std::max(mat.cols, mat.rows);
             Point2f center(len/2., len/2.);
             Mat rot_mat = cv::getRotationMatrix2D(center, angle, 1.0);
             warpAffine(mat, mat, rot_mat, dst_sz);
             cv::Mat image = mat.clone();*/
            vectorText = [self detectTextWrapper:mat];
            /*int  holderSize, holderCoordinate; //after the rotated mat is returned, rotate the cv::Rect back to show it right
             for (int i=0;i<vectorText.size();i++) {
             NSLog(@"[%d vectortext] x: %d y: %d Weight %d Height %d row: %d col %d",i,vectorText[i].x,vectorText[i].y,vectorText[i].width,vectorText[i].height, image.rows, image.cols);
             holderCoordinate = vectorText[i].x;
             vectorText[i].x = image.rows - vectorText[i].y + vectorText[i].height*2;
             vectorText[i].y = holderCoordinate;
             holderSize = vectorText[i].width;
             vectorText[i].width = vectorText[i].height;
             vectorText[i].height = holderSize;
             }*/
        }
        mat.release();
        
        if (sheet==padrao) {
            recognize=YES;
            // TODO: Depois de detectar a folha cortar ela da foto
            // TODO: pegar a imagem do rolo da câmera
            // TODO: salvar em um arquivo os textos
        }
        
        // Dispatch updating of face markers to main queue
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            if (dataClass.openCVMethodSelector == 0)[self displaySheet:sheet forVideoRect:rect videoOrientation:AVCaptureVideoOrientationPortrait withColor:[UIColor greenColor]];
            else if (dataClass.openCVMethodSelector == 2)
                [self displayFaces:vectorText forVideoRect:rect videoOrientation:AVCaptureVideoOrientationPortrait];
            [self.imageView setHidden:YES];
        });
        
    }
    else if (dataClass.openCVMethodSelector == 1 || dataClass.openCVMethodSelector == 3) {
        dispatch_sync(dispatch_get_main_queue(),^{
            NSArray *sublayers = [NSArray arrayWithArray:[self.recordPreview.layer sublayers]];
            for (CALayer *layer in sublayers) {
                if ([[layer name] isEqualToString:@"DefaultLayer"])
                    [layer setHidden:YES];
                if ([[layer name] isEqualToString:@"SheetLayer"])
                    [layer setHidden:YES];
            }
            [self.imageView setHidden:NO];});
        if (dataClass.openCVMethodSelector == 1)
            [self findAndDrawSheet:mat];
        else if (dataClass.openCVMethodSelector == 3)
            [self findAndDrawSheetByContours:mat];
        mat.release();
    }
}

- (cv::Rect) contornObjectOnView:(cv::Mat&)img {
    
    cv::Mat m = img.clone();
    cv::cvtColor(m, m, CV_RGB2GRAY);
    cv::blur(m, m, cv::Size(5,5));
    cv::threshold(m, m, dataClass.threshold, 255,dataClass.binarizeSelector | CV_THRESH_OTSU);
    cv::erode(m, m, cv::Mat(),cv::Point(-1,-1),n_erode_dilate);
    cv::dilate(m, m, cv::Mat(),cv::Point(-1,-1),n_erode_dilate);
    
    std::vector< std::vector<cv::Point> > contours;
    std::vector<cv::Point> points;
    cv::findContours(m, contours, CV_RETR_LIST, CV_CHAIN_APPROX_NONE);
    m.release();
    for (size_t i=0; i<contours.size(); i++) {
        for (size_t j = 0; j < contours[i].size(); j++) {
            cv::Point p = contours[i][j];
            points.push_back(p);
        }
    }
    return cv::boundingRect(cv::Mat(points).reshape(2));
}


// Polimorfism method to use vectors
- (void)displayFaces:(const std::vector<cv::Rect> &)faces
        forVideoRect:(CGRect)rect
    videoOrientation:(AVCaptureVideoOrientation)videoOrientation
{
    NSArray *sublayers = [NSArray arrayWithArray:[self.recordPreview.layer sublayers]];
    int sublayersCount = [sublayers count];
    int currentSublayer = 0;
    
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// hide all the face layers
	for (CALayer *layer in sublayers) {
        NSString *layerName = [layer name];
		if ([layerName isEqualToString:@"FaceLayer"])
			[layer setHidden:YES];
	}
    
    // Create transform to convert from vide frame coordinate space to view coordinate space
    CGAffineTransform t = [self affineTransformForVideoFrame:rect orientation:videoOrientation];
    
    for (int i = 0; i < faces.size(); i++) {
        
        CGRect faceRect;
        faceRect.origin.x = faces[i].x;
        faceRect.origin.y = faces[i].y;
        faceRect.size.width = faces[i].width;
        faceRect.size.height = faces[i].height;
        
        faceRect = CGRectApplyAffineTransform(faceRect, t);
        
        CALayer *featureLayer = nil;
        
        while (!featureLayer && (currentSublayer < sublayersCount)) {
			CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
			if ([[currentLayer name] isEqualToString:@"FaceLayer"]) {
				featureLayer = currentLayer;
				[currentLayer setHidden:NO];
			}
		}
        
        if (!featureLayer) {
            // Create a new feature marker layer
			featureLayer = [[CALayer alloc] init];
            featureLayer.name = @"FaceLayer";
            featureLayer.borderColor = [[UIColor greenColor] CGColor];
            featureLayer.borderWidth = 3.0f;
			[self.recordPreview.layer addSublayer:featureLayer];
		}
        
        featureLayer.frame = faceRect;
    }
    
    [CATransaction commit];
}



// Update face markers given vector of face rectangles
- (void)displaySheet:(const cv::Rect &)squares
        forVideoRect:(CGRect)rect
    videoOrientation:(AVCaptureVideoOrientation)videoOrientation
           withColor:(UIColor*) color
{
    NSArray *sublayers = [NSArray arrayWithArray:[self.recordPreview.layer sublayers]];
    int sublayersCount = [sublayers count];
    int currentSublayer = 0;
    
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// hide all the face layers
	for (CALayer *layer in sublayers) {
        NSString *layerName = [layer name];
		if ([layerName isEqualToString:@"SheetLayer"])
			[layer setHidden:YES];
	}
    
    // Create transform to convert from vide frame coordinate space to view coordinate space
    CGAffineTransform t = [self affineTransformForVideoFrame:rect orientation:videoOrientation];
    
    CGRect faceRect;
    faceRect.origin.x = squares.x;
    faceRect.origin.y = squares.y;
    faceRect.size.width = squares.width;
    faceRect.size.height = squares.height;
    
    faceRect = CGRectApplyAffineTransform(faceRect, t);
    
    CALayer *featureLayer = nil;
    
    while (!featureLayer && (currentSublayer < sublayersCount)) {
        CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
        if ([[currentLayer name] isEqualToString:@"SheetLayer"]) {
            featureLayer = currentLayer;
            [currentLayer setHidden:NO];
        }
    }
    
    if (!featureLayer) {
        // Create a new feature marker layer
        featureLayer = [[CALayer alloc] init];
        featureLayer.name = @"SheetLayer";
        featureLayer.borderColor = [color CGColor];
        featureLayer.borderWidth = 1.0f;
        [self.recordPreview.layer addSublayer:featureLayer];
    }
    
    featureLayer.frame = faceRect;
    
    if(!dataClass.isOpenCVOn){
        for (CALayer *layer in sublayers) {
            NSString *layerName = [layer name];
            if ([layerName isEqualToString:@"SheetLayer"])
                [layer setHidden:YES];
        }
    }
    
    [CATransaction commit];
    
    
}

#pragma mark - 4th implementation


- (void) findAndDrawSheetByContours: (cv::Mat &) mat {
    cv::Mat output = mat.clone();
    double imageSize = mat.rows * mat.cols;  //quando era literal n tinha ess alinha
    cv::cvtColor(mat, mat, CV_BGR2GRAY);
    //UIImageWriteToSavedPhotosAlbum([UIImage imageWithCVMat:mat], nil, nil, nil);
    cv::GaussianBlur(mat, mat, cv::Size(3,3), 0);
    //UIImageWriteToSavedPhotosAlbum([UIImage imageWithCVMat:mat], nil, nil, nil);
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Point(9,9));
    //  UIImageWriteToSavedPhotosAlbum([UIImage imageWithCVMat:kernel], nil, nil, nil);
    cv::Mat dilated;
    cv::dilate(mat, dilated, kernel);
    //    UIImageWriteToSavedPhotosAlbum([UIImage imageWithCVMat:dilated], nil, nil, nil);
    
    cv::Mat edges;
    cv::Canny(dilated, edges, 84, 3);
    //   UIImageWriteToSavedPhotosAlbum([UIImage imageWithCVMat:edges], nil, nil, nil);
    
    lines.clear();
    cv::HoughLinesP(edges, lines, 1, CV_PI/180, 25);
    std::vector<cv::Vec4i>::iterator it = lines.begin();
    for(; it!=lines.end(); ++it) {
        cv::Vec4i l = *it;
        cv::line(edges, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), cv::Scalar(255,0,0), 2, 8);
    }
    //   UIImageWriteToSavedPhotosAlbum([UIImage imageWithCVMat:edges], nil, nil, nil);
    std::vector< std::vector<cv::Point> > contours;
    cv::findContours(edges, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_TC89_KCOS);
    std::vector< std::vector<cv::Point> > contoursCleaned;
    for (int i=0; i < contours.size(); i++) {
        if (cv::arcLength(contours[i], false) > 100)
            contoursCleaned.push_back(contours[i]);
    }
    std::vector<std::vector<cv::Point> > contoursArea;
    
    for (int i=0; i < contoursCleaned.size(); i++) {
        if (cv::contourArea(contoursCleaned[i]) > 10000){
            contoursArea.push_back(contoursCleaned[i]);
            NSLog(@"ASUHEUASHE ");
        }
    }
    NSLog(@"tamanho countours %lu",contoursArea.size());
    std::vector<std::vector<cv::Point> > contoursDraw (contoursCleaned.size());
    for (int i=0; i < contoursArea.size(); i++){
        cv::approxPolyDP(Mat(contoursArea[i]), contoursDraw[i], 40, true);
    }
    NSLog(@"iniciopoligonopontosetal");
    for (int i=0; i < contoursArea.size();i++) {
        for(int j=0; j< contoursArea[i].size();j++){
            NSLog(@"ponto [%d][%d]: x: %d y: %d",i,j,contoursArea[i][j].x,contoursArea[i][j].y);
        }
    }
    if (UIAccessibilityIsVoiceOverRunning()) {
        if (contoursArea.size() > 0) {
            float batata = cv::contourArea(contoursArea[0]);
            cv::Rect lugarAtual = cv::boundingRect(contoursArea[0]);
            if (lugarAtual.x > mat.size().width - (lugarAtual.x + lugarAtual.width)){
                if(lugarAtual.x - (mat.size().width - (lugarAtual.x + lugarAtual.width)) > 100){
                    if (!isTalking){
                        isTalking=YES;
                        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Mova um pouco para a direita", nil));
                    }
                }
            } else if(lugarAtual.x - (mat.size().width - (lugarAtual.x + lugarAtual.width)) < 100){
                if (!isTalking){
                    isTalking=YES;
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Mova um pouco para a esquerda", nil));
                }
            }
            
            if (lugarAtual.y > mat.size().height - (lugarAtual.y + lugarAtual.height)){
                if(lugarAtual.y - (mat.size().height - (lugarAtual.y + lugarAtual.height)) > 100){
                    if (!isTalking){
                        isTalking=YES;
                        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Mova um pouco para trás", nil));
                    }
                }
            } else if(lugarAtual.y - (mat.size().height - (lugarAtual.y + lugarAtual.height)) < 100){
                if (!isTalking){
                    isTalking=YES;
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Mova um pouco para frente", nil));
                }
            }
            
            if (!isTalking){
                isTalking=YES;
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Aproxime o aparelho da folha com cuidado", nil));
            }
            NSLog(@"tamhho %f", batata);
            
            if (batata > (imageSize / 1.21) ){ // era 112000
                recognize=YES;
                isTalking=YES;
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Foto capturada com sucesso, iniciando conversão do texto impresso em voz", nil));
            }
        } else {
            if (!isTalking){
                isTalking=YES;
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Nenhuma folha detectada", nil));
            }
        }
    }
    

    /*if (isTalking) {
        if (++self.count == 60) {
            isTalking=NO;
            self.count=0;
        }
        
    } else
        count=0;*/
    Mat drawing = Mat::zeros( mat.size(), CV_8UC3 );
    cv::drawContours(drawing, contoursDraw, -1, cv::Scalar(0,255,0),1);
    //   NSLog(@"tamanho countours %lu",contoursCleaned.size());
    //UIImageWriteToSavedPhotosAlbum([UIImage imageWithCVMat:drawing], nil, nil, nil);
    
    NSData *data = [NSData dataWithBytes:drawing.data length:drawing.elemSize() * drawing.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (drawing.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(drawing.cols,                                     // Width
                                        drawing.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * drawing.elemSize(),                           // Bits per pixel
                                        drawing.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    
    drawing.release();
    const float blackMask[6] = { 0,0,0, 0,0,0 };
    CGImageRef myColorMaskedImage = CGImageCreateWithMaskingColors(imageRef, blackMask);
    CGImageRelease(imageRef);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.imageView setHidden:NO];
        [self.imageView setImage:[UIImage imageWithCGImage:myColorMaskedImage]];
    });
}

#pragma mark - C++ wrapper

-(cv::vector<cv::Rect>) detectTextWrapper:(cv::Mat &) image {
    DetectText detector = DetectText();
    vector <cv::Rect> texts;
    texts = detector.getBoundingBoxes(image);
    image.release();
    NSLog(@"Passou method objc");
    return texts;
}


#pragma mark - Hough Transform Implementation
-(void) findAndDrawSheet: (cv::Mat &)image {
    
    
    /*    UIGraphicsBeginImageContext(self.recordPreview.frame.size);
     CGContextRef context = UIGraphicsGetCurrentContext(); //erro de agora: não tem cotexto nenhum, tá desenhando no nada, tem que delgar uma CALayer do recordpreview. (como? no sei)
     CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
     CGContextSetLineWidth(context, 2.0);*/
    self.imageView.image =nil;
    cv::cvtColor(image, image, CV_RGB2GRAY);
    cv::Canny(image, image, 50, 250, 3);
    lines.clear();
    cv::HoughLinesP(image, lines, 1, CV_PI/180, dataClass.threshold, 50, 10);
    std::vector<cv::Vec4i>::iterator it = lines.begin();
    for(; it!=lines.end(); ++it) {
        cv::Vec4i l = *it;
        //NSLog(@"inicio x: %d, y: %d, fim x: %d, y: %d",l[0],l[1],l[2],l[3]);
        
        cv::line(image, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), cv::Scalar(255,0,0), 2, CV_AA); //<----- usa essa função e cria uma cv::Mat com fundo transparente, bota uma UIImageView em cima da recordPreview e fica jogando essa cv::Mat lá, tomara qiue fique transparente
    }
    cv::erode(image, image, cv::Mat(),cv::Point(-1,-1),0.5);
    cv::dilate(image, image, cv::Mat(),cv::Point(-1,-1),0.5);//remove smaller part of image
    
    
    
    
    
    
    //image.inv();
    image = 255- image;
    
    
    NSData *data = [NSData dataWithBytes:image.data length:image.elemSize() * image.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(image.cols,                                     // Width
                                        image.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * image.elemSize(),                           // Bits per pixel
                                        image.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    image.release();
    const float whiteMask[6] = { 255,255,255, 255,255,255 };
    CGImageRef myColorMaskedImage = CGImageCreateWithMaskingColors(imageRef, whiteMask);
    CGImageRelease(imageRef);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.imageView setImage:[UIImage imageWithCGImage:myColorMaskedImage]];
        CGImageRelease(myColorMaskedImage);
    });
    
    // dataClass.isOpenCVOn = NO;
    
    /*
     
     CALayer *sheetLinesLayer = nil;
     int currentSublayer = 0;
     NSArray *sublayers = [NSArray arrayWithArray:[self.recordPreview.layer sublayers]];
     while (!sheetLinesLayer && (currentSublayer < [sublayers count])) {
     CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
     if ([[currentLayer name] isEqualToString:@"sheetLinesLayer"]) {
     sheetLinesLayer = nil;
     }
     }
     
     if(!sheetLinesLayer){
     sheetLinesLayer = [CALayer new];
     sheetLinesLayer.name = @"sheetLinesLayer";
     sheetLinesLayer.frame = self.recordPreview.frame;
     [self.recordPreview.layer addSublayer:sheetLinesLayer];
     sheetLinesLayer.delegate = self;
     }
     
     */
    return ;
    
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    // Check that the layer argument is yourLayer (if you are the
    // delegate to more than one layer)
    if ([[layer name] isEqualToString:@"sheetLinesLayer"]){
        
        CGContextRef context = UIGraphicsGetCurrentContext(); //erro de agora: não tem cotexto nenhum, tá desenhando no nada, tem que delgar uma CALayer do recordpreview. (como? no sei)
        CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
        CGContextSetLineWidth(context, 2.0);
        
        
        std::vector<cv::Vec4i>::iterator it = lines.begin();
        for(; it!=lines.end(); ++it) {
            cv::Vec4i l = *it;
            NSLog(@"inicio x: %d, y: %d, fim x: %d, y: %d",l[0],l[1],l[2],l[3]);
            CGContextMoveToPoint(context, l[0]/1.0f, l[1]/1.0f);
            CGContextAddLineToPoint(context, l[2]/1.0f, l[3]/1.0f);
            //cv::line(work_img, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), cv::Scalar(255,0,0), 2, CV_AA);
        }
        CGContextStrokePath(context);
        
    }
    
    // Use the context (second) argument to draw.
}

#pragma mark - Camera initialization:

- (CGAffineTransform)affineTransformForVideoFrame:(CGRect)videoFrame orientation:(AVCaptureVideoOrientation)videoOrientation
{
    CGSize viewSize = self.recordPreview.bounds.size;
    NSString * const videoGravity = captureLayer.videoGravity;
    CGFloat widthScale = 1.0f;
    CGFloat heightScale = 1.0f;
    
    // Move origin to center so rotation and scale are applied correctly
    CGAffineTransform t = CGAffineTransformMakeTranslation(-videoFrame.size.width / 2.0f, -videoFrame.size.height / 2.0f);
    
    switch (videoOrientation) {
        case AVCaptureVideoOrientationPortrait:
            widthScale = viewSize.width / videoFrame.size.width;
            heightScale = viewSize.height / videoFrame.size.height;
            break;
            
        case AVCaptureVideoOrientationPortraitUpsideDown:
            t = CGAffineTransformConcat(t, CGAffineTransformMakeRotation(M_PI));
            widthScale = viewSize.width / videoFrame.size.width;
            heightScale = viewSize.height / videoFrame.size.height;
            break;
            
        case AVCaptureVideoOrientationLandscapeRight:
            t = CGAffineTransformConcat(t, CGAffineTransformMakeRotation(M_PI_2));
            widthScale = viewSize.width / videoFrame.size.height;
            heightScale = viewSize.height / videoFrame.size.width;
            break;
            
        case AVCaptureVideoOrientationLandscapeLeft:
            t = CGAffineTransformConcat(t, CGAffineTransformMakeRotation(-M_PI_2));
            widthScale = viewSize.width / videoFrame.size.height;
            heightScale = viewSize.height / videoFrame.size.width;
            break;
    }
    
    // Adjust scaling to match video gravity mode of video preview
    if (videoGravity == AVLayerVideoGravityResizeAspect) {
        heightScale = MIN(heightScale, widthScale);
        widthScale = heightScale;
    }
    else if (videoGravity == AVLayerVideoGravityResizeAspectFill) {
        heightScale = MAX(heightScale, widthScale);
        widthScale = heightScale;
    }
    
    // Apply the scaling
    t = CGAffineTransformConcat(t, CGAffineTransformMakeScale(widthScale, heightScale));
    
    // Move origin back from center
    t = CGAffineTransformConcat(t, CGAffineTransformMakeTranslation(viewSize.width / 2.0f, viewSize.height / 2.0f));
    
    return t;
}

- (BOOL)createCaptureSessionForCamera:(NSInteger)camera qualityPreset:(NSString *)qualityPreset grayscale:(BOOL)grayscale
{
    
	
    // Set up AV capture
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    if ([devices count] == 0) {
        NSLog(@"No video capture devices found");
        return NO;
    }
    
    if (self.camera == -1) {
        self.camera = -1;
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    else if (self.camera >= 0 && self.camera < [devices count]) {
        captureDevice = [devices objectAtIndex:self.camera] ;
    }
    else {
        self.camera = -1;
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        NSLog(@"Camera number out of range. Using default camera");
    }
    NSError *__autoreleasing* errores = NULL;
    [captureDevice lockForConfiguration:errores];
    if ([captureDevice hasTorch])
        [captureDevice setTorchMode:AVCaptureTorchModeOff];
    
    [captureDevice unlockForConfiguration];
    // Create the capture session
    captureSession = [[AVCaptureSession alloc] init];
    captureSession.sessionPreset = (self.qualityPreset)? self.qualityPreset : AVCaptureSessionPresetHigh;
    
    // Create device input
    NSError *error = nil;
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    
    // Create and configure device output
    videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
    [videoOutput setSampleBufferDelegate:self queue:queue];
    
    videoOutput.alwaysDiscardsLateVideoFrames = YES;
    // captureDevice.activeVideoMinFrameDuration = CMTimeMake(1, 30);
    
    
    // For grayscale mode, the luminance channel from the YUV fromat is used
    // For color mode, BGRA format is used
    OSType format = kCVPixelFormatType_32BGRA;
    
    // Check YUV format is available before selecting it (iPhone 3 does not support it)
    if (grayscale && [videoOutput.availableVideoCVPixelFormatTypes containsObject:
                      [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]]) {
        format = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    }
    
    videoOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:format]
                                                            forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    // Connect up inputs and outputs
    if ([captureSession canAddInput:input]) {
        [captureSession addInput:input];
    }
    
    if ([captureSession canAddOutput:videoOutput]) {
        [captureSession addOutput:videoOutput];
    }
    
    stillImage = [[AVCaptureStillImageOutput alloc] init];
    stillImage.outputSettings = [NSDictionary dictionaryWithObject:AVVideoCodecJPEG
                                                            forKey:AVVideoCodecKey];
    
    
    NSLog(@"canAddOutput: stillImage: %hhd",[captureSession canAddOutput:stillImage]);
    if ([captureSession canAddOutput:stillImage]){
        [captureSession addOutput:stillImage];
    }
    
    
    // Create the preview layer real
    captureLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    [captureLayer setFrame:self.recordPreview.bounds];
    captureLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.recordPreview.layer insertSublayer:captureLayer atIndex:0];
    
    
    
    self.tesseract = [[Tesseract alloc] initWithDataPath:@"tessdata" language: NSLocalizedString(@"first",nil)];
    NSLog(@"Tesseratc language: %@",dataClass.tesseractLanguage);
    
    return YES;
}


@end
