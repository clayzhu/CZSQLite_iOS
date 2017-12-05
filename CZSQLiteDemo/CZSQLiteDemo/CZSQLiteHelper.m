//
//  CZSQLiteHelper.m
//  CZSQLiteDemo
//
//  Created by Netease on 2017/12/5.
//  Copyright © 2017年 Clay Zhu. All rights reserved.
//

#import "CZSQLiteHelper.h"

static NSString *kDatabase = @"CZSQLiteDemo.db";
static NSString *kTable_Person = @"PERSON";

@implementation CZSQLiteHelper

+ (instancetype)sharedManager {
    static CZSQLiteHelper *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[CZSQLiteHelper alloc] init];
    });
    return sharedManager;
}

- (CZSQLite *)czSQLite {
    if (! _czSQLite) {
        _czSQLite = [[CZSQLite alloc] init];
    }
    return _czSQLite;
}

- (void)createDB {
    [self.czSQLite createDB:kDatabase];
}

- (void)createTable {
    [self.czSQLite createTable:kTable_Person columns:@[@"id INTEGER PRIMARY KEY AUTOINCREMENT",
                                                       @"name TEXT",
                                                       @"age INTEGER"]
                         forDB:kDatabase];
}

@end
