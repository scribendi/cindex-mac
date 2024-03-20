//
//  NIRPrintAccessoryController.m
//  Cindex
//
//  Created by Peter Lennie on 4/15/18.
//

#import "IRPrintAccessoryController.h"
#import "commandutils.h"

@interface IRPrintAccessoryController () {
	__weak IRIndexDocument * doc;
}
@property (strong) IBOutlet NSMatrix * rangeType;
@property (strong) IBOutlet NSTextField * rangeStart;
@property (strong) IBOutlet NSTextField * rangeEnd;

@end

@implementation IRPrintAccessoryController

#if 0
+ (NSSet *)keyPathsForValuesAffectingFirstRecord {
	return [NSSet setWithObjects:@"rangeType", @"rangeStart", @"rangeEnd",nil];
}
+ (NSSet *)keyPathsForValuesAffectingLastRecord {
	return [NSSet setWithObjects:@"rangeType", @"rangeStart", @"rangeEnd",nil];
}
#endif
- (instancetype)initForDocument:(IRIndexDocument *)document	{
	if (self = [super initWithNibName:@"IRPrintAccessoryController" bundle:nil]) {
		doc = document;
	}
	return self;
}
- (NSSet *)keyPathsForValuesAffectingPreview {
	return [NSSet setWithObjects:@"firstRecord", @"lastRecord",nil];
}
- (void)viewDidLoad {
    [super viewDidLoad];
	[_rangeType cellWithTag:1].enabled = [doc selectedRecords].length;
	[self printOptionChanged:nil];
	doc.iIndex->pf.lastrec = UINT_MAX;
}
- (NSArray<NSDictionary<NSPrintPanelAccessorySummaryKey,NSString *> *> *)localizedSummaryItems {
	NSString * rType;
	switch (_rangeType.selectedCell.tag) {
		case 0: rType = @"All records in the current view";
			break;
		case 1: rType = @"Selected Records";
			break;
		case 2: rType = @"Records in a specified range";
			break;
	}
	return [NSArray arrayWithObjects:
		[NSDictionary dictionaryWithObjectsAndKeys:@"Which Records To Print", NSPrintPanelAccessorySummaryItemNameKey, rType, NSPrintPanelAccessorySummaryItemDescriptionKey, nil],
		[NSDictionary dictionaryWithObjectsAndKeys:@"The First Record To Print", NSPrintPanelAccessorySummaryItemNameKey, @"First Record", NSPrintPanelAccessorySummaryItemDescriptionKey, nil],
		[NSDictionary dictionaryWithObjectsAndKeys:@"The Last Record To Print", NSPrintPanelAccessorySummaryItemNameKey, @"First Record", NSPrintPanelAccessorySummaryItemDescriptionKey, nil],
		nil];
}
- (void)controlTextDidChange:(NSNotification *)note	{
	NSTextField * control = [note object];
	if (control.stringValue.length)
		[_rangeType selectCellWithTag:2];
	if (control == _rangeStart && !_rangeEnd.stringValue.length)
		[self printOptionChanged:control];
}
- (void)controlTextDidEndEditing:(NSNotification *)note	{
	NSTextField * control = [note object];
	[self printOptionChanged:control];
}
-(IBAction)printOptionChanged:(id)sender {
	memset(&doc.iIndex->pf,0,sizeof(PRINTFORMAT));
	if (com_getrecrange(doc.iIndex,_rangeType.selectedCell.tag, _rangeStart, _rangeEnd,&doc.iIndex->pf.firstrec, &doc.iIndex->pf.lastrec))	{	// if bad range
		[self.view.window makeFirstResponder:sender];
		return;
	}
	self.firstRecord = doc.iIndex->pf.firstrec;
	self.lastRecord = doc.iIndex->pf.lastrec;
}
@end
