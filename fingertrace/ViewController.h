//
//  ViewController.h
//  fingertrace
//
//  Created by Rahul Sundararaman on 9/12/15.
//  Copyright (c) 2015 Rahul Sundararaman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/videoio/cap_ios.h>
#include <opencv2/opencv.hpp>

@interface ViewController : UIViewController <CvVideoCameraDelegate>
@property (strong, nonatomic) IBOutlet UIImageView *ImageView;
@property (nonatomic, retain) CvVideoCamera* videoCamera;
@property (strong, nonatomic) IBOutlet UIImageView *contourimg;
-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;
-(NSArray*)getRGBAsFromImage:(UIImage*)image atX:(int)x andY:(int)y count:(int)count;
@end

