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

#import "ViewController.h"

@interface ViewController ()
@end

@implementation ViewController

@synthesize camera;
@synthesize captureGrayscale;
@synthesize qualityPreset;
@synthesize captureSession;
@synthesize captureDevice;
@synthesize videoOutput;
@synthesize captureLayer;
@synthesize stillImage;
@synthesize tesseract;


#pragma mark - Default:
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.qualityPreset = AVCaptureSessionPresetPhoto;
    captureGrayscale = YES;
    self.camera = -1;
    recognize = NO;
    isOpenCVOn = NO;
    [self createCaptureSessionForCamera:camera qualityPreset:qualityPreset grayscale:captureGrayscale];
    [captureSession startRunning];
    /*AVCaptureDevice *camera = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][1];
     if (camera == nil){
     //aviso de erro e fecha o app
     }
     captureSession = [[AVCaptureSession alloc] init];
     AVCaptureDeviceInput *videoInputCamera = [[AVCaptureDeviceInput alloc] initWithDevice:camera error:nil];
     [captureSession addInput:videoInputCamera];
     
     captureLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
     captureLayer.frame = self.recordPreview.bounds;
     [captureLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
     [self.recordPreview.layer addSublayer:captureLayer];
     [captureSession startRunning];
     NSLog(@"batata");*/
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Buttons:

- (IBAction)apertouUm:(id)sender
{
    if (camera==-1 || camera==0)
        camera=1;
    else
        camera=0;
    NSLog(@"%d",camera);
    [self setCamera:camera];
    
}

- (void)setCamera:(int)camera
{
    if (captureSession) {
        NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        
        [captureSession beginConfiguration];
        
        [captureSession removeInput:[[captureSession inputs] lastObject]];
        
        if (self.camera >= 0 && self.camera < [devices count]) {
            captureDevice = [devices objectAtIndex:self.camera];
        }
        else {
            captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        }
        
        // Create device input
        NSError *error = nil;
        AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
        [captureSession addInput:input];
        
        [captureSession commitConfiguration];
    }
    
}

- (IBAction)apertouDois:(id)sender
{
    UIAlertView *alerta = [[UIAlertView alloc] initWithTitle:@"Língua:" message:@"Selecione a língua:" delegate:self cancelButtonTitle:@"Cancelar" otherButtonTitles:@"Português",@"Inglês",@"Espanhol",@"Alemão", nil];
    [alerta show];
}

- (IBAction)apertouTres:(id)sender
{
    isOpenCVOn = !isOpenCVOn;
    
}

- (IBAction)handleRotation:(UIRotationGestureRecognizer *)sender {
    sender.view.transform = CGAffineTransformRotate(sender.view.transform, sender.rotation);
    sender.rotation = 0;
}

- (IBAction)batata:(id)sender {
}

- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    if(![self.imageView isHidden]){
        CGPoint translation = [recognizer translationInView:self.imageView];
        recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                             recognizer.view.center.y + translation.y);
        [recognizer setTranslation:CGPointMake(0, 0) inView:self.imageView];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint velocity = [recognizer velocityInView:self.view];
        CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
        CGFloat slideMult = magnitude / 200;
        NSLog(@"magnitude: %f, slideMult: %f", magnitude, slideMult);
        
        float slideFactor = 0.1 * slideMult; // Increase for more of a slide
        CGPoint finalPoint = CGPointMake(recognizer.view.center.x + (velocity.x * slideFactor),
                                         recognizer.view.center.y + (velocity.y * slideFactor));
        finalPoint.x = MIN(MAX(finalPoint.x, 0), self.view.bounds.size.width);
        finalPoint.y = MIN(MAX(finalPoint.y, 0), self.view.bounds.size.height);
        
        [UIView animateWithDuration:slideFactor*2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            recognizer.view.center = finalPoint;
        } completion:nil];
        
    }
}

- (IBAction)handlePinch:(UIPinchGestureRecognizer *)sender {
    sender.view.transform = CGAffineTransformScale(sender.view.transform, sender.scale, sender.scale);
    sender.scale = 1;
}

- (IBAction)handleTap:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self.imageView setHidden:YES];
    }
}

#pragma mark - Tesseract:

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.tesseract clear];
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Português"]) {
        Tesseract *tesseractHolder = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"por"];
        if(tesseractHolder) {
            tesseract=tesseractHolder;
            NSLog(@"linguagem muda pra por");
            recognize=true;
        } else
            NSLog(@"erro na troca de linguagem pra por");
    }
    else { if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Inglês"]) {
        Tesseract *tesseractHolder = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"eng"];
        if(tesseractHolder) {
            tesseract=tesseractHolder;
            NSLog(@"linguagem muda pra eng");
            recognize=true;
        } else
            NSLog(@"erro na troca de linguagem pra eng");
    }
    else { if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Espanhol"]) {
        Tesseract *tesseractHolder = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"spa"];
        if(tesseractHolder) {
            tesseract=tesseractHolder;
            NSLog(@"linguagem muda pra spa");
            recognize=true;
        } else
            NSLog(@"erro na troca de linguagem pra spa");
    }
    else { if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Alemão"]) {
        Tesseract *tesseractHolder = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"deu"];
        if(tesseractHolder) {
            tesseract=tesseractHolder;
            NSLog(@"linguagem muda pra deu");
            recognize=true;
        } else
            NSLog(@"erro na troca de linguagem pra deu");
    }}}}
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
    //MARK: metodo mais importante
    if(isOpenCVOn) {
        
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);
        CGRect videoRect = CGRectMake(0.0f, 0.0f, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
        AVCaptureVideoOrientation videoOrientation = AVCaptureVideoOrientationPortrait;
        
        if (format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
            // For grayscale mode, the luminance channel of the YUV data is used
            CVPixelBufferLockBaseAddress(pixelBuffer, 0);
            void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
            
            cv::Mat mat(videoRect.size.height, videoRect.size.width, CV_8UC1, baseaddress, 0);
            
            [self processFrame:mat videoRect:videoRect videoOrientation:videoOrientation];
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        }
        else if (format == kCVPixelFormatType_32BGRA) {
            // For color mode a 4-channel cv::Mat is created from the BGRA data
            CVPixelBufferLockBaseAddress(pixelBuffer, 0);
            void *baseaddress = CVPixelBufferGetBaseAddress(pixelBuffer);
            
            cv::Mat mat(videoRect.size.height, videoRect.size.width, CV_8UC4, baseaddress, 0);
            
            [self processFrame:mat videoRect:videoRect videoOrientation:videoOrientation];
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        }
        else {
            NSLog(@"Unsupported video format");
        }
    }
    
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    if(recognize){
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];});
        //[tesseract setVariableValue:@"ABCDEFGHIJKLMNOPQRSTUVWXYZÇabcdefghijklmnopqrstuvwxyzçÁÉÍÓÚáéíóúÜüÔôêÊÀàõÕãÃ!@#$%¨&*()[]{}\"'" forKey:@"tessedit_char_whitelist"];
        NSLog(@"%@",[stillImage description]);
        AVCaptureConnection *vc = [stillImage connectionWithMediaType:AVMediaTypeVideo];
        [stillImage captureStillImageAsynchronouslyFromConnection:vc completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            NSLog(@"bloco de AVCaptureStillImageOutput capturestillimageassuybncaslopdfaslfgrofmcoennction");
            NSLog(@"%@",error);
            NSLog(@"%@", imageDataSampleBuffer);
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *img = [[UIImage alloc] initWithData:imageData];
            img=[self gs_convert_image:img];
            
            NSLog(@"%@", [img description]);
            // = [self imageFromSampleBuffer:sampleBuffer];
            if (img!=nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.imageView setImage:img];
                    [self.imageView setHidden:NO];
                    
                    [MBProgressHUD hideHUDForView:self.view animated:YES];});
                //UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil); //NEEDED TO SAVE TO CAMERA ROLL
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
                if (UIAccessibilityIsVoiceOverRunning()) {
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                                    textoReconhecido);
                }
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Texto reconhecido:" message:textoReconhecido delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [message show];
            }
        }];
        recognize=false;
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
    
    videOrientation = AVCaptureVideoOrientationPortrait;
    
    // Detect faces
    std::vector<cv::Rect> sheet;
    // MARK: AQUI ENTRA O OPENCV
    //_faceCascade.detectMultiScale(mat, faces, 1.1, 2, kHaarOptions, cv::Size(60, 60))
    
    
    // Dispatch updating of face markers to main queue
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self displaySheet:sheet
              forVideoRect:rect
          videoOrientation:videOrientation];
    });
}

// Update face markers given vector of face rectangles
- (void)displaySheet:(const std::vector<cv::Rect> &)squares
        forVideoRect:(CGRect)rect
    videoOrientation:(AVCaptureVideoOrientation)videoOrientation
{
    NSArray *sublayers = [NSArray arrayWithArray:[self.view.layer sublayers]];
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
    //CGAffineTransform t = [self affineTransformForVideoFrame:rect orientation:videoOrientation];
    
    for (int i = 0; i < squares.size(); i++) {
        
        CGRect faceRect;
        faceRect.origin.x = squares[i].x;
        faceRect.origin.y = squares[i].y;
        faceRect.size.width = squares[i].width;
        faceRect.size.height = squares[i].height;
        
        //   faceRect = CGRectApplyAffineTransform(faceRect, t);
        
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
            featureLayer.borderColor = [[UIColor redColor] CGColor];
            featureLayer.borderWidth = 10.0f;
			[self.view.layer addSublayer:featureLayer];
		}
        
        featureLayer.frame = faceRect;
    }
    
    [CATransaction commit];
}



#pragma mark - OpenCV (C++):
int thresh = 50, N = 11;

// helper function:
// finds a cosine of angle between vectors
// from pt0->pt1 and from pt0->pt2
double angle( cv::Point pt1, cv::Point pt2, cv::Point pt0 )
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

- (std::vector<std::vector<cv::Point> >)findSquaresInImage:(cv::Mat)_image
{
    std::vector<std::vector<cv::Point> > squares;
    //blur will enhance edge detection
    cv::Mat blurred(_image);
    cv::medianBlur(_image, blurred, 9);
    NSLog(@"medianBlur(_image, blurred, 9);");
    
    cv::Mat gray0(blurred.size(), CV_8U), gray;
    cv::vector<cv::vector<cv::Point> > contours;
    
    // find squares in every color plane of the image
    for (int c = 0; c < 3; c++)
    {
        int ch[] = {c, 0};
        mixChannels(&blurred, 1, &gray0, 1, ch, 1);
        NSLog(@"mixChannels(&blurred, 1, &gray0, 1, ch, 1);");
        
        // try several threshold levels
        const int threshold_level = 2;
        for (int l = 0; l < threshold_level; l++)
        {
            // Use Canny instead of zero threshold level!
            // Canny helps to catch squares with gradient shading
            if (l == 0)
            {
                Canny(gray0, gray, 10, 20, 3); //
                
                // Dilate helps to remove potential holes between edge segments
                dilate(gray, gray, cv::Mat(), cv::Point(-1,-1));
            }
            else
            {
                gray = gray0 >= (l+1) * 255 / threshold_level;
                NSLog(@"gray = gray0 >= (l+1) * 255 / %d;", threshold_level);
            }
            
            // Find contours and store them in a list
            findContours(gray, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
            NSLog(@"findContours(gray, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);");
            
            // Test contours
            cv::vector<cv::Point> approx;
            for (size_t i = 0; i < contours.size(); i++)
            {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                approxPolyDP(cv::Mat(contours[i]), approx, arcLength(cv::Mat(contours[i]), true)*0.02, true);
                NSLog(@"approxPolyDP(cv::Mat(contours[%lu]), approx, arcLength(cv::Mat(contours[%lu]), true)*0.02, true); %lu",i, i, contours.size());

                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                if (approx.size() == 4 &&
                    fabs(contourArea(cv::Mat(approx))) > 1000 &&
                    isContourConvex(cv::Mat(approx)))
                {
                    double maxCosine = 0;
                    
                    for (int j = 2; j < 5; j++)
                    {
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                        NSLog(@" double cosine = fabs(angle(approx[j porc 4], approx[j-2], approx[j-1]));");
                    }
                    
                    if (maxCosine < 0.3){
                        squares.push_back(approx);
                        NSLog(@" squares.push_back(approx);");
                    }
                }
            }
        }
    }
    return squares;
}

void debugSquares( std::vector<std::vector<cv::Point> > squares, cv::Mat &image )
{
    /*  //
     */
    for ( int i = 0; i< squares.size(); i++ ) {
        // draw contour
        cv::drawContours(image, squares, i, cv::Scalar(255,0,0), 1, 8, std::vector<cv::Vec4i>(), 0, cv::Point());
        NSLog(@" cv::drawContours(image, squares, i, cv::Scalar(255,0,0), 1, 8, std::vector<cv::Vec4i>(), 0, cv::Point());");
        // draw bounding rect
        cv::Rect rect = boundingRect(cv::Mat(squares[i]));
        cv::rectangle(image, rect.tl(), rect.br(), cv::Scalar(0,255,0), 2, 8, 0);
        NSLog(@"cv::rectangle(image, rect.tl(), rect.br(), cv::Scalar(0,255,0), 2, 8, 0);");
        
        // draw rotated rect
        cv::RotatedRect minRect = minAreaRect(cv::Mat(squares[i]));
        cv::Point2f rect_points[4];
        minRect.points( rect_points );
        for ( int j = 0; j < 4; j++ ) {
            cv::line( image, rect_points[j], rect_points[(j+1)%4], cv::Scalar(0,0,255), 1, 8 ); // blue
            NSLog(@"cv::line( image, rect_points[j], rect_points[(j+1)b 4], cv::Scalar(0,0,255), 1, 8 ); // blue");
        }
    }
    
    // return ;
}


#pragma mark - Camera initialization:

- (CGAffineTransform)affineTransformForVideoFrame:(CGRect)videoFrame orientation:(AVCaptureVideoOrientation)videoOrientation
{
    CGSize viewSize = self.view.bounds.size;
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
    
    // Create the preview layer
    captureLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    [captureLayer setFrame:self.recordPreview.bounds];
    captureLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.recordPreview.layer insertSublayer:captureLayer atIndex:0];
    
    self.tesseract = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"por"];
    
    return YES;
}


@end
