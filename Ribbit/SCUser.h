//
//  SCUser.h
//  Ribbit
//
//  Created by Jason Berlinsky on 2/8/14.
//  Copyright (c) 2014 Tord Åsnes. All rights reserved.
//

#import <Parse/Parse.h>

@interface SCUser : PFUser

+ (SCUser *)initWithDictionary:(NSDictionary *)dict;
- (NSString *)displayName;
- (NSString *)objectId;
- (NSString *)username;

@property (nonatomic, retain) NSDictionary *backing;

@end
