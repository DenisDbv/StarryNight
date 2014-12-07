//
//  SkyViewController.m
//  StarryNight
//
//  Created by Denis Dubov on 25.11.14.
//  Copyright (c) 2014 brandmill. All rights reserved.
//

#import "SkyViewController.h"
#import "UIView+Helpers.h"
#import "NSDate+Calendar.h"
#import <CoreLocation/CoreLocation.h>

// This is defined in Math.h
#define M_PI   3.14159265358979323846264338327950288   /* pi */
// Our conversion definition
#define DEGREES_TO_RADIANS(angle) (angle / 180.0 * M_PI)

@interface SkyViewController ()
@property (nonatomic) NSInteger width,height;
@property (nonatomic, strong) UIView *starryView;
@property (nonatomic) NSInteger count;

@property (nonatomic, strong) UIImageView *startImageView;
@property (nonatomic, strong) UIImageView *progressImageView;
@property (nonatomic, strong) UIImage *starryImage;
@property (nonatomic, strong) UIImage *image1;
@property (nonatomic, strong) UIImage *image2;
@property (weak, nonatomic) IBOutlet UIButton *endButton;
@end

@implementation SkyViewController   {
    NSTimer *timer;
    
    CGFloat azimuth, altitude, hfov;
    double lat, lng;
    NSDate *date;
    
    double dayMs;
    double J1970;
    double J2000;
    
    UIImageView *imgView3;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *_date = [userDefaults valueForKey:@"DATE"];
    double _lat = [[userDefaults valueForKey:@"PLACE_LAT"] doubleValue];
    double _lot = [[userDefaults valueForKey:@"PLACE_LONG"] doubleValue];
    
    NSArray *strings = [_date componentsSeparatedByString:@"."];
    
    azimuth = M_PI;
    altitude = 0.7;
    hfov = 1.2;
    lat = _lat;
    lng = _lot;
    date = [NSDate dateWithYear:[strings[2] integerValue] month:[strings[1] integerValue] day:[strings[0] integerValue]];
    
    //NSLog(@"DATE: %@.%@.%@", strings[0], strings[1], strings[2]);
    //NSLog(@"LAT:%f LONG:%f", _lat, _lot);
    
    dayMs = 1000 * 60 * 60 * 24;
    J1970 = 2440588;
    J2000 = 2451545;
    
    self.count = 1000;
    self.width = self.view.frame.size.width;
    self.height = self.view.frame.size.height;
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    [self update];
    self.image1 = [self mask:[UIImage imageNamed:@"mask-1"] withTexture:self.starryImage];
    self.image2 = [self mask:[UIImage imageNamed:@"mask-2"] withTexture:self.starryImage];
    
    self.starryView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.starryView setFrame:self.view.frame];
    [self.view addSubview:self.starryView];
    
    self.progressImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"progress-circle"]];
    self.progressImageView.center = self.view.center;
    [self.view addSubview:self.progressImageView];
    [self runSpinAnimationOnView:self.progressImageView duration:0.1 rotations:1 repeat:CGFLOAT_MAX];
    
    self.startImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
    [self.view addSubview:self.startImageView];
    
    [self.view insertSubview:self.endButton aboveSubview:self.starryView];
    
    /*UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [panGesture setDelegate:self];
    [panGesture setMaximumNumberOfTouches:1];
    [self.starryView addGestureRecognizer:panGesture];*/
}

- (void)handlePan:(UIPanGestureRecognizer*)recognizer {
    
    CGPoint translation = [recognizer translationInView:recognizer.view];
    
    NSLog(@"%@", NSStringFromCGPoint(translation));
    
    azimuth += translation.x / 1000;
    altitude += translation.y / 1000;
    
    [self initRender];
    imgView3.image = self.starryImage;
}

-(void) viewDidAppear:(BOOL)animated    {
    [UIView animateWithDuration:0.5 animations:^{
        self.startImageView.alpha = 0;
    }];
    timer = [NSTimer scheduledTimerWithTimeInterval:1
                                             target:self
                                           selector:@selector(onTimer)
                                           userInfo:nil
                                            repeats:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) onTimer {
    UIImageView *imgView1 = [[UIImageView alloc] initWithImage:self.image1];
    UIImageView *imgView2 = [[UIImageView alloc] initWithImage:self.image2];
    imgView3 = [[UIImageView alloc] initWithImage:self.starryImage];
    imgView1.frame = self.starryView.frame;
    imgView2.frame = self.starryView.frame;
    imgView3.frame = self.starryView.frame;
    imgView1.alpha = 0;
    imgView2.alpha = 0;
    imgView3.alpha = 0;
    [self.starryView addSubview:imgView1];
    [self.starryView addSubview:imgView2];
    [self.starryView addSubview:imgView3];
    
    UIImageView *leftBorderImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"left-border"]];
    UIImageView *rightBorderImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"right-border"]];
    leftBorderImageView.right = 0;
    rightBorderImageView.left = self.view.frame.size.width;
    [self.starryView addSubview:leftBorderImageView];
    [self.starryView addSubview:rightBorderImageView];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *_name = [userDefaults valueForKey:@"NAME"];
    NSString *_date = [userDefaults valueForKey:@"DATE"];
    NSString *_place = [userDefaults valueForKey:@"PLACE"];
    
    UILabel *titleLabel = [UILabel new];
    titleLabel.font = [UIFont fontWithName:@"Opium" size:26.0];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.text = [NSString stringWithFormat:@"%@\n%@\n%@", _date, _place, _name];
    titleLabel.numberOfLines = 0;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [titleLabel sizeToFit];
    [self.starryView addSubview:titleLabel];
    titleLabel.center = self.starryView.center;
    titleLabel.bottom = 0;
    
    [UIView animateWithDuration:0.2 animations:^{
        imgView1.alpha = 1;
        [UIView animateWithDuration:0.2 delay:0.4 options:UIViewAnimationOptionTransitionNone animations:^{
            imgView2.alpha = 1;
            [UIView animateWithDuration:0.2 delay:0.8 options:UIViewAnimationOptionTransitionNone animations:^{
                imgView3.alpha = 1;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionTransitionNone animations:^{
                    self.progressImageView.alpha = 0;
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionTransitionNone animations:^{
                        leftBorderImageView.left = 0;
                        rightBorderImageView.right = self.view.frame.size.width;
                        titleLabel.top = 20;
                    } completion:^(BOOL finished) {
                        [NSTimer scheduledTimerWithTimeInterval:0.5
                                                         target:self
                                                       selector:@selector(onTimer2)
                                                       userInfo:nil
                                                        repeats:NO];
                    }];
                }];
            }];
        } completion:^(BOOL finished) {
            //
        }];
    }];
}

-(void) onTimer2 {
    [UIView animateWithDuration:0.3 animations:^{
        self.endButton.alpha = 1.0;
    }];
}

-(UIImage*) mask:(UIImage*)maskImage withTexture:(UIImage*)textureImage    {
    
    UIImage *resultImage;
    CGRect backgroundRect = CGRectMake(0, 0, textureImage.size.width, textureImage.size.height);
    
    UIGraphicsBeginImageContextWithOptions(textureImage.size, NO, 2.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, textureImage.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextClipToMask(context, backgroundRect, textureImage.CGImage);
    CGContextDrawImage(context, backgroundRect, maskImage.CGImage);
    resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImage;
}

- (void) runSpinAnimationOnView:(UIView*)view duration:(CGFloat)duration rotations:(CGFloat)rotations repeat:(float)repeat;
{
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * rotations * duration ];
    rotationAnimation.duration = duration;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = repeat;
    
    [view.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)update  {
    [self initRender];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (IBAction)onEndButton:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

-(void) initRender  {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"750" ofType:@"json"];
    NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingMutableContainers error:nil];
    NSArray *stars = [jsonObject valueForKey:@"stars"];
    NSLog(@"Count of stars: %i", stars.count);
    
    if(altitude > 1.5) {
        altitude = 1.5;
    } else if(altitude < 0) {
        altitude = 0;
    }
    if(hfov > 1.2) {
        hfov = 1.2;
    } else if(hfov < 0.6) {
        hfov = 0.6;
    }
    
    // Calculate current star sky positions
    NSMutableArray *currentStars = [NSMutableArray new];
    for(NSDictionary *star in stars)    {
        NSDictionary *temp = [self getStarPosition:date :lat :lng :star];
        [currentStars addObject:temp];
    }
    
    CGFloat lastX = 0.0, lastY = 0;
    NSMutableArray *screenStars = [NSMutableArray new];
    for(NSDictionary *star in currentStars)    {
        double starAltitude = [[star valueForKey:@"altitude"] doubleValue];
        double starAzimuth = [[star valueForKey:@"azimuth"] doubleValue];
        double starVmag = [[star valueForKey:@"vmag"] doubleValue];
        NSString *starName = [star valueForKey:@"name"];
        NSString *starPname = [star valueForKey:@"pname"];
        double starDist = [[star valueForKey:@"dist"] doubleValue];
        
        CGFloat z = sin(starAltitude) * sin(altitude)
        + cos(starAltitude) * cos(starAzimuth + azimuth)
        * cos(altitude);
        
        if((((starAzimuth <= (M_PI / 2) && starAzimuth > -(M_PI / 2) && z >= 0)) ||
            (((starAzimuth > (M_PI / 2) || starAzimuth <= -(M_PI / 2)) && z >= 0)))
           && starAltitude > 0) {
            
            NSMutableDictionary *s = [NSMutableDictionary new];
            
            double sY = -self.view.height / tan(hfov / 2) * (sin(starAltitude) * cos(altitude) - cos(starAltitude) * cos(starAzimuth + azimuth) * sin(altitude)) / z / 2 + self.view.height / 2;
            double sX = self.view.width - (-self.view.height / tan(hfov / 2) * sin(starAzimuth + azimuth) * cos(starAltitude) / z / 2 + self.view.width / 2);
            double sVmag = [[star valueForKey:@"vmag"] doubleValue];
            NSString *sName = [star valueForKey:@"name"];
            NSString *sPname = [star valueForKey:@"pname"];
            double sDist = [[star valueForKey:@"dist"] doubleValue];
            
            [s setObject:[NSNumber numberWithDouble:sY] forKey:@"y"];
            [s setObject:[NSNumber numberWithDouble:sX] forKey:@"x"];
            [s setObject:[NSNumber numberWithDouble:sVmag] forKey:@"vmag"];
            [s setObject:sName forKey:@"name"];
            [s setObject:sPname forKey:@"pname"];
            [s setObject:[NSNumber numberWithDouble:sDist] forKey:@"dist"];
            
            if(sX > lastX)
                lastX = sX;
            if(sY > lastY)
                lastY = sY;
            
            if (sX > 0 && sX < self.view.width && sY > 0 && sY < self.view.height) {
                [screenStars addObject:s];
            }
        }
    }
    
    NSLog(@"==> %f %f", lastX, lastY);
    
    NSLog(@"Count of screenStars: %i", screenStars.count);
    
    if(UIGraphicsBeginImageContextWithOptions != NULL)
    {
        UIGraphicsBeginImageContextWithOptions(self.view.frame.size, NO, 2.0);
    } else {
        UIGraphicsBeginImageContext(self.view.frame.size);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    for (NSInteger i = 0; i < self.count/2; i++) {
        CGContextSetRGBFillColor(context, (arc4random()%255)/1.0f, (arc4random()%255)/1.0f, (arc4random()%255)/1.0f, (arc4random()%100)/100.0f);
        CGContextFillRect(context, CGRectMake(arc4random()%self.width,arc4random()%self.height,1.f,1.f));
        UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(arc4random()%self.width,arc4random()%self.height,1.f,1.f)];
        [[UIColor colorWithRed:(arc4random()%255)/1.0f green:(arc4random()%255)/1.0f blue:(arc4random()%255)/1.0f alpha:(arc4random()%100)/100.0f] setFill];
        [ovalPath fill];
    }
    
    for (NSDictionary *screenStar in screenStars) {
        double _x = [[screenStar valueForKey:@"x"] doubleValue];
        double _y = [[screenStar valueForKey:@"y"] doubleValue];
        double _vmag = [[screenStar valueForKey:@"vmag"] doubleValue];
        
        _vmag = pow(1.5, -_vmag) * 4.5;
        
        CGRect borderRect = CGRectMake(_x, _y, _vmag, _vmag);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
        CGContextSetRGBFillColor(context, (255)/1.0f, (255)/1.0f, (255)/1.0f, (100)/100.0f);
        CGContextSetLineWidth(context, 1.0);
        CGContextFillEllipseInRect (context, borderRect);
        CGContextStrokeEllipseInRect(context, borderRect);
        CGContextFillPath(context);
        
        //CGContextSetRGBFillColor(context, (255)/1.0f, (255)/1.0f, (255)/1.0f, (100)/100.0f);
        //CGContextFillRect(context, CGRectMake(_x, _y, 1.f, 1.f));
    }
    self.starryImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

-(CGFloat) toJulian:(NSDate*)date2 {
    return [date2 timeIntervalSince1970] / dayMs - 0.5 + J1970;
}
-(CGFloat) toDays:(NSDate*)date2 {
    return [self toJulian:date2] - J2000;
}

// general calculations for position

-(CGFloat) getAzimuth:(double)H :(double)phi :(double)dec {
    return atan2(sin(H), cos(H) * sin(phi) - tan(dec) * cos(phi));
}

-(CGFloat) getAltitude:(double)H :(double)phi :(double)dec {
    return asin(sin(phi) * sin(dec) + cos(phi) * cos(dec) * cos(H));
}

-(CGFloat) getSiderealTime:(double)d :(double)lw {
    return (M_PI/180.0) * (280.16 + 360.9856235 * d) - lw;
}

-(NSDictionary*) getStarPosition:(NSDate*)date2 :(CGFloat)lat2 :(CGFloat)lng2 :(NSDictionary*)star  {
    double lw  = (M_PI/180.0) * -lng2;
    double phi = (M_PI/180.0) * lat2;
    double d   = [self toDays:date2];
    
    double cRa = [[star valueForKey:@"ra"] doubleValue];
    double cDec = [[star valueForKey:@"dec"] doubleValue];
    double cVmag = [[star valueForKey:@"vmag"] doubleValue];
    NSString *cName = [star valueForKey:@"name"];
    NSString *cPname = [star valueForKey:@"pname"];
    double cDist = [[star valueForKey:@"dist"] doubleValue];
    
    double H = [self getSiderealTime:d :lw] - cRa / 12 * M_PI;
    double h = [self getAltitude:H :phi :cDec/ 180 * M_PI];
    h = h + (M_PI/180.0) * 0.017 / tan(h + (M_PI/180.0) * 10.26 / (h + (M_PI/180.0) * 5.10));
    
    NSMutableDictionary *result = [NSMutableDictionary new];
    [result setObject:[NSNumber numberWithDouble:[self getAzimuth:H :phi :cDec / 180 * M_PI]] forKey:@"azimuth"];
    [result setObject:[NSNumber numberWithDouble:h] forKey:@"altitude"];
    [result setObject:[NSNumber numberWithDouble:cVmag] forKey:@"vmag"];
    [result setObject:cName forKey:@"name"];
    [result setObject:cPname forKey:@"pname"];
    [result setObject:[NSNumber numberWithDouble:cDist] forKey:@"dist"];
    
    return result;
}

@end
