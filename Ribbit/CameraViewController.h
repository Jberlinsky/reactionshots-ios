//
//  CameraViewController.h
//  Ribbit
//
//  Created by Tord Åsnes on 04/11/13.
//  Copyright (c) 2013 Tord Åsnes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CameraViewController : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *videoFilePath;

@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) NSMutableArray *recipients;

@property (nonatomic, retain) SCFile *file;

- (IBAction)cancel:(id)sender;
- (IBAction)send:(id)sender;

- (void)uploadeMessage;
- (UIImage*)resizeImage:(UIImage*)image toWidth:(float)width height:(float)height;
@end
