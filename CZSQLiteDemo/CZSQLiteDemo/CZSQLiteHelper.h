//
//  CZSQLiteHelper.h
//  CZSQLiteDemo
//
//  Created by Netease on 2017/12/5.
//  Copyright © 2017年 Clay Zhu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CZSQLite.h"

@class PersonModel;

@interface CZSQLiteHelper : NSObject

@property (strong, nonatomic) CZSQLite *czSQLite;

+ (instancetype)sharedManager;

/** 创建数据库 */
- (void)createDB;
/** 创建表 */
- (void)createTable;
/** 插入单个数据 */
- (void)insertPerson:(PersonModel *)person;
/** 批量插入多个数据 */
- (void)insertPersons:(NSArray<PersonModel *> *)personList;
/** 更新一个数据 */
- (void)updateName:(NSString *)name whereAge:(NSNumber *)age;
/** 批量更新多个数据 */
- (void)updateNames:(NSArray<NSString *> *)names whereAges:(NSArray<NSNumber *> *)ages;
/** 删除一个数据 */
- (void)deleteAge:(NSNumber *)age;
/** 批量删除多个数据 */
- (void)deleteAges:(NSArray<NSNumber *> *)ages;
/** 查询表中所有数据 */
- (NSArray<NSDictionary *> *)queryPersons;

@end

@interface PersonModel : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSUInteger age;

+ (instancetype)modelWithName:(NSString *)name age:(NSUInteger)age;

@end
