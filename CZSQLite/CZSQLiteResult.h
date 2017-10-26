//
//  CZSQLiteResult.h
//  EnjoyiOS
//
//  Created by ug19 on 16/6/1.
//  Copyright © 2016年 Ugood. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CZSQLiteResult : NSObject

/** 数据库操作返回的 code，比如数据库打开失败、操作失败或成功，成功时为0 */
@property (assign, nonatomic) int code;
/** 错误信息，成功时为nil */
@property (strong, nonatomic) NSString *errorMsg;
/** SELECT 时才有数据返回的数据列表，里面的每一项为一个字典，key 为列名，value 为值 */
@property (strong, nonatomic) NSArray<NSDictionary *> *data;

@end
