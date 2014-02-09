//
//  SnapchatClient.m
//  Ribbit
//
//  Created by Jason Berlinsky on 2/8/14.
//  Copyright (c) 2014 Tord Åsnes. All rights reserved.
//

#import "SnapchatClient.h"

#define USE_PARSE 0

@implementation SnapchatClient

+ (void) initialize
{
    [Parse setApplicationId:@"hhQ7Zp9BbkFLhTiRop1JApYOrelvDsZbFklWIGaQ"
                  clientKey:@"iPSqpMe2JFR0P7uO8Iy9Q0Oqz6987Zmvb7elEXAl"];
}

#define kEndpoint @"http://ops.jasonberlinsky.com:5000"
//#define kEndpoint @"http://127.0.0.1:5000"

#define kUserDefaultUsernameKey @"snapchatusername"

#define kUserDefaultPasswordKey @"snapchatpassword"
#define kEndpointMessages [NSString stringWithFormat: @"%@/getall", kEndpoint]
#define kEndpointSend [NSString stringWithFormat: @"%@/send", kEndpoint]
#define kEndpointAllFriends [NSString stringWithFormat: @"%@/getfriends/all", kEndpoint]
#define kEndpointLogin [NSString stringWithFormat: @"%@/login", kEndpoint]

#define kUsernameParameterKey @"username"
#define kPasswordParameterKey @"password"
#define kRecipientParameterKey @"recipient"
#define kFileParameterKey @"file"

#define PublicImagesDirectory(filename) [NSString stringWithFormat: @"http://ops.jasonberlinsky.com/static/%@", filename]

+ (NSURL *) fileURLFromMessage:(SCMessage *) message
{
    return [NSURL URLWithString:PublicImagesDirectory([message objectForKey: @"file"])];
}

+ (NSInteger)countdownFromMessage:(SCMessage *) message
{
    return (int)[message objectForKey: @"time"];
}

+ (SCUser *) currentUser
{
    return (SCUser *)[PFUser currentUser];
}

+ (NSArray *) friendsForUser: (SCUser *)user
{
    return [self.currentUser relationforKey:@"friendsRelation"];
}

+ (void)getAllUsersWithBlock: (void (^)(NSArray*, NSError*))block
{
    PFQuery *query = [PFUser query];
    [query orderByAscending:@"username"];
    [query findObjectsInBackgroundWithBlock:block];
}

+ (void)getMyFriendsWithBlock: (void (^)(NSArray*, NSError*))block
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:kEndpointAllFriends parameters: [self loginParameters] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Response: %@", responseObject);
//        [DejalActivityView removeView];
        block(responseObject, nil);
    } failure: ^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];

}


+ (void)sendSnap:(NSData *)fileData withType:(NSString *)fileType withRecipients:(NSMutableArray *)recipients fromUser:(SCUser *)currentUser withBlock: (void (^)(BOOL, NSError*))block
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    //manager.responseSerializer = [AFHTTPRequestSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"%@/%@", kEndpointSend, fileType] parameters: [self loginParametersWithRecipients:recipients] constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:fileData name:@"file" fileName:@"uploaded_file.png" mimeType:@"image/png"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        block(true, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        block(false, error);
    }];
}

     + (NSDictionary *)loginParametersWithRecipients:(NSArray *)recipientName
    {
        NSMutableDictionary *params = [self loginParameters];
        [params setObject: [recipientName componentsJoinedByString:@","] forKey: kRecipientParameterKey];
        NSLog(@"Sending parameters %@", params);
        return params;
    }
     
+ (NSDictionary *)loginParametersWithRecipients:(NSArray *)recipientName dataUpload:(NSString *)blob
{
    NSMutableDictionary *params = [self loginParameters];
    [params setObject: [recipientName componentsJoinedByString:@","] forKey: kRecipientParameterKey];
    [params setObject: blob forKey: kFileParameterKey];
    NSLog(@"Sending parameters %@", params);
    return params;
}


+ (void)logInWithUsername: (NSString *)username password: (NSString *)password block: (void (^)(PFUser*, NSError*))block
{
    // Attempt the connection
    [[NSUserDefaults standardUserDefaults] setObject: username forKey: kUserDefaultUsernameKey];
    [[NSUserDefaults standardUserDefaults] setObject: password forKey: kUserDefaultPasswordKey];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST: kEndpointLogin parameters: [self loginParameters] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Response: %@", responseObject);
        [DejalActivityView removeView];
        
        //if ([[responseObject objectForKey:@"success"] isEqualToString: @"No"])
            block(responseObject, nil);
        //else
        //    block(nil, [NSError errorWithDomain: @"Authentication failure" code: 2  userInfo: nil]);
    } failure: ^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        block(nil, [NSError errorWithDomain: @"Authentication failure" code: 1 userInfo: nil]);
    }];
};

+ (NSMutableDictionary *)loginParameters
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey: kUserDefaultUsernameKey], kUsernameParameterKey,
            (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey: kUserDefaultPasswordKey ], kPasswordParameterKey,
            nil];
}

+ (NSString *)storedUsername
{
    return (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey: kUserDefaultUsernameKey];
}

+ (NSString *)storedPassword
{
    return (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey: kUserDefaultPasswordKey ];
}

+ (void)getMessagesForUser: (SCUser *)currentUser withBlock: (void (^)(NSArray*, NSError*))block
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:kEndpointMessages parameters: [self loginParameters] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [DejalActivityView removeView];
        block(responseObject, nil);
    } failure: ^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
//    [DejalActivityView activityViewForView:self.view];
}

+ (void)saveFileWithName: (NSString *)fileName data: (NSData *)fileData block: (void (^)(BOOL, NSError*))block caller: (CameraViewController *)caller
{
    caller.file = [SCFile fileWithName:fileName data:fileData];
    [caller.file saveInBackgroundWithBlock:block];
}

@end
