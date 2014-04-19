//
//  CameraViewController.m
//  Ribbit
//
//  Created by Tord Åsnes on 04/11/13.
//  Copyright (c) 2013 Tord Åsnes. All rights reserved.
//

#import "CameraViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "MSCellAccessory.h"

@interface CameraViewController ()

@end

@implementation CameraViewController


UIColor *disclosureColor;


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.recipients = [[NSMutableArray alloc] init];
    
    disclosureColor = [UIColor colorWithRed:0.553 green:0.439 blue:0.718 alpha:1.0];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(retriveFriends) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    self.friends = [delegate myFriends];
    
    if (self.image == nil && self.videoFilePath.length == 0) {
        self.imagePicker = [[UIImagePickerController alloc] init];
        self.imagePicker.delegate = self;
        
        self.imagePicker.allowsEditing = NO;
        self.imagePicker.videoMaximumDuration = 5;
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            
        } else {
            self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        self.imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:self.imagePicker.sourceType];
        [self presentViewController:self.imagePicker animated:NO completion:Nil];
    
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
    return self.friends.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    SCUser *user = [SCUser initWithDictionary: [self.friends objectAtIndex:indexPath.row]];
    cell.textLabel.text = [user displayName];
    
    if ([self.recipients containsObject:user.objectId]) {
        cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_CHECKMARK color:disclosureColor];
    } else {
        cell.accessoryView = nil;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    SCUser *user = [SCUser initWithDictionary: [self.friends objectAtIndex:indexPath.row]];
    
    if (cell.accessoryView == nil) {
        cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_CHECKMARK color:disclosureColor];
        [self.recipients addObject:user.username];
        
    } else {
        cell.accessoryView = nil;
        [self.recipients removeObject:user.objectId];
    }
}

#pragma mark - ImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:NO completion:nil];
    
    [self.tabBarController setSelectedIndex:0];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString*)kUTTypeImage]) {
        // Photo was taken or selected
        self.image = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (self.imagePicker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            // Save image
            UIImageWriteToSavedPhotosAlbum(self.image, nil, nil, nil);
        }
    } else {
        // Video selected or taken
        self.videoFilePath = (__bridge NSString *)([[info objectForKey:UIImagePickerControllerMediaURL] path]);
        if (self.imagePicker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            // Save video
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(self.videoFilePath)) {
                UISaveVideoAtPathToSavedPhotosAlbum(self.videoFilePath, nil, Nil, nil);
            }
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - IBActions

- (IBAction)cancel:(id)sender {
    [self reset];
    [self.tabBarController setSelectedIndex:0];
}



- (IBAction)send:(id)sender {
    
    if (self.image == nil && self.videoFilePath.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Try agin!"
                                                        message:@"Please capture or selecte a photo or a video to share!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        [self presentViewController:self.imagePicker animated:NO completion:nil];
    } else {
        [self uploadeMessage];
        [self.tabBarController setSelectedIndex:0];
    }
    
}

#pragma mark - Helper methods

- (void)uploadeMessage
{
    NSData *fileData;
    NSString *fileName;
    NSString *fileType;
    
    if (self.image != nil) {
        UIImage *newImage = [self resizeImage:self.image toWidth:320.0f height:480.0f];
        
        fileData = UIImagePNGRepresentation(newImage);
        fileName = @"image.png";
        fileType = @"image";
    } else {
        fileData = [NSData dataWithContentsOfFile:self.videoFilePath];
        fileName = @"video.mov";
        fileType = @"movie";
    }
    
    __block CameraViewController *me = self;
            void (^block)(BOOL, NSError*) = ^(BOOL success, NSError *error) {
                if (error) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error occured!"
                                                                    message:@"Please try sending your message again!" delegate:me cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [alert show];
                } else {
                    // Everything went better than expected
                    [me reset];
                }
            };
    
    [SnapchatClient sendSnap: fileData withType: fileType withRecipients: self.recipients fromUser: [SnapchatClient currentUser] withBlock: block];
}

- (void)reset {
    self.image = nil;
    self.videoFilePath = nil;
    [self.recipients removeAllObjects];
}

- (UIImage*)resizeImage:(UIImage *)image toWidth:(float)width height:(float)height
{
    CGSize newSize = CGSizeMake(width, height);
    CGRect newRectangle = CGRectMake(0, 0, width, height);
    UIGraphicsBeginImageContext(newSize);
    [self.image drawInRect:newRectangle];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

- (void)retriveFriends
{
    __block CameraViewController *me = self;
    void (^block)(NSArray*, NSError*) = ^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Error: %@ %@", error, error.userInfo);
        } else {
            // Found messages!
            me.friends = objects;
            NSLog(@"Retrived %d messages", me.friends
                  .count);
            Delegate.myFriends = me.friends;
        }
        [[me tableView] reloadData];
        [self.refreshControl endRefreshing];
    };
    [SnapchatClient getMyFriendsWithBlock: block];
}






@end
