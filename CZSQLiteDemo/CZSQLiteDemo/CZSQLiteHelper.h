//
//  CZSQLiteHelper.h
//  CZSQLiteDemo
//
//  Created by Netease on 2017/12/5.
//  Copyright © 2017年 Clay Zhu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CZSQLite.h"

@interface CZSQLiteHelper : NSObject

@property (strong, nonatomic) CZSQLite *czSQLite;

+ (instancetype)sharedManager;

/** 创建数据库 */
- (void)createDB;
/** 创建表 */
- (void)createTable;

@end
