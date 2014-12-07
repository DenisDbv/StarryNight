//
//  UIView+Helpers.h
//  WelpyApp
//
//  Created by Администратор on 8/6/14.
//  Copyright (c) 2014 Welpy Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Helpers)

@property (nonatomic) float left;
@property (nonatomic) float top;
@property (nonatomic) float right;
@property (nonatomic) float bottom;

@property (nonatomic) float width;
@property (nonatomic) float height;

-(void)addFrame:(CGRect)rect;

-(void)scaleOut;

-(void)applyGradientMaskStartAlpha:(float)startAlpha endAlpha:(float)endAlpha
                             startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint;

-(void) shakeItWithDelta:(CGFloat)delta;

@end
