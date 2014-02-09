//
//  SnapchatClient.h
//  Ribbit
//
//  Created by Jason Berlinsky on 2/8/14.
//  Copyright (c) 2014 Tord Åsnes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "SCUser.h"
#import "SCMessage.h"
#import "SCFile.h"
#import "CameraViewController.h"
#include "DejalActivityView.h"



#import <AFNetworking/AFHTTPRequestOperationManager.h>


#define GET_ALL_USERS_IN_UITABLEVIEW(currentClass) \
__block currentClass *me = self; \
void (^block)(NSArray*, NSError*) = ^(NSArray *objects, NSError *error) { \
if(error){ \
NSLog(@"Error: %@ %@", error, error.userInfo); \
} else { \
me.allUsers = objects; \
[me.tableView reloadData]; \
} \
}; \
[SnapchatClient getAllUsersWithBlock:block];

@interface SnapchatClient : NSObject

+ (NSURL *) fileURLFromMessage:(SCMessage *) message;
+ (NSInteger)countdownFromMessage:(SCMessage *) message;
+ (SCUser *) currentUser;
+ (NSArray *) friendsForUser: (SCUser *)user;
+ (void)getAllUsersWithBlock: (void (^)(NSArray*, NSError*))block;
+ (void)getMyFriendsWithBlock: (void (^)(NSArray*, NSError*))block;
+ (void)sendSnap:(NSData *)fileData withType:(NSString *)fileType withRecipients:(NSMutableArray *)recipients fromUser:(SCUser *)currentUser withBlock: (void (^)(BOOL, NSError*))block;
+ (void)logInWithUsername: (NSString *)username password: (NSString *)password block: (void (^)(PFUser*, NSError*))block;
+ (void)getMessagesForUser: (SCUser *)currentUser withBlock: (void (^)(NSArray*, NSError*))block;
+ (void)saveFileWithName: (NSString *)fileName data: (NSData *)fileData block: (void (^)(BOOL, NSError*))block caller:(CameraViewController *)caller;
+ (NSURL *) fileURLFromFile:(SCFile *)file;

+ (NSString *)storedUsername;
+ (NSString *)storedPassword;

+ (NSDictionary *)loginParametersWithRecipients:(NSArray *)recipientName dataUpload:(NSString *)blob;
+ (NSMutableDictionary *)loginParameters;
@end
