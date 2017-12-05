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
                                                       @"age INTEGER"]];
}

- (void)insertPerson:(PersonModel *)person {
    [self.czSQLite insertData:@{@"name":person.name,
                                @"age":@(person.age)
                                }
                     forTable:kTable_Person];
}

- (void)insertPersons:(NSArray<PersonModel *> *)personList {
    NSMutableArray<NSDictionary *> *ma = [NSMutableArray arrayWithCapacity:personList.count];
    for (PersonModel *model in personList) {
        NSDictionary *dic = @{@"name":model.name,
                              @"age":@(model.age)
                              };
        [ma addObject:dic];
    }
    [self.czSQLite insertDataBatch:ma forTable:kTable_Person];
}

- (NSArray<NSDictionary *> *)queryPersons {
    CZSQLiteResult *result = [self.czSQLite selectAllFromTable:kTable_Person];
    if (result.data.count > 0) {
        NSMutableArray<NSDictionary *> *ma = [NSMutableArray array];
        for (NSDictionary *dic in result.data) {
            [ma addObject:dic];
        }
        return ma;
    }
    return nil;
}

- (void)updateName:(NSString *)name whereAge:(NSNumber *)age {
    [self.czSQLite updateData:@{@"name":name} condition:@{@"age":age} forTable:kTable_Person];
}

- (void)updateNames:(NSArray<NSString *> *)names whereAges:(NSArray<NSNumber *> *)ages {
    if (names.count != ages.count) {
        return;
    }
    NSMutableArray<NSDictionary *> *nameMA = [NSMutableArray arrayWithCapacity:names.count];
    NSMutableArray<NSDictionary *> *ageMA = [NSMutableArray arrayWithCapacity:ages.count];
    for (NSUInteger i = 0; i < names.count; i ++) {
        NSString *name = names[i];
        [nameMA addObject:@{@"name":name}];
        NSNumber *age = ages[i];
        [ageMA addObject:@{@"age":age}];
    }
    [self.czSQLite updateDataBatch:nameMA condition:ageMA forTable:kTable_Person];
}

@end

@implementation PersonModel

+ (instancetype)modelWithName:(NSString *)name age:(NSUInteger)age {
    PersonModel *model = [[PersonModel alloc] init];
    model.name = name;
    model.age = age;
    return model;
}

@end
