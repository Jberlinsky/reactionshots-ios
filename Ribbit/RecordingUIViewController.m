//
//  RecordingUIViewController.m
//  Ribbit
//
//  Created by Jason Berlinsky on 2/9/14.
//  Copyright (c) 2014 Tord Åsnes. All rights reserved.
//

#import "RecordingUIViewController.h"

@interface RecordingUIViewController ()

@end

@implementation RecordingUIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)sendResponse
{
    [SnapchatClient sendSnap: [NSData dataWithContentsOfFile: self.path] withType:@"video" withRecipients:[NSArray arrayWithObject: self.senderName] fromUser:[SnapchatClient currentUser] withBlock:^(BOOL completed, NSError *error) {
        [DejalActivityView removeView];
    }];
}

@end
