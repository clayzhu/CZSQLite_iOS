//
//  CZSQLite.m
//  EnjoyiOS
//
//  Created by ug19 on 16/5/30.
//  Copyright © 2016年 Ugood. All rights reserved.
//

#import "CZSQLite.h"

@interface CZSQLite ()
{
    sqlite3 *_db;
}

@end

@implementation CZSQLite

- (void)openDB:(NSString *)dbPath result:(CZSQLiteResult *)result {
    @synchronized (self) {
        sqlite3_config(SQLITE_CONFIG_SERIALIZED);   // SQLite 使用串行模式，所有线程共用全局的数据库连接，并开启 WAL 模式，提高性能的同时，保证线程安全
        
        int openCode = sqlite3_open([dbPath UTF8String], &_db);
        result.code = openCode;
        if (openCode != SQLITE_OK) {
            NSLog(@"数据库打开失败");
            result.errorMsg = @"数据库打开失败";
        } else {
            NSLog(@"数据库打开成功");
            // 开启 Write-Ahead Logging 模式，并发性更好
            char *err;
            if (sqlite3_exec(_db, "PRAGMA journal_mode=WAL;", NULL, NULL, &err) != SQLITE_OK) {
                NSLog(@"Failed to set WAL mode: %s", err);
            }
            sqlite3_wal_checkpoint(_db, NULL);  // 每次测试前先 checkpoint，避免 WAL 文件过大而影响性能
        }
    }
}

#pragma mark - 建数据库和表
- (CZSQLiteResult *)createDB:(NSString *)dbName {
	CZSQLiteResult *result = [[CZSQLiteResult alloc] init];
	NSString *dbPath = [self dbPath:dbName];
	if ([[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
		NSLog(@"数据库已经存在");
		result.errorMsg = @"数据库已经存在";
	}
    [self openDB:dbPath result:result];
	return result;
}

- (CZSQLiteResult *)copyDBFromBundle:(NSString *)dbName {
	CZSQLiteResult *result = [[CZSQLiteResult alloc] init];
	NSString *dbPath = [self dbPath:dbName];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
		NSLog(@"数据库已经存在");
		result.errorMsg = @"数据库已经存在";
	} else {
		NSLog(@"Copy the template db to local!");
		NSString *type;
		if ([dbName hasSuffix:@".db"]) {	// 传入的数据库名称参数带后缀 .db
			type = @"";
		} else {
			type = @".db";
		}
		NSString *localDBFilePath = [[NSBundle mainBundle] pathForResource:dbName ofType:type];	// bundle 中的数据库路径
		NSData *mainBundleFile = [NSData dataWithContentsOfFile:localDBFilePath];	// bundle 中的数据库的数据
		[[NSFileManager defaultManager] createFileAtPath:dbPath contents:mainBundleFile attributes:nil];	// 在 Document 中创建一个同名同数据的数据库
	}
    [self openDB:dbPath result:result];
	return result;
}

- (CZSQLiteResult *)createTable:(NSString *)tableName columns:(NSArray *)columns {
	NSString *columnStr = @"";
	for (NSString *key in columns) {	// 将表中每一列列名列类型的字符串拼装成 SQL 语句的参数
		columnStr = [columnStr stringByAppendingString:key];
		columnStr = [columnStr stringByAppendingString:@","];
	}
	columnStr = [columnStr substringToIndex:columnStr.length - 1];	// 剪掉最后一个“,”
	NSString *sqlCreate = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@)", tableName, columnStr];
	return [self execSQL:sqlCreate];
}

#pragma mark - 增删改查
- (CZSQLiteResult *)insertData:(NSDictionary *)dataDic forTable:(NSString *)tableName {
    NSString *sqlStr = [self assembleInsertData:dataDic forTable:tableName];
	return [self execSQL:sqlStr];
}

- (CZSQLiteResult *)insertDataForOneRow:(NSArray *)dataList forTable:(NSString *)tableName {
    NSString *insertValue = @"";
    for (NSString *value in dataList) {
        insertValue = [insertValue stringByAppendingFormat:@"'%@',", value];    // 拼装一行的所有列的值参数
    }
    insertValue = [insertValue substringToIndex:insertValue.length - 1];    // 剪掉最后一个“,”
    NSString *sqlStr = [NSString stringWithFormat:@"INSERT INTO %@ VALUES (%@)", tableName, insertValue];
	return [self execSQL:sqlStr];
}

- (void)insertDataBatch:(NSArray<NSDictionary *> *)dataDicList forTable:(NSString *)tableName {
    NSMutableArray *sqlStrMA = [NSMutableArray arrayWithCapacity:dataDicList.count];
    for (NSDictionary *dataDic in dataDicList) {
        NSString *sqlStr = [self assembleInsertData:dataDic forTable:tableName];
        [sqlStrMA addObject:sqlStr];
    }
    [self execTransactionSQL:sqlStrMA];
}

- (CZSQLiteResult *)updateData:(NSDictionary *)newDataDic condition:(id)conditionParam forTable:(NSString *)tableName {
    NSString *sqlStr = [self assembleUpdateData:newDataDic condition:conditionParam forTable:tableName];
	return [self execSQL:sqlStr];
}

- (void)updateDataBatch:(NSArray<NSDictionary *> *)newDataDicList condition:(NSArray<id> *)conditionParamList forTable:(NSString *)tableName {
    if (newDataDicList.count != conditionParamList.count) { // 需要更新的数据个数和条件个数对不上
        return;
    }
    NSMutableArray *sqlStrMA = [NSMutableArray arrayWithCapacity:newDataDicList.count];
    for (NSUInteger i = 0; i < newDataDicList.count; i ++) {
        NSDictionary *newDataDic = newDataDicList[i];
        id conditionParam = conditionParamList[i];
        NSString *sqlStr = [self assembleUpdateData:newDataDic condition:conditionParam forTable:tableName];
        [sqlStrMA addObject:sqlStr];
    }
    [self execTransactionSQL:sqlStrMA];
}

- (CZSQLiteResult *)deleteDataWithCondition:(id)conditionParam forTable:(NSString *)tableName {
	NSString *sqlStr = [self assembleDeleteDataWithCondition:conditionParam forTable:tableName];
	return [self execSQL:sqlStr];
}

- (void)deleteDataWithConditionBatch:(NSArray<id> *)conditionParamList forTable:(NSString *)tableName {
    NSMutableArray *sqlStrMA = [NSMutableArray arrayWithCapacity:conditionParamList.count];
    for (id conditionParam in conditionParamList) {
        NSString *sqlStr = [self assembleDeleteDataWithCondition:conditionParam forTable:tableName];
        [sqlStrMA addObject:sqlStr];
    }
    if (sqlStrMA.count == 0) {
        NSString *sqlStr = [self assembleDeleteDataWithCondition:nil forTable:tableName];
        [sqlStrMA addObject:sqlStr];
    }
    [self execTransactionSQL:sqlStrMA];
}

- (CZSQLiteResult *)dropTable:(NSString *)tableName {
    NSString *sqlStr = [NSString stringWithFormat:@"DROP TABLE %@", tableName];
    return [self execSQL:sqlStr];
}

- (CZSQLiteResult *)selectData:(NSArray *)columnList condition:(id)conditionParam forTable:(NSString *)tableName {
	CZSQLiteResult *result = [[CZSQLiteResult alloc] init];
    NSString *column = @"";
    if (columnList && columnList.count > 0) {
        for (NSString *columnName in columnList) {
            column = [column stringByAppendingFormat:@"%@,", columnName];    // 拼装查询指定列名的参数
        }
        column = [column substringToIndex:column.length - 1];    // 剪掉最后一个“,”
    } else {    // 列名列表参数不传的话，表示查询全部
        column = @"*";
    }
    @synchronized (self) {
        NSString *sqlStr = [NSString stringWithFormat:@"SELECT %@ FROM %@%@", column, tableName, [self assembleCondition:conditionParam]];
        sqlite3_stmt *stmt;
        int prepareCode = sqlite3_prepare_v2(_db, [sqlStr UTF8String], -1, &stmt, NULL);    // 查询数据库的 code
        result.code = prepareCode;
        if (prepareCode == SQLITE_OK) {
            NSLog(@"数据库查询成功");
            NSMutableArray *results = [NSMutableArray array];
            while (sqlite3_step(stmt) == SQLITE_ROW) {    // 一行行逐步查询
                NSMutableDictionary *columnNameValue = [NSMutableDictionary dictionary];
                for (int i = 0; i < sqlite3_column_count(stmt); i ++) {    // 查询的列数
                    NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(stmt, i)];    // 第i列的列名
                    NSString *columnValue;
                    if (NULL != (char *)sqlite3_column_text(stmt, i)) {    // 该列的值
                        columnValue = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmt, i)];
                    } else {
                        columnValue = @"";
                    }
                    [columnNameValue setObject:columnValue forKey:columnName];
                }
                [results addObject:columnNameValue];
            }
            result.data = results;
        } else {
            NSLog(@"数据库查询失败");
            char *errMsg = (char *)sqlite3_errmsg(_db);
            if (errMsg == NULL) { // 防止 initWithUTF8String 参数为空导致崩溃
                errMsg = "未知错误";
            }
            NSString *errMsgStr = [[NSString alloc] initWithUTF8String:errMsg];
            NSLog(@"errmsg:%@", errMsgStr);
            result.errorMsg = errMsgStr;
        }
    }
	return result;
}

- (CZSQLiteResult *)selectAllFromTable:(NSString *)tableName {
	return [self selectData:nil condition:nil forTable:tableName];
}

#pragma mark - 使用 SQL 语句
- (CZSQLiteResult *)execSQL:(NSString *)sqlStr {
    CZSQLiteResult *result = [[CZSQLiteResult alloc] init];
    char *err;
    int execCode;
    @synchronized (self) {
        execCode = sqlite3_exec(_db, [sqlStr UTF8String], NULL, NULL, &err);    // 执行 SQL 语句的 code
    }
    result.code = execCode;
    if (execCode != SQLITE_OK) {
        if (err == NULL) { // 防止 initWithUTF8String 参数为空导致崩溃
            err = "未知错误";
        }
        NSLog(@"数据库操作失败");
        result.errorMsg = [[NSString alloc] initWithUTF8String:err];
    } else {
        NSLog(@"数据库操作成功");
    }
    return result;
}

- (void)execTransactionSQL:(NSArray *)sqlStrList {
    if (sqlStrList.count == 0) {
        return;
    }
    @synchronized (self) {
        @try {
            char *errorMsg;
            if (sqlite3_exec(_db, "BEGIN", NULL, NULL, &errorMsg) == SQLITE_OK) {   // 启动事务
                NSLog(@"启动事务成功");
                sqlite3_free(errorMsg);
                
                // 执行 SQL 语句。如果使用 sqlite3_exec，SQLite 要对循环中每一句 SQL 语句进行“词法分析”和“语法分析”，这对于同时插入大量数据的操作来说，很浪费时间
                sqlite3_stmt *statement;
                for (NSUInteger i = 0; i < sqlStrList.count; i ++) {
                    if (sqlite3_prepare_v2(_db, [sqlStrList[i] UTF8String], -1, &statement, NULL) == SQLITE_OK) {
                        if (sqlite3_step(statement) != SQLITE_DONE) {
                            NSLog(@"数据库操作成功");
                            sqlite3_finalize(statement);
                        }
                    }
                }
                
                if (sqlite3_exec(_db, "COMMIT", NULL, NULL, &errorMsg) == SQLITE_OK) {  // 提交事务
                    NSLog(@"提交事务成功");
                }
                sqlite3_free(errorMsg);
            } else {
                NSLog(@"启动事务失败");
                sqlite3_free(errorMsg);
            }
        } @catch (NSException *exception) {
            char *errorMsg;
            if (sqlite3_exec(_db, "ROLLBACK", NULL, NULL, &errorMsg) == SQLITE_OK) {    // 回滚事务
                NSLog(@"回滚事务成功");
            }
            sqlite3_free(errorMsg);
        } @finally {
            
        }
    }
}

#pragma mark - Private
/** 数据库所在路径 */
- (NSString *)dbPath:(NSString *)dbName {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *document = [paths objectAtIndex:0];
	NSString *tempDBName;
	if ([dbName hasSuffix:@".db"]) {	// 传入的数据库名称参数带后缀 .db
		tempDBName = dbName;
	} else {
		tempDBName = [dbName stringByAppendingString:@".db"];
	}
	NSString *dbPath = [document stringByAppendingPathComponent:tempDBName];
	return dbPath;
}

#pragma mark 拼装 SQL 语句
/** 根据条件参数拼装 WHERE 语句 */
- (NSString *)assembleCondition:(id)conditionParam {
	NSString *where = @"";
	NSString *condition = @"";
	if ([conditionParam isKindOfClass:[NSString class]]) {	// 字符串形式的条件，自定义的条件语句，拼装上 WHERE
		NSString *conditionStr = (NSString *)conditionParam;
		if (conditionStr && conditionStr.length > 0) {
			where = @" WHERE";
			condition = [@" " stringByAppendingString:conditionStr];
		}
	}
	else if ([conditionParam isKindOfClass:[NSDictionary class]]) {	// 字典形式的条件，拼装成： WHERE column1 = 'value1' AND column2 = 'value2'
		NSDictionary *conditionDic = (NSDictionary *)conditionParam;
		if (conditionParam && conditionDic.allKeys > 0) {
			where = @" WHERE";
			for (NSString *condiKey in conditionDic.allKeys) {
				condition = [condition stringByAppendingFormat:@" %@ = '%@' AND", condiKey, conditionDic[condiKey]];
			}
			condition = [condition substringToIndex:condition.length - 3];
		}
	}
	return [NSString stringWithFormat:@"%@%@", where, condition];
}

/**
 拼装 SQL 语句，为数据库的指定表插入数据

 @param dataDic 要插入的数据字典，key 为列名，value 为值，格式如：@{@"name":@"A", @"age":@"24"}，id 会自增
 @param tableName 指定表
 @return SQL 语句
 */
- (NSString *)assembleInsertData:(NSDictionary *)dataDic forTable:(NSString *)tableName {
    NSString *insertKey = @"";
    NSString *insertValue = @"";
    for (NSString *key in dataDic.allKeys) {
        insertKey = [insertKey stringByAppendingFormat:@"%@,", key];    // 拼装第一个()中的列名参数
        insertValue = [insertValue stringByAppendingFormat:@"'%@',", dataDic[key]];    // 拼装第二个()中的值参数
    }
    insertKey = [insertKey substringToIndex:insertKey.length - 1];    // 剪掉最后一个“,”
    insertValue = [insertValue substringToIndex:insertValue.length - 1];    // 剪掉最后一个“,”
    NSString *sqlStr = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", tableName, insertKey, insertValue];
    return sqlStr;
}

/**
 拼装 SQL 语句，根据条件为数据库的指定表更新数据

 @param newDataDic 要更新的数据字典，key 为列名，value 为值，格式如：@{@"name":@"A", @"age":@"24"}
 @param conditionParam WHERE 更新条件参数，可传的类型为 NSDictionary、NSString。条件为 NSDictionary 类型时，key 为列名，value 为值，可拼装格式为：column1 = 'value1' AND column2 = 'value2'；其他要使用 OR 或 <= 等条件时，使用 NSString 自定义条件语句。WHERE 不需要传入，可以传空
 @param tableName 指定表
 @return SQL 语句
 */
- (NSString *)assembleUpdateData:(NSDictionary *)newDataDic condition:(id)conditionParam forTable:(NSString *)tableName {
    NSString *newData = @"";
    for (NSString *newKey in newDataDic.allKeys) {
        newData = [newData stringByAppendingFormat:@"%@ = '%@',", newKey, newDataDic[newKey]];    // 拼装 column1 = 'value1' AND column2 = 'value2' 格式的参数
    }
    newData = [newData substringToIndex:newData.length - 1];    // 剪掉最后一个“,”
    NSString *sqlStr = [NSString stringWithFormat:@"UPDATE %@ SET %@%@", tableName, newData, [self assembleCondition:conditionParam]];
    return sqlStr;
}

/**
 拼装 SQL 语句，根据条件删除数据库的指定表中的数据

 @param conditionParam WHERE 删除条件参数，可传的类型为 NSDictionary、NSString。条件为 NSDictionary 类型时，key 为列名，value 为值，可拼装格式为：column1 = 'value1' AND column2 = 'value2'；其他要使用 OR 或 <= 等条件时，使用 NSString 自定义条件语句；当要删除整张表里的数据时，传入 nil。WHERE 不需要传入，可以传空
 @param tableName 指定表
 @return SQL 语句
 */
- (NSString *)assembleDeleteDataWithCondition:(id)conditionParam forTable:(NSString *)tableName {
    NSString *sqlStr = [NSString stringWithFormat:@"DELETE FROM %@%@", tableName, [self assembleCondition:conditionParam]];
    return sqlStr;
}

@end
