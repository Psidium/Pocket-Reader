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

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.qualityPreset = AVCaptureSessionPresetPhoto;
    captureGrayscale = YES;
    self.camera = -1;
    recognize=false;
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
    UIAlertView *alerta = [[UIAlertView alloc] initWithTitle:@"Língua:" message:@"Selecione a língua:" delegate:self cancelButtonTitle:@"Cancelar" otherButtonTitles:@"Português",@"Inglês",@"Espanhol", nil];
    [alerta show];
}

- (IBAction)apertouTres:(id)sender
{
    //UIImageWriteToSavedPhotosAlbum([UIImage imageNamed:@"image_sample.jpg"], nil, nil, nil);
    [self.imageView setImage:[UIImage imageNamed:@"image_sample.png"]];
    //[tesseract setVariableValue:@"ABCDEFGHIJKLMNOPQRSTUVWXYZÇabcdefghijklmnopqrstuvwxyzçÁÉÍÓÚáéíóúÜüÔôêÊÀàõÕãÃ" forKey:@"tessedit_char_whitelist"];
    [self.tesseract setImage:[UIImage imageNamed:@"image_sample.png"]];
    NSLog(@"começa a reconhecer");
    NSLog([self.tesseract recognize] ? @"Reconheceu" : @"não reconheceu");
    NSLog(@"terminou");
    NSLog(@"%@",[self.tesseract description]);
    NSLog(@"%@", [self.tesseract recognizedText]);
    NSLog(@"deveria ter mostrado");
    if (UIAccessibilityIsVoiceOverRunning()) {
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                        [self.tesseract recognizedText]);
    }
    // UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Lido:" message:[tesseract recognizedText] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    //[message show];
    
    
    [self.tesseract clear];
    
    
}

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
    }}}
}

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
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    if(recognize){
        //[captureSession stopRunning];
        //[tesseract setVariableValue:@"ABCDEFGHIJKLMNOPQRSTUVWXYZÇabcdefghijklmnopqrstuvwxyzçÁÉÍÓÚáéíóúÜüÔôêÊÀàõÕãÃ!@#$%¨&*()[]{}\"'" forKey:@"tessedit_char_whitelist"];
        NSLog(@"%@",[stillImage description]);
        AVCaptureConnection *vc = [stillImage connectionWithMediaType:AVMediaTypeVideo];
        [stillImage captureStillImageAsynchronouslyFromConnection:vc completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            NSLog(@"bloco de AVCaptureStillImageOutput capturestillimageassuybncaslopdfaslfgrofmcoennction");
            NSLog(@"%@",error);
            NSLog(@"%@", imageDataSampleBuffer);
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer]; //error-------------------------------------------------------------------
            UIImage *img = [[UIImage alloc] initWithData:imageData];
            img= [self gs_convert_image:img];
            
            NSLog(@"%@", [img description]);
            // = [self imageFromSampleBuffer:sampleBuffer];
            if (img!=nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.imageView setImage:img]; });
                //UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
                NSLog(@"saiu uimage");
                
                
                [self.tesseract setImage:img] ;
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
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Lsadsaddaso:" message:textoReconhecido delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [message show];
            }
            
        }];
        
        
        recognize=false;
        //[captureSession startRunning];
        NSLog(@"voltou a funcionar");
    }
    
    /* if (format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
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
     
     
     */
}

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    NSLog(@"imageFromSampleBuffer: called");
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    //  size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 0, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    
    // Free up the context and color space
    //CGContextRelease(context);
    //CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    /*  CGImageRelease(quartzImage);*/ //ARC  is used
    
    return (image);
}

- (void)processFrame:(cv::Mat &)mat videoRect:(CGRect)rect videoOrientation:(AVCaptureVideoOrientation)videOrientation
{
    /* // Shrink video frame to 320X240
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
     
     // Detect RETÂNGULOS
     std::vector<cv::Rect> retangulo;
     
     //_faceCascade.detectMultiScale(mat, faces, 1.1, 2, kHaarOptions, cv::Size(60, 60));
     
     //ACHA O QUADRADO
     
     
     
     // Dispatch updating of face markers to main queue
     dispatch_sync(dispatch_get_main_queue(), ^{
     [self displaySheet:retangulo
     forVideoRect:rect
     videoOrientation:videOrientation];
     });*/
}

- (void)displaySheet:(const std::vector<cv::Rect> &)faces forVideoRect:(CGRect)rect videoOrientation:(AVCaptureVideoOrientation)videoOrientation
{
    NSArray *sublayers = [NSArray arrayWithArray:[_recordPreview.layer sublayers]];
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
            featureLayer.borderColor = [[UIColor redColor] CGColor];
            featureLayer.borderWidth = 10.0f;
			[self.view.layer addSublayer:featureLayer];
		}
        
        featureLayer.frame = faceRect;
    }
    
    [CATransaction commit];
}

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
    /* _lastFrameTimestamp = 0;
     _frameTimesIndex = 0;
     _captureQueueFps = 0.0f;
     _fps = 0.0f;*/
	
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
