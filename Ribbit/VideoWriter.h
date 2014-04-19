//
//  VideoWriter.h
//  Ribbit
//
//  Created by Jason Berlinsky on 2/9/14.
//  Copyright (c) 2014 Tord Åsnes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SnapchatClient.h"
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoWriter : NSObject

+ (void)writeImagesAsMovie:(NSArray *)array toPath:(NSString*)path;
@end
