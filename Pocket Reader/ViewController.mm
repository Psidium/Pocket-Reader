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

@interface ViewController () {
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
@synthesize dataClass;
@synthesize count;
@synthesize motionManager;
@synthesize didOneSecondHasPassed;

#pragma mark - Default:
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tabBarController setSelectedIndex:1];
    [self.tabBarController setSelectedIndex:0];
    if (![@"1" isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"Avalue"]]) { // detect first launch
        [[NSUserDefaults standardUserDefaults] setValue:@"1" forKey:@"Avalue"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        //if is the first launch of the app by the user
        //Action here
        
    }
    self.qualityPreset = AVCaptureSessionPresetPhoto; //maximum quality
    captureGrayscale = NO; //Set color capture
    self.camera = -1; //Set back camera
    recognize = NO; //clean Recognize text flag
    [self timerFireMethod:nil]; // prints a red rectangle on the screen for DEBUG
    [self setTorch:NO]; //turn flash off
    dataClass = [PocketReaderDataClass getInstance];
    dataClass.isOpenCVOn = YES;
    dataClass.tesseractLanguage =  NSLocalizedString(@"first",nil);
    n_erode_dilate = 1;
    dataClass.speechRateValue = 0.5;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(announcementFinished:)
                                                 name:UIAccessibilityAnnouncementDidFinishNotification
                                               object:nil];
    if (!UIAccessibilityIsVoiceOverRunning()) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"VoiceOver inactive",nil) message: NSLocalizedString(@"Warning: VoiceOver is currently off. Pocket Reader is meant to be used with VoiceOver feature turned on.", nil) delegate:self cancelButtonTitle: NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [message show];
    }
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timeOut:) userInfo:nil repeats:YES];
    [self createCaptureSessionForCamera:camera qualityPreset:qualityPreset grayscale:captureGrayscale]; //set camera and it view
    [captureSession startRunning]; //start the camera capturing
    self.motionManager = [[CMMotionManager alloc] init];
    if (self.motionManager.accelerometerAvailable) {
        self.motionManager.accelerometerUpdateInterval = 0.1;
        self.motionManager.deviceMotionUpdateInterval = 0.1;
        [self.motionManager startDeviceMotionUpdates];
        [self.motionManager startAccelerometerUpdates];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    dataClass.isOpenCVOn = NO; //disable OpenCV processing and let ARC clean the memory
    [self performSelector:@selector(timerFireMethod:) withObject:nil afterDelay:2.0]; //after 2 seconds turn openCV on again
    
    
    
    // Dispose of any resources that can be recreated.
    
}

- (BOOL) accessibilityPerformMagicTap {
    isTalking=YES;
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(dataClass.isOpenCVOn ? @"Guia desligado" : @"Guia ligado", nil));
    dataClass.isOpenCVOn = !dataClass.isOpenCVOn;
    return YES;
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


-(void)timeOut:(NSTimer *) timer {
    didOneSecondHasPassed = YES;
}

#pragma mark - Tesseract:

- (IBAction)apertouDois:(id)sender
{
    [dataClass.tesseract clear]; //clean the tesseract
    dataClass.tesseract=nil;
    Tesseract *tesseractHolder = [[Tesseract alloc] initWithDataPath:@"tessdata" language:dataClass.tesseractLanguage];
    dataClass.tesseract=tesseractHolder;
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

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //MARK: Most Important Method
    
    if(dataClass.isOpenCVOn && isViewAppearing && didOneSecondHasPassed) {
        
        
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CGRect videoRect = CGRectMake(0.0f, 0.0f, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
        AVCaptureVideoOrientation videoOrientation = AVCaptureVideoOrientationPortrait;
        /*
         
         CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
         
         CIContext *temporaryContext = [CIContext contextWithOptions: nil];
         CGImageRef videoImage = [temporaryContext
         createCGImage:ciImage
         fromRect:videoRect];
         
         
         UIImage *imageBebug = [UIImage imageWithCGImage:videoImage];
         
         CGImageRelease(videoImage);*/
        
        UIImage *imageBebug = [self imageFromSampleBuffer:sampleBuffer];
        
        cv::Mat mat = [imageBebug CVMat];
        
        
        [self processFrame:mat videoRect:videoRect videoOrientation:videoOrientation];
        
        mat.release();
        
        didOneSecondHasPassed = NO;
    }
    // TODO: Depois de detectar a folha cortar ela da foto
    // TODO: pegar a imagem do rolo da câmera
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
                [dataClass.tesseract setImage:img];
                img =nil;
                
                [dataClass.tesseract recognize];
                NSString *textoReconhecido = [dataClass.tesseract recognizedText];
                
                [dataClass.tesseract clear]; //clean the tesseract
                dataClass.tesseract=nil;
                
                Tesseract *tesseractHolder = [[Tesseract alloc] initWithDataPath:@"tessdata" language:dataClass.tesseractLanguage];
                dataClass.tesseract=tesseractHolder;
                
                NSLog(@"%@", textoReconhecido);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
                if (UIAccessibilityIsVoiceOverRunning()) {
                    isTalking=YES;
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                                    textoReconhecido);
                }
                [self.tabBarController setSelectedIndex:1];
                UIAlertView *message = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Texto reconhecido:",nil) message:textoReconhecido delegate:nil cancelButtonTitle: NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
                [message show];
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"AddToHistory"
                 object:textoReconhecido];
                
                [self setTorch:torchPreviousState];
                dataClass.isOpenCVOn =openCVOnPreviousState;
            }
        }];
        recognize=false;
    }
}

-(void) viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    isViewAppearing = YES;
    [self.motionManager startDeviceMotionUpdates];
    if (self.motionManager.accelerometerAvailable) {
        [self.motionManager startDeviceMotionUpdates];
        [self.motionManager startAccelerometerUpdates];
    }
}

-(void) viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    isViewAppearing = NO;
    [self.motionManager stopDeviceMotionUpdates];
    if (self.motionManager.accelerometerAvailable) {
        [self.motionManager stopDeviceMotionUpdates];
        [self.motionManager stopAccelerometerUpdates];
    }
    
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
    
    // MARK: Here comes the OpenCV methods
    
    
    [self findAndDrawSheetByContours:mat];
    mat.release();
    
}



#pragma mark - Findind the sheet


- (void) findAndDrawSheetByContours: (cv::Mat &) mat {
    double imageSize = mat.rows * mat.cols;  //quando era literal n tinha ess alinha
    cv::cvtColor(mat, mat, CV_BGR2GRAY);
    //UIImageWriteToSavedPhotosAlbum([UIImage imageWithCVMat:mat], nil, nil, nil);
    cv::GaussianBlur(mat, mat, cv::Size(3,3), 0);
    //UIImageWriteToSavedPhotosAlbum([UIImage imageWithCVMat:mat], nil, nil, nil);
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Point(9,9));
    //  UIImageWriteToSavedPhotosAlbum([UIImage imageWithCVMat:kernel], nil, nil, nil);
    cv::Mat dilated;
    cv::dilate(mat, dilated, kernel);
    kernel.release();
    //    UIImageWriteToSavedPhotosAlbum([UIImage imageWithCVMat:dilated], nil, nil, nil);
    
    cv::Mat edges;
    cv::Canny(dilated, edges, 84, 3);
    dilated.release();
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
    edges.release();
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
        cv::approxPolyDP(cv::Mat(contoursArea[i]), contoursDraw[i], 40, true);
    }
    //NSLog(@"iniciopoligonopontosetal");
    cv::Point topRight, topLeft, bottomRight, bottomLeft;
    /*for (int i=0; i < contoursArea.size();i++) {
     for(int j=0; j< contoursArea[i].size();j++){
     NSLog(@"ponto [%d][%d]: x: %d y: %d",i,j,contoursArea[i][j].x,contoursArea[i][j].y);
     if (contoursArea[i][j].x > topLeft.x){
     topLeft = contoursArea[i][j];
     }
     }
     }*/
    cv::Rect lugarAtual;
    cv::Point center;
    cv::RotatedRect rotatedRectangle;
    if (UIAccessibilityIsVoiceOverRunning()) {
        CMAccelerometerData * accelerometerData = self.motionManager.accelerometerData;
        NSLog(@"x: %f y: %f  z: %f",accelerometerData.acceleration.x, accelerometerData.acceleration.y, accelerometerData.acceleration.z);
        if (contoursArea.size() > 0) {
            if (ABS(accelerometerData.acceleration.x) > 0.1 || ABS(accelerometerData.acceleration.y) > 0.1) {
                if (!isTalking) {
                    isTalking=YES;
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Alinhe o aparelho na posição horizontal", nil));
                }
            }
            float batata = cv::contourArea(contoursArea[0]);
            lugarAtual = cv::boundingRect(cv::Mat(contoursArea[0]));
            rotatedRectangle = minAreaRect(contoursArea[0]);
            center = cv::Point(lugarAtual.x + (lugarAtual.width/2), lugarAtual.y + (lugarAtual.height/2) );
            NSLog(@"angulation : %f", rotatedRectangle.angle);
            NSLog(@"(center.x - mat.size().width/2)  = %d", (center.x - mat.size().width/2));
            
            NSLog(@"height rotated: %f ", rotatedRectangle.angle);
            
            if (rotatedRectangle.angle < -5 ) {
                if ((rotatedRectangle.size.width < rotatedRectangle.size.height)) {
                    if (!isTalking) {
                        isTalking=YES;
                        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Gire o aparelho no sentido anti-horário", nil));
                        NSLog(@"Gire o aparelho no sentido anti-horário");
                    }
                }
            }
            if (rotatedRectangle.angle > -85 ){
                if ((rotatedRectangle.size.width > rotatedRectangle.size.height)){
                    if (!isTalking) {
                        isTalking=YES;
                        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Gire o aparelho no sentido horário", nil));
                        NSLog(@"Gire o aparelho no sentido horário");
                    }
                }
            }
            
            
            if((center.x - mat.size().width/2) > 5){
                if (!isTalking){
                    isTalking=YES;
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Mova um pouco para a direita", nil));
                }
            } else if((mat.size().width/2 - center.x) > 5){
                if (!isTalking){
                    isTalking=YES;
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Mova um pouco para a esquerda", nil));
                }
            }
            
            
            
            NSLog(@"(center.y - mat.size().height/2)  = %d", (center.y - mat.size().height/2));
            if((center.y - mat.size().height/2) > 5){
                if (!isTalking){
                    isTalking=YES;
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Mova um pouco para trás", nil));
                }
            } else if((mat.size().height/2 - center.y) > 5){
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
    
    
    if (isTalking) {
        if (++self.count == 60) {
            isTalking=NO;
            self.count=0;
        }
        
    } else
        count=0;
    
    cv::Mat drawing = cv::Mat::zeros( mat.size(), CV_8UC3 );
    if (contoursArea.size() > 0) {
        cv::drawContours(drawing, contoursDraw, -1, cv::Scalar(0,255,0),1);
        cv::rectangle(drawing, lugarAtual, cv::Scalar(255,255,0));
        cv::circle(drawing, center, 10, cv::Scalar(255,0,0));
        cv::circle(drawing, cv::Point(mat.size().width/2,mat.size().height/2), 5, cv::Scalar(255,0,255));
        cv::Point2f rect_points[4]; rotatedRectangle.points( rect_points );
        for( int j = 0; j < 4; j++ )
            line( drawing, rect_points[j], rect_points[(j+1)%4], cv::Scalar(255,30,150), 1, 8 );
        cv::putText(drawing, [[NSString stringWithFormat:@"%fº",rotatedRectangle.angle] UTF8String] , rotatedRectangle.center, cv::FONT_HERSHEY_SIMPLEX, 0.5, cv::Scalar(255,30,150));
    }
    
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
        CGImageRelease(myColorMaskedImage);
    });
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
    cv::HoughLinesP(image, lines, 1, CV_PI/180, 130, 50, 10);
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
    
    return ;
    
}

#pragma mark - Camera initialization:

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
    
    
    
    dataClass.tesseract = [[Tesseract alloc] initWithDataPath:@"tessdata" language: NSLocalizedString(@"first",nil)];
    NSLog(@"Tesseratc language: %@",dataClass.tesseractLanguage);
    
    return YES;
}


@end
