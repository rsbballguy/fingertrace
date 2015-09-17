//
//  ViewController.m
//  fingertrace
//
//  Created by Rahul Sundararaman on 9/12/15.
//  Copyright (c) 2015 Rahul Sundararaman. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/highgui.hpp>
#import <opencv2/highgui/highgui.hpp>
#include <opencv2/video/background_segm.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/videoio.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/video.hpp>
#include <iostream>
#include <sstream>
#include <stdio.h>
#include <stdlib.h>
@interface ViewController ()

@end

@implementation ViewController
cv::Mat canny_output;
cv::Mat src;
cv::Mat src_gray;
cv::RNG rng(12345);
UIImage *tobesaved;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:_ImageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.rotateVideo = YES;
    [self.videoCamera start];
    _contourimg.transform = CGAffineTransformMakeRotation(M_PI);
    _ImageView.transform = CGAffineTransformMakeRotation((M_PI*3)/2);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)flip:(id)sender {
    [self.videoCamera switchCameras];
    }
- (IBAction)click:(id)sender {
    UIImageWriteToSavedPhotosAlbum(tobesaved, nil, nil, nil);

}
#pragma mark – Protocol CvVideoCameraDelegate

#ifdef __cplusplus
-(void)processImage:(cv::Mat &)image
{
    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    int thresh = 120-(floor(self.slider.value*100)+20);
    src = image;
    cvtColor( src, src_gray, CV_BGR2GRAY );
    blur( src_gray, src_gray, cvSize(3, 3));
    Canny( src_gray, canny_output, thresh, thresh*2, 3 );
    findContours( canny_output, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE);
    cv::Mat drawing = cv::Mat::zeros( canny_output.size(), CV_8UC3 );
    std::vector<std::vector<cv::Point> >hull( contours.size() );
    std::vector<cv::Vec4i>convexdef;
    for( int i = 0; i < contours.size(); i++ )
    {
         convexHull( cv::Mat(contours[i]), hull[i], false, true);
    }
    for( int i = 0; i< contours.size(); i++ )
    {
        cv::Scalar color = cvScalar( rng.uniform(0, 255), rng.uniform(0,255), rng.uniform(0,255) );
        drawContours( drawing, contours, i, color, CV_FILLED,  8, hierarchy);
    }
 
    UIImage *imag = [self UIImageFromCVMat:drawing];
    tobesaved = imag;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_contourimg setImage:imag];
    });
    
    
//    CvContourScanner thisscanner = cvStartFindContours(&image, connectedCompStorage);
//    cv::findContours( image, contours, hierarchy, cv::RETR_CCOMP, cv::CHAIN_APPROX_TC89_KCOS);
//    for ( size_t i=0; i<contours.size(); ++i )
//    {
//        cv::drawContours( image, contours, i, cvScalar(200,0,0), 1, 8, hierarchy, 0 );
//        cv::Rect brect = cv::boundingRect(contours[i]);
//        cv::rectangle(image, brect, cvScalar(255,0,0));
//    }
//    CGFloat red, green, blue, alpha;
//    for(int x = 0; x<thisimage.size.width; x++){
//        for(int y=0; y<thisimage.size.height; y++){
//            NSArray *thisarray = [self getRGBAsFromImage:thisimage atX:x andY:y count:1];
//            UIColor *redColor = thisarray[0];
//            [redColor getRed: &red green: &green blue: &blue alpha: &alpha];
//            
//        }
//    }
}
#endif
-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    if ( cvMat.elemSize() == 1 ) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    }
    else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData( (__bridge CFDataRef)data );
    CGImageRef imageRef = CGImageCreate( cvMat.cols, cvMat.rows, 8, 8 * cvMat.elemSize(), cvMat.step[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault );
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease( imageRef );
    CGDataProviderRelease( provider );
    CGColorSpaceRelease( colorSpace );
    return finalImage;
}
- (NSArray*)getRGBAsFromImage:(UIImage*)image atX:(int)x andY:(int)y count:(int)count
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    NSUInteger byteIndex = (bytesPerRow * y) + x * bytesPerPixel;
    for (int i = 0 ; i < count ; ++i)
    {
        CGFloat red   = (rawData[byteIndex]     * 1.0) / 255.0;
        CGFloat green = (rawData[byteIndex + 1] * 1.0) / 255.0;
        CGFloat blue  = (rawData[byteIndex + 2] * 1.0) / 255.0;
        CGFloat alpha = (rawData[byteIndex + 3] * 1.0) / 255.0;
        byteIndex += bytesPerPixel;
        
        UIColor *acolor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
        [result addObject:acolor];
    }
    
    free(rawData);
    
    return result;
}
@end
