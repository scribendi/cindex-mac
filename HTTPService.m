//
//  HTTPService.m
//  Cindex
//
//  Created by Peter Lennie on 6/12/08; modified 5/7/18
//  Copyright 2008 Indexing Research. All rights reserved.
//

#import "HTTPService.h"
#import "MessageController.h"
#import "commandutils.h"

static NSString * _urlstring = @"https://storage.googleapis.com/indexres-d3231811-9b04-47b0-8756-5da84afef700/downloads/versionupdate.json";

@implementation HTTPService

- (void)check:(id)sender {
#if 1
	_data = [NSMutableData data];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:_urlstring]];
	
	[NSURLConnection connectionWithRequest:request delegate:self];
#endif
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_data appendData:data];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection	{
	NSError * error = nil;
//	NSString * xs = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
//	NSDictionary * pdic = [NSPropertyListSerialization propertyListWithData:_data options:NSPropertyListImmutable format:nil error:&error];
	NSDictionary * pdic = [NSJSONSerialization JSONObjectWithData:_data options:kNilOptions error:&error];
	if (!error) {
		NSDateFormatter * df = [[NSDateFormatter alloc] init];
		df.dateFormat = @"y-M-d";
		int minVersion = [[pdic objectForKey:@"minVersion"] intValue];
		int maxVersion = [[pdic objectForKey:@"maxVersion"] intValue];
		int versionType = [[pdic objectForKey:@"versionType"] intValue];
		NSDate * startDate = [df dateFromString:[pdic objectForKey:@"startDate"]];
		NSDate * endDate = [df dateFromString:[pdic objectForKey:@"endDate"]];

		if (CINVERSION >= minVersion && CINVERSION <= maxVersion && versionType&U_MAC) {	// if potentially eligible for message
			if ([startDate timeIntervalSinceNow] < 0 && [endDate timeIntervalSinceNow]  > 0)	 {	// if within date range
				NSDate * lastCheck = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastCheck"];
				if (!lastCheck || [[NSDate date] timeIntervalSinceDate:lastCheck] > 86400 * 14) {	// show message every 14 days
//					MessageController * mc = [[MessageController alloc] initWithURL:[pdic objectForKey:@"url"]];
					if (NSRunInformationalAlertPanel([pdic objectForKey:@"messageTitle"],@"%@",@"Learn More…", @"Cancel",nil,[pdic objectForKey:@"message"])) {	// display info string with option
						[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[pdic objectForKey:@"url"]]];
					}
					[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastCheck"];
				}
			}
		}
	}
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"Connection Failed");
}
@end
