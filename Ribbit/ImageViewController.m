
//
//  ImageViewController.m
//  Ribbit
//
//  Created by Tord Åsnes on 04/11/13.
//  Copyright (c) 2013 Tord Åsnes. All rights reserved.
//

#import "ImageViewController.h"

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
    _path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/video.mov"];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath:_path error:&error]) {
        NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
    }

#if !TARGET_IPHONE_SIMULATOR
    [self prepareCamera];
    [self setupTimer];
#endif
}

- (void)prepareCamera
{
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:_path]
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

- (void)sendResponse
{
    // TODO send the file at TemporaryVideoLocation to Snapchat
    [SnapchatClient sendSnap: [NSData dataWithContentsOfFile: _path] withType:@"video" withRecipients:[NSArray arrayWithObject: self.senderName] fromUser:[SnapchatClient currentUser] withBlock:^(BOOL completed, NSError *error) {
        [DejalActivityView removeView];
    }];
}

- (void)stitchVideo
{
    [self writeImagesAsMovie: self.captureImages toPath: _path];
}

- (void) writeImagesAsMovie:(NSArray *)array toPath:(NSString*)path {
    
    NSString *documents = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
    
    UIImage *first = [array objectAtIndex: 0];
    
    CGSize frameSize = first.size;
    
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  [NSURL fileURLWithPath:path] fileType:AVFileTypeMPEG4
                                                              error:&error];
    
    if(error) {
        NSLog(@"error creating AssetWriter: %@",[error description]);
    }
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:frameSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:frameSize.height], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput* writerInput = [AVAssetWriterInput
                                        assetWriterInputWithMediaType:AVMediaTypeVideo
                                        outputSettings:videoSettings];
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.width] forKey:(NSString*)kCVPixelBufferWidthKey];
    [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.height] forKey:(NSString*)kCVPixelBufferHeightKey];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                     sourcePixelBufferAttributes:attributes];
    
    [videoWriter addInput:writerInput];
    
    // fixes all errors
    writerInput.expectsMediaDataInRealTime = YES;
    
    //Start a session:
    BOOL start = [videoWriter startWriting];
    NSLog(@"Session started? %d", start);
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    CVPixelBufferRef buffer = NULL;
    buffer = [self pixelBufferFromCGImage:[first CGImage]];
    BOOL result = [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
    
    if (result == NO) //failes on 3GS, but works on iphone 4
        NSLog(@"failed to append buffer");
    
    if(buffer)
        CVBufferRelease(buffer);
    
    [NSThread sleepForTimeInterval:0.05];
    
    int reverseSort = NO;
    NSArray *newArray = array;
    
    float delta = 1.0/[newArray count];
    
    int fps = 15;
    
    int i = 0;
    for (UIImage *image in newArray)
    {
        if (adaptor.assetWriterInput.readyForMoreMediaData)
        {
            
            i++;
            NSLog(@"inside for loop %d ",i);
            CMTime frameTime = CMTimeMake(1, fps);
            CMTime lastTime=CMTimeMake(i, fps);
            CMTime presentTime=CMTimeAdd(lastTime, frameTime);
            
            UIImage *imgFrame = image ;
            buffer = [self pixelBufferFromCGImage:[imgFrame CGImage]];
            BOOL result = [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
            
            if (result == NO) //failes on 3GS, but works on iphone 4
            {
                NSLog(@"failed to append buffer");
                NSLog(@"The error is %@", [videoWriter error]);
            }
            if(buffer)
                CVBufferRelease(buffer);
            [NSThread sleepForTimeInterval:0.05];
        }
        else
        {
            NSLog(@"error");
            i--;
        }
        [NSThread sleepForTimeInterval:0.02];
    }
    
    //Finish the session:
    [writerInput markAsFinished];
    [videoWriter finishWriting];
    CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
}

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(image),
                        CGImageGetHeight(image), kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                        &pxbuffer);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, CGImageGetWidth(image),
                                                 CGImageGetHeight(image), 8, 4*CGImageGetWidth(image), rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (void)_completed {
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_path error: nil];
    NSDictionary *dictInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              _path, FILE_PATH_KEY,
                              [fileAttributes objectForKey:NSFileSize], FILE_SIZE_KEY,
                              [fileAttributes objectForKey: NSFileCreationDate], FILE_CREATE_DATE_KEY,
                              nil];
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
    [_dates addObject:[NSDate date]];
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
