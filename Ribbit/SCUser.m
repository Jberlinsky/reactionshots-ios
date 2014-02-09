//
//  SCUser.m
//  Ribbit
//
//  Created by Jason Berlinsky on 2/8/14.
//  Copyright (c) 2014 Tord Åsnes. All rights reserved.
//

#import "SCUser.h"

@implementation SCUser

@synthesize backing;

- (NSString *)displayName
{
    
    NSString *display = [backing objectForKey: @"display"];
    if ([display isEqualToString: @""] || display == NULL)
        display = [backing objectForKey: @"name"];
    return display;
}

- (NSString *)username
{
    return [backing objectForKey: @"name"];
}

- (NSString *)objectId
{
    return [backing objectForKey: @"ts"];
}

+ (SCUser *)initWithDictionary:(NSDictionary *)dict
{
    SCUser *newUser = [SCUser alloc];
    newUser.backing = dict;
    return newUser;
}

@end
