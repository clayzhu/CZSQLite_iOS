//
//  ViewController.m
//  CZSQLiteDemo
//
//  Created by Clay Zhu on 2017/8/3.
//  Copyright © 2017年 Clay Zhu. All rights reserved.
//

#import "ViewController.h"
#import "CZSQLiteHelper.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    CZSQLiteHelper *czSQLiteHelper = [CZSQLiteHelper sharedManager];
    [czSQLiteHelper createDB];
    [czSQLiteHelper createTable];
//    // 插入一个数据
//    PersonModel *person = [PersonModel modelWithName:@"Tom" age:20];
//    [czSQLiteHelper insertPerson:person];
    // 批量插入多个数据
    NSMutableArray<PersonModel *> *ma = [NSMutableArray array];
    for (NSUInteger i = 0; i < 5; i ++) {
        PersonModel *model = [PersonModel modelWithName:@"Tom" age:20 + i];
        [ma addObject:model];
    }
    [czSQLiteHelper insertPersons:ma];
    // 查询所有数据
    NSArray<NSDictionary *> *queryResults = [czSQLiteHelper queryPersons];
    NSLog(@"queryResults insert:%@", queryResults);
//    // 更新一个数据
//    [czSQLiteHelper updateName:@"Tom 22" whereAge:[NSNumber numberWithInteger:22]];
    // 批量更新多个数据
    NSMutableArray<NSString *> *newNameMA = [NSMutableArray arrayWithCapacity:queryResults.count];
    NSMutableArray<NSNumber *> *conditionAgeMA = [NSMutableArray arrayWithCapacity:queryResults.count];
    for (NSDictionary *oldResult in queryResults) {
        NSInteger age = [oldResult[@"age"] integerValue];
        [newNameMA addObject:[oldResult[@"name"] stringByAppendingFormat:@" %@", @(age)]];
        [conditionAgeMA addObject:[NSNumber numberWithInteger:age]];
    }
    [czSQLiteHelper updateNames:newNameMA whereAges:conditionAgeMA];
    // 查询所有数据
    NSArray<NSDictionary *> *queryResults2 = [czSQLiteHelper queryPersons];
    NSLog(@"queryResults update:%@", queryResults2);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
