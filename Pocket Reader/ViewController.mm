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
#import <sys/types.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>				

@interface ViewController () {
    std::vector<cv::Vec4i> lines;
    UIAlertView *_firstLaunchAlertView;
    UIAlertView *_message;
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
@synthesize firstAppear;

#pragma mark - Default:
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.firstAppear = YES;
    NSString *model = [self platformString];
    if ([model isEqualToString:@"iPod Touch (4 Gen)"] || [model isEqualToString:@"iPhone 3GS"] || [model isEqualToString:@"iPad 2"]) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Unsuported device",nil) message: NSLocalizedString(@"Pocket Reader does not support your device's camera resolution.", nil) delegate:self cancelButtonTitle: NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [message show];
    }
    self.qualityPreset = AVCaptureSessionPresetPhoto; //maximum quality
    captureGrayscale = NO; //Set color capture
    self.camera = -1; //Set back camera
    recognize = NO; //clean Recognize text flag
    [self timerFireMethod:nil];
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
        _message = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"VoiceOver inactive",nil) message: NSLocalizedString(@"Warning: VoiceOver is currently off. Pocket Reader is meant to be used with VoiceOver feature turned on.", nil) delegate:self cancelButtonTitle: NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [_message show];
    }
    [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(timeOut:) userInfo:nil repeats:YES];
    self.motionManager = [[CMMotionManager alloc] init];
    if (self.motionManager.accelerometerAvailable) {
        self.motionManager.accelerometerUpdateInterval = 0.1;
        self.motionManager.deviceMotionUpdateInterval = 0.1;
        [self.motionManager startDeviceMotionUpdates];
        [self.motionManager startAccelerometerUpdates];
        NSLog(@"Device motion started;");
    }

    
    //DEBUG ONLY (because the simulator doesn't have a camera
    if (TARGET_IPHONE_SIMULATOR) {
    //    self.recordPreview.backgroundColor = [UIColor greenColor];
      //  self.imageView.backgroundColor = [UIColor purpleColor];
    }
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView isEqual:_firstLaunchAlertView]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstLaunch"];
        // Não é recomendado chamar esse método ao longo do programa, visto que ele é chamado automaticamente de tempos em tempos. Mas, nesse caso, o usuário não vai querer as intruções duas vezes e pode aconetecer de o app ser encerrado antes do standardUserDefaults ser sincronizado.
        [[NSUserDefaults standardUserDefaults] synchronize];
        // Liga a guia por voz apenas depois de o usuário ter confirmado que leu as instruções de firstLaunch, evitando irritantes interrupções de NO SHEET DETECTED.
        dataClass.isOpenCVOn = YES;
    }
    if ([alertView isEqual:_message]) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"firstLaunch"]) {
            // Delay execution of my block for 2 seconds.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [_firstLaunchAlertView show];
            });
            // Mostra o alerta de first launch se 1. for o fisrt launch 2. o usuário tiver dado dismiss no alerta de VoiceOver desativado (E possivelmente ter ligado o VoiceOver (ou não, mas não interessa...)). Usando essa gambiarra (timer) porque se mandava a  o show do _firstLaunchAlertView aqui, o VoiceOver começava com o ~cursor~ no botão de cancelar e não lia o alerta.
        }
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (self.firstAppear) {
        [self createCaptureSessionForCamera:camera qualityPreset:qualityPreset grayscale:captureGrayscale]; //set camera and it's view
        [captureSession startRunning]; //start the camera capturing
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.firstAppear = NO;
        
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"firstLaunch"]) {
            //ADICIONAR: Existem dois botões nesta tela, chamados Flash e Foto, ao pressionar Flash, o flash do iPhone ou iPod é ligado. Ao pressionar o botão Foto, a foto será forçadamente tirada.
            _firstLaunchAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Instruções", nil) message:NSLocalizedString(@"Para localizar o texto da melhor maneira possível, por favor, posicione o dispositivo no centro da folha, em orientação retrato. Afaste o aparelho da folha com cuidado, tentando manter o smartphone centralizado na folha. Siga então as dicas de enquadramento que a foto será capturada e convertida automaticamente. Pressione Ok para continuar.", nil) delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            dataClass.isOpenCVOn = NO; // Independente se o VoiceOver estiver ligado ou não, liga a guia por voz apenas depois de o usuário ter confirmado que leu as instruções de firstLaunch, evitando irritantes interrupções de NO SHEET DETECTED durante a leitura dessas instruções.
            // Usa pra verificar se não vai colocar um alerta sobre o do alerta de "VoiceOver desligado". O alerta de "Unsupported Device" pode ficar por último no stack de alertView para que o usuário consiga ver que o seu dispositivo não é suportado, primeiramente ligando o VoiceOver.
            [_firstLaunchAlertView show];
        }
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    dataClass.isOpenCVOn = NO;
    [self performSelector:@selector(timerFireMethod:) withObject:nil afterDelay:2.0];
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
    //[self performSegueWithIdentifier:@"firstLaunchSegue" sender:self];
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
    
    if (isTalking) {
        if (++self.count == 60) {
            isTalking=NO;
            self.count=0;
        }
        
    } else
        count=0;
    if(dataClass.isOpenCVOn && isViewAppearing && didOneSecondHasPassed && !isTalking && (self.recordPreview.accessibilityElementIsFocused || !UIAccessibilityIsVoiceOverRunning()) ) {
        
        
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CGRect videoRect = CGRectMake(0.0f, 0.0f, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
        AVCaptureVideoOrientation videoOrientation = AVCaptureVideoOrientationPortrait;
        
        
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
                [dataClass.tesseract recognize];
                NSString *textoReconhecido = [dataClass.tesseract recognizedText];
                [dataClass.tesseract clear]; //clean the tesseract
                dataClass.tesseract=nil;
                
                Tesseract *tesseractHolder = [[Tesseract alloc] initWithDataPath:@"tessdata" language:dataClass.tesseractLanguage];
                dataClass.tesseract=tesseractHolder;
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
                [self.tabBarController setSelectedIndex:1];
                if (UIAccessibilityIsVoiceOverRunning()) {
                    isTalking=YES;
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                                    textoReconhecido);
                }
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
    [super viewWillAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    isViewAppearing = NO;
    [self.motionManager stopDeviceMotionUpdates];
    if (self.motionManager.accelerometerAvailable) {
        [self.motionManager stopDeviceMotionUpdates];
        [self.motionManager stopAccelerometerUpdates];
    }
    [super viewWillDisappear:animated];
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
    double imageSize = mat.rows * mat.cols;
    cv::cvtColor(mat, mat, CV_BGR2GRAY);
    cv::GaussianBlur(mat, mat, cv::Size(3,3), 0);
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Point(9,9));
    cv::Mat dilated;
    cv::dilate(mat, dilated, kernel);
    kernel.release();
    cv::Mat edges;
    cv::Canny(dilated, edges, 84, 3);
    dilated.release();
    lines.clear();
    cv::HoughLinesP(edges, lines, 1, CV_PI/180, 25);
    std::vector<cv::Vec4i>::iterator it = lines.begin();
    for(; it!=lines.end(); ++it) {
        cv::Vec4i l = *it;
        cv::line(edges, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), cv::Scalar(255,0,0), 2, 8);
    }
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
        if (accelerometerData.acceleration.y > 0.1)
        {
            if (!isTalking) {
                isTalking=YES;
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Topo do aparelho mais para cima", nil));
            }
        }
        if (accelerometerData.acceleration.y < -0.1)
        {
            if (!isTalking) {
                isTalking=YES;
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Parte de baixo do aparelho mais para cima", nil));
            }
        }
        if (accelerometerData.acceleration.x > 0.1)
        {
            if (!isTalking) {
                isTalking=YES;
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Direita do aparelho mais para cima", nil));
            }
        }
        else if (accelerometerData.acceleration.x < -0.1)
        {
            if (!isTalking) {
                isTalking=YES;
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Esquerda do aparelho mais para cima", nil));
            }
        }
        if (contoursArea.size() > 0) {
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
            
            if (!isTalking){
                isTalking=YES;
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Aproxime o aparelho da folha com cuidado", nil));
            }
            NSLog(@"tamhho %f > %f ? ", batata, ((imageSize / 1.21) * dataClass.tolerance));
            
            if (batata > ((imageSize / 1.21) * dataClass.tolerance)  ){ // era 112000
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
    
    
    
    
    cv::Mat drawing = cv::Mat::zeros( mat.size(), CV_8UC3 );
    if (contoursArea.size() > 0) {
        cv::drawContours(drawing, contoursDraw, -1, cv::Scalar(0,255,0),1);
        //cv::rectangle(drawing, lugarAtual, cv::Scalar(255,255,0));
        cv::circle(drawing, center, 10, cv::Scalar(255,0,0));
        cv::circle(drawing, cv::Point(mat.size().width/2,mat.size().height/2), 5, cv::Scalar(255,0,255));
        cv::Point2f rect_points[4]; rotatedRectangle.points( rect_points );
        for( int j = 0; j < 4; j++ )
            line( drawing, rect_points[j], rect_points[(j+1)%4], cv::Scalar(255,30,150), 1, 8 );
        //cv::putText(drawing, [[NSString stringWithFormat:@"%fº",rotatedRectangle.angle] UTF8String] , rotatedRectangle.center, cv::FONT_HERSHEY_SIMPLEX, 0.5, cv::Scalar(255,30,150));
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
    const CGFloat blackMask[6] = { 0,0,0, 0,0,0 };
    CGImageRef myColorMaskedImage = CGImageCreateWithMaskingColors(imageRef, blackMask);
    CGImageRelease(imageRef);
    UIImage* greenboundsImage = [UIImage imageWithCGImage:myColorMaskedImage];
    CGImageRelease(myColorMaskedImage);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.imageView setHidden:NO];
        [self.imageView setImage:greenboundsImage];
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
    const CGFloat whiteMask[6] = { 255,255,255, 255,255,255 };
    CGImageRef myColorMaskedImage = CGImageCreateWithMaskingColors(imageRef, whiteMask);
    CGImageRelease(imageRef);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.imageView setImage:[UIImage imageWithCGImage:myColorMaskedImage]];
        CGImageRelease(myColorMaskedImage);
    });
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

- (NSString *) platformString {
    // Gets a string with the device model
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char *) malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 2G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,2"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"iPhone 4 (CDMA)";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch (1 Gen)";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch (2 Gen)";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch (3 Gen)";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch (4 Gen)";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch (5 Gen)";
    
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad1,2"])      return @"iPad 3G";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    
    return platform;
}


@end
