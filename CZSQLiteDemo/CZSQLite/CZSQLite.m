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

- (CZSQLiteResult *)createDB:(NSString *)dbName {
	CZSQLiteResult *result = [[CZSQLiteResult alloc] init];
	NSString *dbPath = [self dbPath:dbName];
	if ([[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
		NSLog(@"数据库已经存在");
		result.errorMsg = @"数据库已经存在";
	} else {
		int openCode = sqlite3_open([dbPath UTF8String], &_db);
		result.code = openCode;
		if (openCode != SQLITE_OK) {
			NSLog(@"数据库打开失败");
			result.errorMsg = @"数据库打开失败";
		} else {
			NSLog(@"数据库打开成功");
		}
		sqlite3_close(_db);
	}
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
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
		
	} else {
		int openCode = sqlite3_open([dbPath UTF8String], &_db);
		result.code = openCode;
		if (openCode != SQLITE_OK) {
			NSLog(@"数据库打开失败");
			result.errorMsg = @"数据库打开失败";
		} else {
			NSLog(@"数据库打开成功");
		}
		sqlite3_close(_db);
	}
	return result;
}

- (CZSQLiteResult *)createTable:(NSString *)tableName columns:(NSArray *)columns forDB:(NSString *)dbName {
	NSString *columnStr = @"";
	for (NSString *key in columns) {	// 将表中每一列列名列类型的字符串拼装成 SQL 语句的参数
		columnStr = [columnStr stringByAppendingString:key];
		columnStr = [columnStr stringByAppendingString:@","];
	}
	columnStr = [columnStr substringToIndex:columnStr.length - 1];	// 剪掉最后一个“,”
	NSString *sqlCreate = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@)", tableName, columnStr];
	return [self execSQL:sqlCreate forDB:dbName];
}

- (CZSQLiteResult *)execSQL:(NSString *)sqlStr forDB:(NSString *)dbName {
	CZSQLiteResult *result = [[CZSQLiteResult alloc] init];
	NSString *dbPath = [self dbPath:dbName];
	int openCode = sqlite3_open([dbPath UTF8String], &_db);	// 打开数据库的 code
	if (openCode != SQLITE_OK) {
		NSLog(@"数据库打开失败");
		result.code = openCode;
		result.errorMsg = @"数据库打开失败";
	} else {
		char *err;
		int execCode = sqlite3_exec(_db, [sqlStr UTF8String], NULL, NULL, &err);	// 执行 SQL 语句的 code
		result.code = execCode;
		if (execCode != SQLITE_OK) {
			NSLog(@"数据库操作失败");
			result.errorMsg = [[NSString alloc] initWithUTF8String:err];
		} else {
			NSLog(@"数据库操作成功");
		}
	}
	sqlite3_close(_db);
	return result;
}

- (CZSQLiteResult *)insertData:(NSDictionary *)dataDic forTable:(NSString *)tableName forDB:(NSString *)dbName {
	NSString *insertKey = @"";
	NSString *insertValue = @"";
	for (NSString *key in dataDic.allKeys) {
		insertKey = [insertKey stringByAppendingFormat:@"%@,", key];	// 拼装第一个()中的列名参数
		insertValue = [insertValue stringByAppendingFormat:@"'%@',", dataDic[key]];	// 拼装第二个()中的值参数
	}
	insertKey = [insertKey substringToIndex:insertKey.length - 1];	// 剪掉最后一个“,”
	insertValue = [insertValue substringToIndex:insertValue.length - 1];	// 剪掉最后一个“,”
	NSString *sqlInsert = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", tableName, insertKey, insertValue];
	return [self execSQL:sqlInsert forDB:dbName];
}

- (CZSQLiteResult *)insertDataForOneRow:(NSArray *)dataList forTable:(NSString *)tableName forDB:(NSString *)dbName {
	NSString *insertValue = @"";
	for (NSString *value in dataList) {
		insertValue = [insertValue stringByAppendingFormat:@"'%@',", value];	// 拼装一行的所有列的值参数
	}
	insertValue = [insertValue substringToIndex:insertValue.length - 1];	// 剪掉最后一个“,”
	NSString *sqlInsert = [NSString stringWithFormat:@"INSERT INTO %@ VALUES (%@)", tableName, insertValue];
	return [self execSQL:sqlInsert forDB:dbName];
}

- (CZSQLiteResult *)updateData:(NSDictionary *)newDataDic condition:(id)conditionParam forTable:(NSString *)tableName forDB:(NSString *)dbName {
	NSString *newData = @"";
	for (NSString *newKey in newDataDic.allKeys) {
		newData = [newData stringByAppendingFormat:@"%@ = '%@',", newKey, newDataDic[newKey]];	// 拼装 column1 = 'value1' AND column2 = 'value2' 格式的参数
	}
	newData = [newData substringToIndex:newData.length - 1];	// 剪掉最后一个“,”
	NSString *sqlUpdate = [NSString stringWithFormat:@"UPDATE %@ SET %@%@", tableName, newData, [self assembleCondition:conditionParam]];
	return [self execSQL:sqlUpdate forDB:dbName];
}

- (CZSQLiteResult *)deleteDataWithCondition:(id)conditionParam forTable:(NSString *)tableName forDB:(NSString *)dbName {
	NSString *sqlDelete = [NSString stringWithFormat:@"DELETE FROM %@%@", tableName, [self assembleCondition:conditionParam]];
	return [self execSQL:sqlDelete forDB:dbName];
}

- (CZSQLiteResult *)selectData:(NSArray *)columnList condition:(id)conditionParam forTable:(NSString *)tableName forDB:(NSString *)dbName {
	CZSQLiteResult *result = [[CZSQLiteResult alloc] init];
	NSString *dbPath = [self dbPath:dbName];
	int openCode = sqlite3_open([dbPath UTF8String], &_db);
	if (openCode != SQLITE_OK) {
		NSLog(@"数据库打开失败");
		result.code = openCode;
		result.errorMsg = @"数据库打开失败";
	} else {
		NSString *column = @"";
		if (columnList && columnList.count > 0) {
			for (NSString *columnName in columnList) {
				column = [column stringByAppendingFormat:@"%@,", columnName];	// 拼装查询指定列名的参数
			}
			column = [column substringToIndex:column.length - 1];	// 剪掉最后一个“,”
		} else {	// 列名列表参数不传的话，表示查询全部
			column = @"*";
		}
		NSString *sqlQuery = [NSString stringWithFormat:@"SELECT %@ FROM %@%@", column, tableName, [self assembleCondition:conditionParam]];
		sqlite3_stmt *stmt;
		int prepareCode = sqlite3_prepare_v2(_db, [sqlQuery UTF8String], -1, &stmt, NULL);	// 查询数据库的 code
		result.code = prepareCode;
		if (prepareCode == SQLITE_OK) {
			NSLog(@"数据库查询成功");
			NSMutableArray *results = [NSMutableArray array];
			while (sqlite3_step(stmt) == SQLITE_ROW) {	// 一行行逐步查询
				NSMutableDictionary *columnNameValue = [NSMutableDictionary dictionary];
				for (int i = 0; i < sqlite3_column_count(stmt); i ++) {	// 查询的列数
					NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(stmt, i)];	// 第i列的列名
					NSString *columnValue;
					if (NULL != (char *)sqlite3_column_text(stmt, i)) {	// 该列的值
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
			NSString *errMsgStr = [[NSString alloc] initWithUTF8String:errMsg];
			NSLog(@"errmsg:%@", errMsgStr);
			result.errorMsg = errMsgStr;
		}
	}
	sqlite3_close(_db);
	return result;
}

- (CZSQLiteResult *)selectAllFromTable:(NSString *)tableName forDB:(NSString *)dbName {
	return [self selectData:nil condition:nil forTable:tableName forDB:dbName];
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

@end
