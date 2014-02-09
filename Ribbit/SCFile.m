//
//  SCFile.m
//  Ribbit
//
//  Created by Jason Berlinsky on 2/8/14.
//  Copyright (c) 2014 Tord Åsnes. All rights reserved.
//

#import "SCFile.h"

@implementation SCFile

@synthesize name, data;

+ (SCFile *) fileWithName: (NSString *)fileName data: (NSData *)fileData
{
    SCFile *file = [SCFile alloc];
    file.name = fileName;
    file.data = fileData;
    return file;
}

- (void) saveInBackgroundWithBlock:(void (^)(BOOL, NSError*))block
{
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *targetFile = [documentsDirectory stringByAppendingPathComponent:self.name];
    if ([self.data writeToFile:targetFile atomically:YES]) {
        block(true, nil);
    } else {
        block(false, error);
    }
}

- (NSURL *)url
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *targetFile = [documentsDirectory stringByAppendingPathComponent:self.name];
    return [NSURL URLWithString:targetFile];
}

@end
