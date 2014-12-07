//
//  UIView+Helpers.m
//  WelpyApp
//
//  Created by Администратор on 8/6/14.
//  Copyright (c) 2014 Welpy Inc. All rights reserved.
//

#import "UIView+Helpers.h"

@implementation UIView (Helpers)

-(float)left
{
    return self.frame.origin.x;
}

-(float)top
{
    return self.frame.origin.y;
}

-(float)right
{
    return self.left + self.width;
}

-(float)bottom
{
    return self.top + self.height;
}

-(float)width
{
    return self.frame.size.width;
}

-(float)height
{
    return self.frame.size.height;
}

-(void)setLeft:(float)left
{
    CGRect frame = self.frame;
    frame.origin.x = left;
    self.frame = frame;
}

-(void)setTop:(float)top
{
    CGRect frame = self.frame;
    frame.origin.y = top;
    self.frame = frame;
}

-(void)setRight:(float)right
{
    self.left = right - self.width;
}

-(void)setBottom:(float)bottom
{
    self.top = bottom - self.height;
}

-(void)setWidth:(float)width
{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

-(void)setHeight:(float)height
{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

-(void)addFrame:(CGRect)rect
{
    CGRect frame = self.frame;
    frame.origin.x += rect.origin.x;
    frame.origin.y += rect.origin.y;
    frame.size.width += rect.size.width;
    frame.size.height += rect.size.height;
    self.frame = frame;
}

-(void) shakeItWithDelta:(CGFloat)delta
{
    CAKeyframeAnimation *anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ];
    anim.values = [ NSArray arrayWithObjects:
                   [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(delta, 0.0f, 0.0f) ],
                   [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-delta, 0.0f, 0.0f) ],
                   nil ] ;
    anim.autoreverses = YES ;
    anim.repeatCount = 3.0f ;
    anim.duration = 0.07f ;
    
    [self.layer addAnimation:anim forKey:nil ];
}

@end
