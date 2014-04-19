//
//  InboxViewController.m
//  Ribbit
//
//  Created by Tord Åsnes on 03/11/13.
//  Copyright (c) 2013 Tord Åsnes. All rights reserved.
//

#import "InboxViewController.h"
#import "ImageViewController.h"
#import "MSCellAccessory.h"
#import "VideoViewController.h"

@interface InboxViewController ()

@end

@implementation InboxViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (![SnapchatClient currentUser]) {
        [self performSegueWithIdentifier:@"showLogin" sender:self];
    }
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(retriveMessages) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setHidden:NO];
    
    if (self.messages.count <= 0) {
        [self retriveMessages];
    }
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    SCMessage *message = [self.messages objectAtIndex:indexPath.row];
    cell.textLabel.text = [message objectForKey:@"senderName"];
    
    UIColor *color = [UIColor colorWithRed:0.553 green:0.439 blue:0.718 alpha:1.0];
    cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_DISCLOSURE_INDICATOR color:color];
    
    NSString *fileType = [message objectForKey:@"fileType"];
    BOOL isOurs = [[message objectForKey:@"isReaction"] boolValue];
    
    if (isOurs) {
        cell.imageView.image = [UIImage imageNamed:@"icon_reaction"];
    }
    else if ([fileType isEqualToString:@"image"]) {
        cell.imageView.image = [UIImage imageNamed:@"icon_image"];
    } else {
        //cell.imageView.image = [UIImage imageNamed:@"icon_video"];
        // HACK HACK HACK
        // FIXME BEFORE RELEASE
        cell.imageView.image = [UIImage imageNamed:@"icon_reaction"];

    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedMessage = [self.messages objectAtIndex:indexPath.row];

    NSString *fileType = [self.selectedMessage objectForKey:@"fileType"];
    if ([fileType isEqualToString:@"image"]) {
        [self performSegueWithIdentifier:@"showImage" sender:self];
    } else {
        self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[SnapchatClient fileURLFromMessage:self.selectedMessage]];
        [self.moviePlayer prepareToPlay];
                [self.view addSubview:self.moviePlayer.view];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterFullScreen) name:MPMoviePlayerWillEnterFullscreenNotification object:self.moviePlayer];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willExitFullScreen) name:MPMoviePlayerDidExitFullscreenNotification object:self.moviePlayer];
        [self.moviePlayer setFullscreen:YES animated: YES];
    }

}

- (void)willEnterFullScreen {
    self.senderName = [self.selectedMessage objectForKey:@"senderName"];
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

- (void)willExitFullScreen {
    
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showLogin"]) {
        [segue.destinationViewController setHidesBottomBarWhenPushed:YES];
    } else if ([segue.identifier isEqualToString:@"showImage"]) {

        [segue.destinationViewController setHidesBottomBarWhenPushed:YES];
        ImageViewController *imageViewController = (ImageViewController*)segue.destinationViewController;
        imageViewController.message = self.selectedMessage;
    }
}

#pragma mark - Helper methods

- (void)retriveMessages
{
    __block InboxViewController *me = self;
    void (^block)(NSArray*, NSError*) = ^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Error: %@ %@", error, error.userInfo);
        } else {
            // Found messages!
            me.messages = objects;
            NSLog(@"Retrived %d messages", me.messages
                  .count);
            Delegate.myMessages = me.messages;
        }
        [[me tableView] reloadData];
        [self.refreshControl endRefreshing];
    };
    [SnapchatClient getMessagesForUser: nil withBlock: block];
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
    //[self sendResponse];
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
    if (!self.sentResponse)
        [self sendVideoResponse];
}

- (void)sendResponse
{
    [SnapchatClient sendSnap: [NSData dataWithContentsOfFile: self.path] withType:@"video" withRecipients:[NSArray arrayWithObject: self.senderName] fromUser:[SnapchatClient currentUser] withBlock:^(BOOL completed, NSError *error) {
        [DejalActivityView removeView];
    }];
}





@end
