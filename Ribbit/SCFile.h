//
//  SCFile.h
//  Ribbit
//
//  Created by Jason Berlinsky on 2/8/14.
//  Copyright (c) 2014 Tord Åsnes. All rights reserved.
//

#import <Parse/Parse.h>

@interface SCFile : PFFile

- (void) saveInBackgroundWithBlock:(void (^)(BOOL, NSError*))block;
- (NSURL *)url;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSData *data;

@end
