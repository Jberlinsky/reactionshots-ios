//
//  ImageViewController.h
//  Ribbit
//
//  Created by Tord Åsnes on 04/11/13.
//  Copyright (c) 2013 Tord Åsnes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "SnapchatClient.h"
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

#define FILE_PATH_KEY @"IQFilePath"
#define FILE_SIZE_KEY @"IQFileSize"
#define FILE_CREATE_DATE_KEY @"IQFileCreateDate"

@interface ImageViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) PFObject *message;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIImageView *cameraImageView;
@property (strong, nonatomic) AVCaptureDevice *device;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) UIImage *captureImage;
@property (strong, nonatomic) NSMutableArray *captureImages;
@property (strong, nonatomic) NSTimer *cameraTimer, *countdownTimer;
@property (strong, nonatomic) NSString *senderName;
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) NSMutableArray      *dates;
@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) AVAssetWriter *videoWriter;
@property int timeRemaining;
@property bool sentResponse;

- (void)timeOut;


@end
