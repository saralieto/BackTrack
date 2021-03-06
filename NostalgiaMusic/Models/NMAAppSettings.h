//
//  NMAAppSettings.h
//  NostalgiaMusic
//
//  Created by Eric Peterson on 6/23/15.
//  Copyright (c) 2015 Intrepid Pursuits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface NMAAppSettings : NSObject

+ (instancetype)sharedSettings;

- (BOOL)userHasCompletedOnboarding;
- (void)setUserOnboardingStatusToCompleted;
- (void)setAccessToken:(FBSDKAccessToken *)token;
- (NSString *)accessTokenString;
- (BOOL)userIsLoggedIn;
- (BOOL)userDidAutoplay;
- (void)setAutoplaySettingToOff;
- (void)setAutoplaySettingToOn;

@end
