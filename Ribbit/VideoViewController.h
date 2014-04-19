//
//  ImageViewController.h
//  Ribbit
//
//  Created by Tord Åsnes on 04/11/13.
//  Copyright (c) 2013 Tord Åsnes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SnapchatClient.h"
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import "RecordingUIViewController.h"
#import <MediaPlayer/MediaPlayer.h>

#define FILE_PATH_KEY @"IQFilePath"
#define FILE_SIZE_KEY @"IQFileSize"
#define FILE_CREATE_DATE_KEY @"IQFileCreateDate"

@interface VideoViewController : RecordingUIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) PFObject *message;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIImageView *cameraImageView;
@property (strong, nonatomic) NSTimer *countdownTimer;
@property (strong, nonatomic) NSTimer *movieTimer;


@property int timeRemaining;

@property (nonatomic, retain) MPMoviePlayerController *moviePlayer;
@property (nonatomic, retain) UIViewController *parent;


- (void)timeOut;



- (void)createTimerDisappearMovieAfter:(NSTimeInterval)interval;
- (void)disappearMovie;

@end
