
//
//  ImageViewController.m
//  Ribbit
//
//  Created by Tord Åsnes on 04/11/13.
//  Copyright (c) 2013 Tord Åsnes. All rights reserved.
//

#import "ImageViewController.h"
#import "VideoWriter.h"

#define DEGREES_TO_RADIANS(x) (M_PI * (x) / 180.0)

@interface ImageViewController ()

@end

@implementation ImageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    NSURL *imageFileUrl = [SnapchatClient fileURLFromMessage: self.message];
    self.timeRemaining = [[self.message objectForKey:@"time"] intValue] + 1;
    NSData *imageData = [NSData dataWithContentsOfURL:imageFileUrl];
    self.imageView.image = [UIImage imageWithData:imageData];
    
    self.senderName = [self.message objectForKey:@"senderName"];
    [self setCountdownTitle: self.timeRemaining];
    [self setupCountdownTimer];
}

- (void)setCountdownTitle:(int)secondsRemaining
{
    NSString *countdown = @"";
    if (secondsRemaining != 0)
    {
        if (secondsRemaining < 0)
            [self timeOut];
        countdown = [NSString stringWithFormat:@" (%i)", secondsRemaining];
    }
    NSString *title = [NSString stringWithFormat:@"Sent from %@%@", self.senderName, countdown];
    self.navigationItem.title  = title;
}

- (void)viewWillAppear: (BOOL)animated
{
    self.path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/video.mov"];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath:self.path error:&error]) {
        NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
    }

#if !TARGET_IPHONE_SIMULATOR
    [self prepareCamera];
    [self setupTimer];
#endif
}

- (void)prepareCamera
{
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:self.path]
                                            fileType:AVFileTypeMPEG4
                                               error:nil];
    self.captureImages = [NSMutableArray array];
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront)
            self.device = device;
    }
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error: nil];
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    output.alwaysDiscardsLateVideoFrames = YES;
    
    dispatch_queue_t queue;
    queue = dispatch_queue_create("cameraQueue", NULL);
    [output setSampleBufferDelegate: self queue: queue];
    
    NSString *key = (NSString *) kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt: kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [output setVideoSettings: videoSettings];
    
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession addInput: input];
    [self.captureSession addOutput: output];
    [self.captureSession setSessionPreset: AVCaptureSessionPresetPhoto]; // TODO ???
    
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    self.previewLayer.frame = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width);
    self.previewLayer.orientation = AVCaptureVideoOrientationLandscapeRight;
    
    [self.captureSession startRunning];
}

- (void) captureOutput: (AVCaptureOutput *)captureOutput didOutputSampleBuffer: (CMSampleBufferRef)sampleBuffer fromConnection: (AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    self.captureImage = [UIImage imageWithCGImage:newImage scale: 1.0f orientation:UIImageOrientationDownMirrored];
    
    CGImageRelease(newImage);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

- (void)sendVideoResponse
{
#if TARGET_IPHONE_SIMULATOR
#else
    [self stitchVideo];
    [self sendResponse];
#endif
    self.sentResponse = true;
}

- (void)stitchVideo
{
    [VideoWriter writeImagesAsMovie: self.captureImages toPath: self.path];
}


- (void)setupTimer
{
    self.cameraTimer = [NSTimer scheduledTimerWithTimeInterval:0.15f target:self selector:@selector(snapshot) userInfo:nil repeats:YES];
}

- (void)setupCountdownTimer
{
    self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(countdown) userInfo:nil repeats:YES];
}

- (void)countdown
{
    self.timeRemaining--;
    [self setCountdownTitle: self.timeRemaining];
}

- (void)snapshot
{
    [self.captureImages addObject:self.captureImage];
    [self.dates addObject:[NSDate date]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self respondsToSelector:@selector(timeOut)]) {
        [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(timeOut) userInfo:Nil repeats:NO];
    }
}

#pragma mark - Helper methods

- (void)timeOut
{
    [self.captureSession stopRunning];
    [self.cameraTimer invalidate];
    [self.countdownTimer invalidate];
    if (!self.sentResponse)
        [self sendVideoResponse];
    [self.navigationController popViewControllerAnimated:YES];
}


@end
