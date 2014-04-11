//
//  SQLiteRootViewController.m
//  SQLiteSample
//
//  Created by 姚卓禹 on 14-4-7.
//  Copyright (c) 2014年 姚卓禹. All rights reserved.
//

#import "SQLiteRootViewController.h"
#import "sqlite3.h"

@interface SQLiteRootViewController ()
{
    sqlite3 *db;
    NSString *firstTableName;
}

@end

@implementation SQLiteRootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    firstTableName = @"firstTable";
    
    [self sqliteTest];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark - sqlite function

- (void)sqliteTest
{
    BOOL openFlag = [self openDB];
    if (!openFlag) {
        return;
    }
    
    do {
        BOOL createFlag = [self createTableWith:firstTableName];
        if (!createFlag) {
            break;
        }
        
        if (![self findCString:@"testA"]) {
            //插入数据
            [self insertValueWithB:200 textC:@"testA" isLastInsert:NO];
            [self insertValueWithB:201 textC:@"testB" isLastInsert:NO];
            [self insertValueWithB:202 textC:@"testC" isLastInsert:NO];
            [self insertValueWithB:203 textC:@"testD" isLastInsert:NO];
            [self insertValueWithB:204 textC:@"testE" isLastInsert:YES];
        }
        
        //查询数据
        [self selectAllData];
        
        NSLog(@">>>>>>%@ row count is %d", firstTableName, [self getRowCountOfTable:firstTableName]);
        
        //[self selectSingleColumnTest];
        
        NSLog(@"************************************************");
        NSLog(@"测试transaction");
        [self testSimpleTransactionAndRollBack];
        [self testSimpleTransactionAndCommit];
        
        
    } while (0);
    
    
    
    if (openFlag) {
        [self closeDB];
    }
}


- (NSString *)sqliteFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = [paths objectAtIndex:0];
    return [documentDir stringByAppendingPathComponent:@"test.db"];
}


- (BOOL)openDB
{
    //没有数据库文件会自动创建，存在的话打开
//    if (sqlite3_open_v2([[self sqliteFilePath] UTF8String], &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, NULL) != SQLITE_OK) {
//        NSLog(@"打开数据库失败， %s",sqlite3_errmsg(db));
//        sqlite3_close(db);
//        return NO;
//    }
    if (sqlite3_open([[self sqliteFilePath] UTF8String], &db) != SQLITE_OK) {
        NSLog(@"打开数据库失败， %s",sqlite3_errmsg(db));
        sqlite3_close(db);
        return NO;
    }
    
    return YES;
}

- (void)closeDB
{
    sqlite3_close(db);
}

- (BOOL)createTableWith:(NSString *)tableName
{
    sqlite3_stmt *createStmt = NULL;
    NSString *createTableSql = [NSString stringWithFormat:@"create table if not exists %@ (a INTEGER PRIMARY KEY AUTOINCREMENT, b INTEGER, c TEXT)", tableName];
    if (sqlite3_prepare_v2(db, [createTableSql UTF8String], -1, &createStmt, NULL) != SQLITE_OK) {
        NSLog(@"prepare sql 失败， %s",sqlite3_errmsg(db));
        return NO;
    }
    
    BOOL successed = NO;
    int rc = sqlite3_step(createStmt);
    if (rc != SQLITE_DONE) {
        successed = NO;
        NSLog(@"step sql 失败， %s , %d",sqlite3_errmsg(db), rc);
    }
    sqlite3_finalize(createStmt);
    successed = YES;
    return successed;
}

- (BOOL)deleteRowIfValueB:(NSUInteger)bInteger
{
    return YES;
}

- (BOOL)insertValueWithB:(NSInteger)bInteger textC:(NSString *)cString isLastInsert:(BOOL)isLastInsert
{
    static sqlite3_stmt *insertStatement;
    BOOL successed = NO;
    if (!insertStatement) {
        NSString *insertSql = [NSString stringWithFormat:@"insert into %@ values (NULL, ?, ?)", firstTableName];
        if (sqlite3_prepare_v2(db, [insertSql UTF8String], -1, &insertStatement, NULL) != SQLITE_OK) {
            NSLog(@"prepare insert sql 失败， %s",sqlite3_errmsg(db));
            return NO;
        }
    }
    
    sqlite3_bind_int(insertStatement, 1, bInteger);
    sqlite3_bind_text(insertStatement, 2, [cString UTF8String], -1, SQLITE_STATIC);
    
    if (sqlite3_step(insertStatement) != SQLITE_DONE) {
        NSLog(@"insert data 失败 %s", sqlite3_errmsg(db));
        sqlite3_finalize(insertStatement);
        return NO;
    }
    
    if (!isLastInsert) {
        sqlite3_reset(insertStatement);
    }else{
        sqlite3_finalize(insertStatement);
        insertStatement = nil;
    }
    return successed;
    
}

- (void)selectAllData
{
    NSString *sql = [NSString stringWithFormat:@"select * from %@", firstTableName];
    sqlite3_stmt *selectStatement;
    
    if (sqlite3_prepare_v2(db, [sql UTF8String], -1, &selectStatement, NULL) != SQLITE_OK) {
        NSLog(@"select data prepare sql 失败 %s", sqlite3_errmsg(db));
        return;
    }
    NSLog(@"all data in db >>>>>>>>>>>>>>>>");
    while (sqlite3_step(selectStatement) == SQLITE_ROW) {
        NSInteger aInt = sqlite3_column_int(selectStatement, 0);
        NSInteger bInt = sqlite3_column_int(selectStatement, 1);
        NSString *cString = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(selectStatement, 2)];
        NSLog(@"a :%d, b :%d, c :%@",aInt, bInt, cString);
    }
    
    sqlite3_finalize(selectStatement);
}

- (BOOL)findCString:(NSString *)cString
{
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where c='%@'", firstTableName, cString];
    sqlite3_stmt *selectStatement;
    
    if (sqlite3_prepare_v2(db, [sql UTF8String], -1, &selectStatement, NULL) != SQLITE_OK) {
        NSLog(@"select data prepare sql 失败 %s", sqlite3_errmsg(db));
        return NO;
    }
    
//    NSLog(@">>>>>> 测试sqlite3_column_name 0 , %s", sqlite3_column_name(selectStatement, 0));
//    NSLog(@">>>>>> 测试sqlite3_column_name 1 , %s", sqlite3_column_name(selectStatement, 1));
//    NSLog(@">>>>>> 测试sqlite3_column_name 2 , %s", sqlite3_column_name(selectStatement, 2));
    //  结果 a, b, c
    
    NSLog(@">>>>> sqlite3_column_count: %d", sqlite3_column_count(selectStatement));
    //  结果为3.
    
    BOOL res = NO;
    
    if (sqlite3_step(selectStatement) == SQLITE_ROW) {
        
        NSLog(@">>>>> sqlite3_data_count: %d", sqlite3_data_count(selectStatement));
        
        NSInteger aInt = sqlite3_column_int(selectStatement, 0);
        NSInteger bInt = sqlite3_column_int(selectStatement, 1);
        NSString *cString_ = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(selectStatement, 2)];
        NSLog(@">>>>>find c = %@ , is a :%d, b :%d, c :%@", cString,aInt, bInt, cString_);
        res = YES;
    }else{
        res = NO;
    }
    sqlite3_finalize(selectStatement);
    return res;
}


- (void)selectSingleColumnTest
{
    NSString *sql = [NSString stringWithFormat:@"select a from %@ where c='%@'", firstTableName, @"testA"];
    sqlite3_stmt *selectStatement;
    
    if (sqlite3_prepare_v2(db, [sql UTF8String], -1, &selectStatement, NULL) != SQLITE_OK) {
        NSLog(@"select data prepare sql 失败 %s", sqlite3_errmsg(db));
        return;
    }
    
    NSLog(@">>>>>> 测试sqlite3_column_name 0 , %s", sqlite3_column_name(selectStatement, 0));
    //  结果 a
    
    NSLog(@">>>>> sqlite3_column_count: %d", sqlite3_column_count(selectStatement));
    //  结果为1.
    
    BOOL res = NO;
    
    if (sqlite3_step(selectStatement) == SQLITE_ROW) {
        
        NSLog(@">>>>> sqlite3_data_count: %d", sqlite3_data_count(selectStatement));
        //  结果为1.
        
        NSInteger aInt = sqlite3_column_int(selectStatement, 0);
        NSLog(@">>>>>find is a :%d", aInt);
        res = YES;
    }else{
        res = NO;
    }
    sqlite3_finalize(selectStatement);
}


- (int)getRowCountOfTable:(NSString *)tableName
{
    NSString *sql = [NSString stringWithFormat:@"select count(*) from %@", tableName];
    sqlite3_stmt *countStatement;
    
    if (sqlite3_prepare_v2(db, [sql UTF8String], -1, &countStatement, NULL) != SQLITE_OK) {
        NSLog(@"select count prepare sql 失败 %s", sqlite3_errmsg(db));
        return 0;
    }
    
    int count = 0;
    while (sqlite3_step(countStatement) == SQLITE_ROW) {
        count = sqlite3_column_int(countStatement, 0);
    }
    sqlite3_finalize(countStatement);
    return count;
    
}

/////////////////////////////////////////////////////////////////////////////////////

- (BOOL)beginNormalTransaction
{
    NSString *tSql = @"begin exclusive transaction";
    sqlite3_stmt *transactionStatement;
    
    if (sqlite3_prepare_v2(db, [tSql UTF8String], -1, &transactionStatement, NULL) != SQLITE_OK) {
        NSLog(@"transaction prepare sql 失败 %s", sqlite3_errmsg(db));
        return NO;
    }
    
    if (sqlite3_step(transactionStatement) != SQLITE_DONE) {
        NSLog(@"transaction sqlite3 step 失败 %s", sqlite3_errmsg(db));
        return NO;
    }
    sqlite3_finalize(transactionStatement);
    return YES;
}

- (BOOL)rollbackTransaction
{
    NSString *tSql = @"rollback transaction";
    sqlite3_stmt *transactionStatement;
    
    if (sqlite3_prepare_v2(db, [tSql UTF8String], -1, &transactionStatement, NULL) != SQLITE_OK) {
        NSLog(@"rollback prepare sql 失败 %s", sqlite3_errmsg(db));
        return NO;
    }
    
    if (sqlite3_step(transactionStatement) != SQLITE_DONE) {
        NSLog(@"rollback sqlite3 step 失败 %s", sqlite3_errmsg(db));
        return NO;
    }
    sqlite3_finalize(transactionStatement);
    return YES;
}

- (BOOL)commitTransaction
{
    NSString *tSql = @"commit transaction";
    sqlite3_stmt *transactionStatement;
    
    if (sqlite3_prepare_v2(db, [tSql UTF8String], -1, &transactionStatement, NULL) != SQLITE_OK) {
        NSLog(@"commit prepare sql 失败 %s", sqlite3_errmsg(db));
        return NO;
    }
    
    if (sqlite3_step(transactionStatement) != SQLITE_DONE) {
        NSLog(@"commit sqlite3 step 失败 %s", sqlite3_errmsg(db));
        return NO;
    }
    sqlite3_finalize(transactionStatement);
    return YES;
}

- (void)testSimpleTransactionAndRollBack
{
    if (![self beginNormalTransaction]) {
        NSLog(@"beginNormalTransaction failure");
        return;
    }
    
    [self insertValueWithB:300 textC:@"testZ" isLastInsert:NO];
    [self insertValueWithB:301 textC:@"testY" isLastInsert:YES];
    
    if (![self rollbackTransaction]) {
        NSLog(@"rollbackTransaction failure");
        return;
    }
    [self selectAllData];
    
}

- (void)testSimpleTransactionAndCommit
{
    if (![self beginNormalTransaction]) {
        NSLog(@"beginNormalTransaction failure");
        return;
    }
    
    [self insertValueWithB:400 textC:@"testM" isLastInsert:NO];
    [self insertValueWithB:401 textC:@"testN" isLastInsert:YES];
    
    if (![self commitTransaction]) {
        NSLog(@"rollbackTransaction failure");
        return;
    }
    [self selectAllData];
}




























@end
