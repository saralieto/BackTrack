//
//  NMARequestManager.m
//  NostalgiaMusic
//
//  Created by Amy Ly on 7/1/15.
//  Copyright (c) 2015 Intrepid Pursuits. All rights reserved.
//

#import "NMARequestManager.h"
#import "NMADatabaseManager.h"
#import <AFNetworking/AFNetworking.h>
#import "NMANewsStory.h"
#import "FBSDKGraphRequest.h"

@implementation NMARequestManager

+ (instancetype)sharedManager {
    static id sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[NMARequestManager alloc] init];
    });
    return sharedManager;
}

- (void)getSongFromYear:(NSString *)year
                         success:(void (^)(NMASong *song))success
                         failure:(void (^)(NSError *error))failure {
    NMASong *song = [[NMADatabaseManager sharedDatabaseManager] getSongFromYear:year];
    
    if (song) {
        if (success) {
            [self getiTunesMusicForSong:song
                                success:success
                                failure:^(NSError *error) {
                                    NSLog(@"can't find song on itunes"); //TODO: handle error
                                }];
        }
    } else {
        if (failure) {
            NSError *error = [[NSError alloc] init];
            failure(error); //TODO: handle error
        }
    }
}

- (void)getNewYorkTimesStory:(NSString *)date
                      onYear:(NSString *)year
                     success:(void (^)(NMANewsStory *story))success
                     failure:(void (^)(NSError *error))failure {

    NSURL *requestURL = [NSURL URLWithString:[self configureQueryString:date withYear:year]];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:requestURL];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSMutableArray *stories = [self parseNYTJSON:responseObject];
        success([stories objectAtIndex:0]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get NYT information");
        failure(nil);
     }];

    [operation start];

}

- (NSString *)configureQueryString:(NSString *)date withYear:(NSString *)year{
    NSString *urlQueryDefault = @"http://api.nytimes.com/svc/search/v2/articlesearch.json?fq=section_name.contains%3A%22Front+Page%22+OR+%22World%22";
    NSString *apiKey = @"dcea47d59f7c08951bc83252867d596d:1:72360000";
    NSString *dateWithYear = [year stringByAppendingString:date];
    NSString *urlWithStartYear = [urlQueryDefault stringByAppendingString:[NSString stringWithFormat:@"&begin_date=%@", dateWithYear]];
    NSString *urlWithYearRange = [urlWithStartYear stringByAppendingString:[NSString stringWithFormat:@"&end_date=%@", dateWithYear]];
    NSString *urlWithAPI = [urlWithYearRange stringByAppendingString:[NSString stringWithFormat:@"&api-key=%@", apiKey]];
    return urlWithAPI;
}

- (NSMutableArray *)parseNYTJSON:(NSDictionary *)json {
    NSMutableArray *stories = [[NSMutableArray alloc] init];
    NMANewsStory *story = [[NMANewsStory alloc] init];
    NSDictionary *response = [json objectForKey:@"response"];
    NSDictionary *docs = [response objectForKey:@"docs"];
    for (NSDictionary *item in docs) {
        NSMutableArray *images = [item valueForKey:@"multimedia"];
        story.imageLinks = images;
        story.abstract = [self resolveNSNullToNil:[item valueForKey:@"abstract"]];
        story.headline = [item valueForKey:@"headline"];
        story.headline = [self resolveNSNullToNil:[story.headline valueForKey:@"main"]];
        story.snippet = [self resolveNSNullToNil:[item valueForKey:@"snippet"]];
        story.articleURL = [self resolveNSNullToNil:[item valueForKey:@"web_url"]];
        story.byline = [item valueForKey:@"byline"];
        story.byline = [self resolveNSNullToNil:[story.byline valueForKey:@"original"]];
        [stories addObject:story];
    }
    return stories;
  }

- (id)resolveNSNullToNil:(id)objectForKey {
    return [NSNull null] == objectForKey ? nil : objectForKey;
}

- (void)getiTunesMusicForSong:(NMASong *)song
                      success:(void (^)(NMASong *songWithPreview))success
                      failure:(void (^)(NSError *error))failure {

    NSString *searchTerm = [NSString stringWithFormat:@"%@ %@", song.title, song.artistAsAppearsOnLabel];
    NSDictionary *parameters = @{ @"term":searchTerm, @"media":@"music" };
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/JSON"];

    NSString *searchString = @"https://itunes.apple.com/search";

    [manager GET:searchString
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSArray *resultsArray = [responseObject objectForKey:@"results"];
             for (NSDictionary *result in resultsArray) {
                 if ([[result valueForKey:@"kind"] isEqualToString:@"song"]) {
                     song.previewURL = [result objectForKey:@"previewUrl"];

                     NSMutableArray *images = [[NSMutableArray alloc] init];
                     [images addObject:[result objectForKey:@"artworkUrl100"]];
                     [images addObject:[result objectForKey:@"artworkUrl60"]];
                     [images addObject:[result objectForKey:@"artworkUrl30"]];
                     song.albumImageUrlsArray = [images copy];

                     break;
                 }
             }
             if (success) {
                 success(song);
             }
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             if (failure) {
                 failure (error); //TODO: handle error
             }
         }
     ];
}

#pragma mark - Facebook Requests
- (void)requestFBPostsFromDate:(NSString *)year
                       success:(void (^)(NSArray *posts))success
                       failure:(void (^)(NSError *error))failure {
    //Facebook wants its dates in UTC, so make sure we set local boundaries...
    NSDate *targetDateStart = [self getLocalDate:year startOfDay:YES];
    NSDate *targetDateEnd = [self getLocalDate:year startOfDay:NO];
    
    //...Before formatting in UTC time
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *sinceTime = [dateFormatter stringFromDate:targetDateStart];
    NSString *untilTime = [dateFormatter stringFromDate:targetDateEnd];

    NSString *path = @"/me/posts";
    NSDictionary *params = @{
                             @"since" : sinceTime,
                             @"until" : untilTime
                             };
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:path
                                                                   parameters:params
                                                                   HTTPMethod:@"GET"];
    
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        
        //we need to update the posts on the main thread with the UI
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *posts = [result objectForKey:@"data"];
            if(posts) {
                success(posts);
            }
        });
        
    }];
}

- (void)requestFBPostPicture:(NSString *)imageId
                     success:(void (^)(NSString *imagePath))success
                     failure:(void (^)(NSError *error))failure {
    NSString *path = [NSString stringWithFormat:@"/%@", imageId];
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:path
                                                                   parameters:nil
                                                                   HTTPMethod:@"GET"];
    
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        
        //we need to update the posts on the main thread with the UI
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *imageVersions = [result objectForKey:@"images"];
            if(imageVersions) {
                NSString *imagePath = [imageVersions[0] objectForKey:@"source"];
                success(imagePath);
            }
        });
        
    }];
}

#pragma mark - Format Utility

///@discussion if startOfDay, the time of the date is 00:00:00am, else its 11:59:59pm (the end of the day)
- (NSDate *)getLocalDate:(NSString *)year
              startOfDay:(BOOL)start {
    NSDateComponents *presentDateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                                              fromDate:[NSDate date]];
    
    NSDateComponents *targetDateComponents = [[NSDateComponents alloc] init];
    [targetDateComponents setYear:[year integerValue]];
    [targetDateComponents setMonth:presentDateComponents.month];
    [targetDateComponents setDay:presentDateComponents.day - 1];
    [targetDateComponents setHour:(start ? 0 : 23)];
    [targetDateComponents setMinute:(start ? 0 : 59)];
    [targetDateComponents setSecond:(start ? 0 : 59)];
    [targetDateComponents setTimeZone:[NSTimeZone localTimeZone]];
    NSCalendar *gregorianCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    return [gregorianCal dateFromComponents:targetDateComponents];
    
}

@end
