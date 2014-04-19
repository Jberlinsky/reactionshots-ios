//
//  RecordingUIViewController.h
//  Ribbit
//
//  Created by Jason Berlinsky on 2/9/14.
//  Copyright (c) 2014 Tord Åsnes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SnapchatClient.h"
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import "RecordingUIViewController.h"

@interface RecordingUIViewController : UIViewController

@property (strong, nonatomic) AVCaptureDevice *device;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) UIImage *captureImage;
@property (strong, nonatomic) NSMutableArray *captureImages;
@property (strong, nonatomic) NSTimer *cameraTimer;
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) NSMutableArray      *dates;
@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) AVAssetWriter *videoWriter;
@property (strong, nonatomic) NSString *senderName;
@property (weak, nonatomic) IBOutlet UIImageView *cameraImageView;

@property bool sentResponse;

- (void)sendResponse;


@end
