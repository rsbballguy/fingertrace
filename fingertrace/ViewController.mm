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
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Hello!" message:@"Welcome to OpenCV" delegate:self cancelButtonTitle:@"Continue" otherButtonTitles:nil];
//    [alert show];
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:_ImageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.rotateVideo = NO;
//    self.videoCamera.grayscale = NO;
    [self.videoCamera start];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark – Protocol CvVideoCameraDelegate

#ifdef __cplusplus
-(void)processImage:(cv::Mat &)image
{
    // Do some OpenCV stuff with the image
//    cv::Mat image_copy;
//    cvtColor(image, image_copy, CV_BGRA2BGR);
//    bitwise_not(image_copy, image_copy);
//    cvtColor(image_copy, image, CV_BGR2BGRA);
    UIImage *thisimage = [self UIImageFromCVMat:image];
    CvMemStorage *connectedCompStorage = cvCreateMemStorage (0);
    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    IplImage tmp = image;
    cvStartFindContours(&tmp, connectedCompStorage);
    cv::findContours( image, contours, hierarchy, cv::RETR_CCOMP, cv::CHAIN_APPROX_TC89_KCOS);
    for ( size_t i=0; i<contours.size(); ++i )
    {
        cv::drawContours( image, contours, i, cvScalar(200,0,0), 1, 8, hierarchy, 0 );
        cv::Rect brect = cv::boundingRect(contours[i]);
        cv::rectangle(image, brect, cvScalar(255,0,0));
    }
    CGFloat red, green, blue, alpha;
    for(int x = 0; x<thisimage.size.width; x++){
        for(int y=0; y<thisimage.size.height; y++){
            NSArray *thisarray = [self getRGBAsFromImage:thisimage atX:x andY:y count:1];
            UIColor *redColor = thisarray[0];
            [redColor getRed: &red green: &green blue: &blue alpha: &alpha];
            
        }
    }
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
    
    // First get the image into your data buffer
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
    
    // Now your rawData contains the image data in the RGBA8888 pixel format.
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
