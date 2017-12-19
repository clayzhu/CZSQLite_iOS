//
//  CZSQLite.h
//  EnjoyiOS
//
//  Created by ug19 on 16/5/30.
//  Copyright © 2016年 Ugood. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "CZSQLiteResult.h"

/**
 *  对 SQLite 数据库的常用操作的封装，可以再二次封装一个帮助类，以更方便地对当前的项目数据库进行操作。
 *  PS: 1. 添加已有的数据库到项目里的时候，务必勾选上 Add to targets.
 *      2. 需要在 Build Phases 的 Link Binary With Libraries 中添加 libsqlite.tbd
 */
@interface CZSQLite : NSObject

#pragma mark - 建数据库和表
/**
*  创建指定名称的数据库，后缀 .db 可加可不加
*
*  @param dbName 要创建的数据库名称
*
*  @return CZSQLiteResult 对象，code 可能返回数据库已经存在、数据库打开失败或成功，出错时 errorMsg 返回出错信息，data 返回 nil
*/
- (CZSQLiteResult *)createDB:(NSString *)dbName;
/**
 *  拷贝一个 bundle 中的数据库到沙盒中的 Document 目录，方便增删改查
 *
 *  @param dbName 要拷贝的数据库名称
 *
 *  @return CZSQLiteResult 对象，code 可能返回数据库已经存在、数据库打开失败或成功，出错时 errorMsg 返回出错信息，data 返回 nil
 */
- (CZSQLiteResult *)copyDBFromBundle:(NSString *)dbName;
/**
 *  为数据库创建指定名称的表，并定义列名和列类型
 *
 *  @param tableName 要创建的表名
 *  @param columns   每一列列名和列类型组成的列表，格式如：@[@"id INTEGER PRIMARY KEY AUTOINCREMENT", @"name TEXT", @"age INTEGER"]
 *
 *  @return CZSQLiteResult 对象，code 可能返回数据库打开失败、数据库操作失败或成功，出错时 errorMsg 返回出错信息，data 返回 nil
 */
- (CZSQLiteResult *)createTable:(NSString *)tableName columns:(NSArray *)columns;

#pragma mark - 增删改查
#pragma mark 添加
/**
 *  为数据库的指定表插入数据
 *
 *  @param dataDic   要插入的数据字典，key 为列名，value 为值，格式如：@{@"name":@"A", @"age":@"24"}，id 会自增
 *  @param tableName 指定表
 *
 *  @return CZSQLiteResult 对象，code 可能返回数据库打开失败、数据库操作失败或成功，出错时 errorMsg 返回出错信息，data 返回 nil
 */
- (CZSQLiteResult *)insertData:(NSDictionary *)dataDic forTable:(NSString *)tableName;
/**
 *  为数据库的指定表的所有列插入一行数据
 *
 *  @param dataList  对应表的完整的一行数据，值的顺序与列在表中的顺序一致，如：@[@"1", @"Clay", @"24"]，id 也不能省略
 *  @param tableName 指定表
 *
 *  @return CZSQLiteResult 对象，code 可能返回数据库打开失败、数据库操作失败或成功，出错时 errorMsg 返回出错信息，data 返回 nil
 */
- (CZSQLiteResult *)insertDataForOneRow:(NSArray *)dataList forTable:(NSString *)tableName;
/**
 为数据库的指定表批量插入一组数据

 @param dataDicList 要插入的一组数据，每一项为一个字典，key 为列名，value 为值，格式如：@{@"name":@"A", @"age":@"24"}，id 会自增
 @param tableName 指定表
 */
- (void)insertDataBatch:(NSArray<NSDictionary *> *)dataDicList forTable:(NSString *)tableName;

#pragma mark 修改
/**
 *  根据条件为数据库的指定表更新数据
 *
 *  @param newDataDic     要更新的数据字典，key 为列名，value 为值，格式如：@{@"name":@"A", @"age":@"24"}
 *  @param conditionParam WHERE 更新条件参数，可传的类型为 NSDictionary、NSString。条件为 NSDictionary 类型时，key 为列名，value 为值，可拼装格式为：column1 = 'value1' AND column2 = 'value2'；其他要使用 OR 或 <= 等条件时，使用 NSString 自定义条件语句。WHERE 不需要传入，可以传空
 *  @param tableName      指定表
 *
 *  @return CZSQLiteResult 对象，code 可能返回数据库打开失败、数据库操作失败或成功，出错时 errorMsg 返回出错信息，data 返回 nil
 */
- (CZSQLiteResult *)updateData:(NSDictionary *)newDataDic condition:(id)conditionParam forTable:(NSString *)tableName;
/**
 根据条件为数据库的指定表批量更新一组数据

 @param newDataDicList 要更新的一组数据，每一项为一个字典，key 为列名，value 为值，格式如：@{@"name":@"A", @"age":@"24"}
 @param conditionParamList 与要更新的一组数据一一对应的一组条件，每一项为一个 WHERE 更新条件参数，可传的类型为 NSDictionary、NSString。条件为 NSDictionary 类型时，key 为列名，value 为值，可拼装格式为：column1 = 'value1' AND column2 = 'value2'；其他要使用 OR 或 <= 等条件时，使用 NSString 自定义条件语句。WHERE 不需要传入，可以传空
 @param tableName 指定表
 */
- (void)updateDataBatch:(NSArray<NSDictionary *> *)newDataDicList condition:(NSArray<id> *)conditionParamList forTable:(NSString *)tableName;

#pragma mark 删除
/**
 *  根据条件删除数据库的指定表中的数据
 *
 *  @param conditionParam WHERE 删除条件参数，可传的类型为 NSDictionary、NSString。条件为 NSDictionary 类型时，key 为列名，value 为值，可拼装格式为：column1 = 'value1' AND column2 = 'value2'；其他要使用 OR 或 <= 等条件时，使用 NSString 自定义条件语句；当要删除整张表里的数据时，传入 nil。WHERE 不需要传入，可以传空
 *  @param tableName      指定表
 *
 *  @return CZSQLiteResult 对象，code 可能返回数据库打开失败、数据库操作失败或成功，出错时 errorMsg 返回出错信息，data 返回 nil
 */
- (CZSQLiteResult *)deleteDataWithCondition:(id)conditionParam forTable:(NSString *)tableName;
/**
 根据条件批量删除数据库的指定表中的一组数据

 @param conditionParamList 要删除的数据的一组条件，每一项为一个 WHERE 删除条件参数，可传的类型为 NSDictionary、NSString。条件为 NSDictionary 类型时，key 为列名，value 为值，可拼装格式为：column1 = 'value1' AND column2 = 'value2'；其他要使用 OR 或 <= 等条件时，使用 NSString 自定义条件语句；当要删除整张表里的数据时，传入 nil。WHERE 不需要传入，可以传空
 @param tableName 指定表
 */
- (void)deleteDataWithConditionBatch:(NSArray<id> *)conditionParamList forTable:(NSString *)tableName;
/**
 从数据库删除指定表
 
 @param tableName 指定表
 */
- (CZSQLiteResult *)dropTable:(NSString *)tableName;

#pragma mark 查找
/**
 *  根据条件从数据库的指定表查询指定列的数据
 *
 *  @param columnList     要查询的指定列的列名列表，格式如：@[@"name", @"age"]；传入 nil 表示查询全部
 *  @param conditionParam WHERE 查询条件参数，可传的类型为 NSDictionary、NSString。条件为 NSDictionary 类型时，key 为列名，value 为值，可拼装格式为：column1 = 'value1' AND column2 = 'value2'；其他要使用 OR 或 <= 等条件时，使用 NSString 自定义条件语句。WHERE 不需要传入，可以传空
 *  @param tableName      指定表
 *
 *  @return CZSQLiteResult 对象，code 可能返回数据库打开失败、数据库查询失败或成功，出错时 errorMsg 返回出错信息，查询成功时 data 返回一个数据列表，里面的每一项为一个字典，key 为列名，value 为值
 */
- (CZSQLiteResult *)selectData:(NSArray *)columnList condition:(id)conditionParam forTable:(NSString *)tableName;
/**
 *  查询数据库的指定表的所有数据
 *
 *  @param tableName 指定表
 *
 *  @return CZSQLiteResult 对象，code 可能返回数据库打开失败、数据库查询失败或成功，出错时 errorMsg 返回出错信息，查询成功时 data 返回一个数据列表，里面的每一项为一个字典，key 为列名，value 为值
 */
- (CZSQLiteResult *)selectAllFromTable:(NSString *)tableName;

#pragma mark - 使用 SQL 语句
/**
 *  直接使用 SQL 语句的数据库操作方法，更加复杂的数据库操作可以直接使用这个方法
 *
 *  @param sqlStr 符合 SQLite 语法标准的语句
 *
 *  @return CZSQLiteResult 对象，code 可能返回数据库打开失败、数据库操作失败或成功，出错时 errorMsg 返回出错信息，data 返回 nil
 */
- (CZSQLiteResult *)execSQL:(NSString *)sqlStr;
/**
 使用事务批量操作数据库的方法

 @param sqlStrList 符合 SQLite 语法标准的语句数组
 */
- (void)execTransactionSQL:(NSArray *)sqlStrList;

@end
