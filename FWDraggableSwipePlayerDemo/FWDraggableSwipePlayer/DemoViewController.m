//
//  DemoViewController.m
//  FWDraggableSwipePlayer
//
//  Created by Filly Wang on 20/1/15.
//  Copyright (c) 2015 Filly Wang. All rights reserved.
//

#import "DemoViewController.h"
#import "FWSwipePlayerConfig.h"
#import "MovieDetailView.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface DemoViewController ()
{
    NSMutableArray *list;
    BOOL shouldRotate;
    FWSwipePlayerViewController *playerController;
}

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.listView.delegate = self;
    self.listView.dataSource = self;
    
    shouldRotate = NO;
    
    NSString *path=[[NSBundle mainBundle] pathForResource:@"list" ofType:@"json"];
    NSData *listData=[NSData dataWithContentsOfFile:path];
    list = [NSJSONSerialization JSONObjectWithData:listData options:NSJSONReadingMutableLeaves error:nil];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [list count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tablecell"];
    
    if(cell==nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"tablecell"];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = list[[indexPath row]][@"title"];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if([indexPath row] == 0)
    {
        if(self.playerManager == nil)
        {
            FWSwipePlayerConfig *config = [[FWSwipePlayerConfig alloc]init];
            self.playerManager = [[FWDraggablePlayerManager alloc]initWithList:list Config:config];
        }
        else
            [self.playerManager updateInfo:list[[indexPath row]]];
        
        MovieDetailView *detailView = [[MovieDetailView alloc]initWithFrame:self.view.frame];
        [detailView initWithInfo:list[[indexPath row]]];
        
         [[NSNotificationCenter defaultCenter] addObserver:self
         selector:@selector(handleSwipePlayerViewStateChange:)
         name:FWSwipePlayerViewStateChange object:nil];
        
        [self.playerManager showAtViewAndPlay:self.view];
        
        if(playerController != nil)
        {
            [playerController.moviePlayer stopAndRemove];
            playerController = nil;
        }
        self.listView.frame = CGRectMake(0, 0, self.listView.frame.size.width, self.view.frame.size.height);
        
    }
    else
    {
        if(self.playerManager)
        {
            [self.playerManager exit];
            self.playerManager = nil;
        }
        
        playerController =  [[FWSwipePlayerViewController alloc]init];
        FWSwipePlayerConfig *config = [[FWSwipePlayerConfig alloc]init];

        NSMutableArray *dataList = [[NSMutableArray alloc]init] ;

        for(int i = (int)[indexPath row] ; i < [list count]; ++i)
        {
            [dataList addObject:list[i]];
        }
        
        config.draggable = NO;
        [playerController updateMoviePlayerWithVideoList:dataList Config:config];
        playerController.moviePlayer.delegate = self;
        [playerController attachTo:self];
        [playerController playStartAt:200];
        self.listView.frame = CGRectMake(0, playerController.moviePlayer.view.frame.size.height, self.listView.frame.size.width, self.view.frame.size.height - playerController.moviePlayer.view.frame.size.height);

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleSwipePlayerViewStateChange:)
                                                     name:FWSwipePlayerViewStateChange object:nil];

        [[NSNotificationCenter defaultCenter] postNotificationName:FWSwipePlayerViewStateChange object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],@"isSmall",[NSNumber numberWithBool:NO],@"isLock",nil] ];
    }
}

#pragma mark notification
-(void)handleSwipePlayerViewStateChange:(NSNotification *)notity
{
    BOOL isSmall = [[[notity userInfo] valueForKey:@"isSmall"] boolValue];
    BOOL isLock = [[[notity userInfo] valueForKey:@"isLock"] boolValue];
    
    if(isSmall || isLock)
        shouldRotate = NO;
    else if(!isLock && !isSmall)
        shouldRotate = YES;
    else
        shouldRotate = NO;
}

#pragma mark
-(void)doneBtnOnClick:(id)sender
{
    [self exitPlayer];
    [self setOrientation:UIDeviceOrientationPortrait];
    [[NSNotificationCenter defaultCenter] postNotificationName:FWSwipePlayerViewStateChange object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],@"isSmall",[NSNumber numberWithBool:NO],@"isLock",nil] ];
    
    self.listView.frame = CGRectMake(0, 0, self.listView.frame.size.width, self.view.frame.size.height);
}

- (void)exitPlayer
{
    if(playerController)
    {
        [playerController stopAndRemove];
        playerController = nil;
    }
}

- (void)setOrientation:(int)orientation
{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

#pragma mark rotata

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return shouldRotate;
}

- (BOOL)shouldAutorotate
{
    return shouldRotate;
}

- (NSUInteger)supportedInterfaceOrientations
{
     return UIInterfaceOrientationMaskAll;
}

@end
