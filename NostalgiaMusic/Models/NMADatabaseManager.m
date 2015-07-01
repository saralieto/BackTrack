//
//  NMADatabaseManager.m
//  NostalgiaMusic
//
//  Created by Amy Ly on 6/30/15.
//  Copyright (c) 2015 Intrepid Pursuits. All rights reserved.
//

#import "NMADatabaseManager.h"
#import "NMABillboardSong.h"
#import <sqlite3.h>

@interface NMADatabaseManager ()

@property (strong, nonatomic) NSMutableArray *queryResultsArray;

@end

@implementation NMADatabaseManager

#pragma mark - Singleton

+ (instancetype)sharedDatabaseManager {
    static id sharedDB = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDB = [[NMADatabaseManager alloc] init];
    });
    return sharedDB;
}

#pragma mark - Public Methods

- (NMABillboardSong *)getSongFromYear:(NSString *)year {
    NMABillboardSong *randomSong;
    sqlite3 *database;
    NSString *dbFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/tracks.db"];
    if (sqlite3_open([dbFilePath UTF8String], &database) == SQLITE_OK) {
        const char *sql = [[NSString stringWithFormat:@"SELECT * FROM tracks WHERE year_peaked = %@", year] UTF8String];
        sqlite3_stmt *selectStatement;
        if (sqlite3_prepare_v2(database, sql, -1, &selectStatement, NULL) == SQLITE_OK) {
            randomSong = [self getRandomSongWithSQLStatement:selectStatement];
        }
        sqlite3_finalize(selectStatement); // destroy prepared statement object
    }
    sqlite3_close(database); // close database
    return randomSong;
}

#pragma mark - Private Methods

- (NMABillboardSong *)getRandomSongWithSQLStatement:(sqlite3_stmt *)statement {
    self.queryResultsArray = [[NSMutableArray alloc] init];
    while (sqlite3_step(statement) == SQLITE_ROW) {
        NMABillboardSong *newSong = [[NMABillboardSong alloc] init];
        newSong.yearPeaked = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 2)];
        newSong.yearlyRank = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 3)];
        newSong.artistAsAppearsOnLabel = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 10)];
        newSong.title = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 13)];
        [self.queryResultsArray addObject:newSong];
    }
    NSUInteger randomIndex = arc4random() % [self.queryResultsArray count];
    return self.queryResultsArray[randomIndex];
}

@end
