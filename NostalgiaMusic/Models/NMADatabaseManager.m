//
//  NMADatabaseManager.m
//  NostalgiaMusic
//
//  Created by Amy Ly on 6/30/15.
//  Copyright (c) 2015 Intrepid Pursuits. All rights reserved.
//

#import "NMADatabaseManager.h"
#import "NMASong.h"
#import <sqlite3.h>

static NSString * const query = @"SELECT * FROM tracks WHERE year_peaked = %@";

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

- (NMASong *)getSongFromYear:(NSString *)year {
    NMASong *song;
    sqlite3 *database;
    NSString *dbFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/tracks.db"];
    
    if (sqlite3_open([dbFilePath UTF8String], &database) == SQLITE_OK) {
        const char *sql = [[NSString stringWithFormat:query, year] UTF8String];
        sqlite3_stmt *selectStatement;
        int databaseCallResult = sqlite3_prepare_v2(database, sql, -1, &selectStatement, NULL);
        song = (databaseCallResult == SQLITE_OK) ? [self getSongWithSQLStatement:selectStatement] : nil;
        sqlite3_finalize(selectStatement);
    }
    
    sqlite3_close(database);
    return song;
}

#pragma mark - Private Methods

- (NMASong *)getSongWithSQLStatement:(sqlite3_stmt *)statement {
    self.queryResultsArray = [[NSMutableArray alloc] init];
    NSInteger dayOfMonth = [self dayOfMonth];

    while (sqlite3_step(statement) == SQLITE_ROW) {
        NMASong *newSong = [[NMASong alloc] init];
        newSong.yearPeaked = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 2)];
        newSong.yearlyRank = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 3)];
        newSong.artistAsAppearsOnLabel = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 10)];
        newSong.title = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 13)];
        [self.queryResultsArray addObject:newSong];
    }
    
    if ([self.queryResultsArray count]) {
        NSUInteger hashIndex = [self.queryResultsArray count] % dayOfMonth;
        return self.queryResultsArray[hashIndex];
    } else {
        return nil;
    }
}

- (NSInteger)dayOfMonth {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
    NSInteger day = [components day];
    return day;
}

@end
