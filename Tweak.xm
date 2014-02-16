@interface WBContact : NSObject
@property(retain, nonatomic) NSString *screenName;
@property(readonly, nonatomic) BOOL isFollower;
@end

@interface WBUser : WBContact
@property(nonatomic) unsigned int gender; // 1代表程序猿，0代表程序媛
@end

@interface WBTimelineItem : NSObject
@property(retain, nonatomic) NSString *text;
@property(retain, nonatomic) WBUser *user;
@end

@interface WBUniversalStatus : WBTimelineItem
@end

@interface WBStatus : WBUniversalStatus
@end

@interface WBStatusBusinessViewController : UIViewController
{
	NSMutableArray *list;
}
@property(nonatomic) BOOL hasMore;
- (void)loadMoreData;
@end

@interface WBRepostListViewController : WBStatusBusinessViewController
@end

%hook WBRepostListViewController
%new
- (void)iOSRELoadMoreReposts:(NSTimer *)refreshTimer
{
	if ([self hasMore]) [self loadMoreData];
	else
	{
		[refreshTimer invalidate];

		// 开始抽奖倒计时 :)
		[NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(iOSRELottery:) userInfo:nil repeats:YES];
	}
}

%new
- (void)iOSRELottery:(NSTimer *)lotteryTimer
{
	// 设定抽奖截止时间
	NSDateComponents *components = [[NSDateComponents alloc] init];
	[components setYear:2014];
	[components setMonth:2];
	[components setDay:17];
	[components setHour:12];
	[components setMinute:0];
	[components setSecond:0];
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDate *deadline = [gregorian dateFromComponents:components];
	[components release];
	[gregorian release];

	// 获取当前时间
	NSDate *now = [NSDate date];

	// 截止时间到！
	if ([now compare:deadline] == NSOrderedDescending)
	{
		// 停止抽奖倒计时 :(
		[lotteryTimer invalidate];

		// 获取所有转发
		NSMutableArray *list = MSHookIvar<NSMutableArray *>(self, "list");
		if ([list count] == 0)
		{
			NSLog(@"iOSRE: 人气太低，活动取消 :(");
			return;
		}

		NSLog(@"iOSRE: 经iOSRELottery统计，参与转发抽奖的一共有%lu位朋友。感谢大家的支持！下面开始开奖喽！", (unsigned long)[list count]);

		NSMutableArray *deduplicateArray = [NSMutableArray arrayWithCapacity:5];

		// 抽出5名获奖者
		for (int i = 0; i < 5; i++)
		{
			// 生成随机数
			NSUInteger winnerIndex = (NSUInteger)arc4random_uniform([list count]);

			// 确保随机数没出现过
			if ([deduplicateArray containsObject:[NSNumber numberWithUnsignedLong:(unsigned long)winnerIndex]])
			{
				i--;
				continue;
			}
			else [deduplicateArray addObject:[NSNumber numberWithUnsignedLong:(unsigned long)winnerIndex]];

			// 获取转发者名字
			WBStatus *status = [list objectAtIndex:winnerIndex];
			WBUser *user = [status user];
			NSString *userName = [user screenName];

			if ([userName isEqualToString:@"hangcom2010"] || [userName isEqualToString:@"iOS应用逆向工程"] || [userName isEqualToString:@"Me"] || [userName isEqualToString:@"我"])
			{
				NSLog(@"iOSRE: 裁判不准参与比赛啊！");
				i--;
				continue;
			}

			// 获取微博内容
			NSString *weiboText = [status text];
			if ([weiboText rangeOfString:@"//@"].location != NSNotFound) weiboText = [weiboText substringToIndex:[weiboText rangeOfString:@"//@"].location];

			// 关注@iOS应用逆向工程
			if (![user isFollower])
			{
				NSLog(@"iOSRE: @%@，你没有关注@iOS应用逆向工程 啊，可惜~", userName);
				i--;
				continue;
			}

			// 爱特3人以上
			NSError *error = nil;
			NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^.*@.*@.*@.*$" options:NSRegularExpressionCaseInsensitive error:&error];
			if (error)
			{
				NSLog(@"iOSRE: 正则表达式出错了，错误是%@", [error localizedDescription]);
				i--;
				continue;
			}

			NSUInteger numberOfMatches = [regex numberOfMatchesInString:weiboText options:0 range:NSMakeRange(0, [weiboText length])];
			if (numberOfMatches == 0)
			{
				NSLog(@"iOSRE: @%@，你没有爱特够3个人啊，可惜~", userName);
				i--;
				continue;
			}

			NSLog(@"iOSRE: 第%d位中奖的朋友是“@%@”，%@的转发内容是“%@”。%@将获得《iOS应用逆向工程》一本，恭喜%@！", i + 1, userName, [user gender] == 1 ? @"他" : @"她", weiboText, [user gender] == 1 ? @"他" : @"她", [user gender] == 1 ? @"他" : @"她");
		}

		NSLog(@"iOSRE: 5位朋友已经全数抽出，感谢大家热情参与！iOSRE团队后续还会有更多动作，誓为提高中国iOS开发者的整体技术水平贡献自己的微薄之力，敬请期待！谢谢！");
	}
}

- (void)viewDidLoad // 点进一条微博，此函数得到调用
{
	%orig;

	// 加载所有转发
	[NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(iOSRELoadMoreReposts:) userInfo:nil repeats:YES];
}
%end
