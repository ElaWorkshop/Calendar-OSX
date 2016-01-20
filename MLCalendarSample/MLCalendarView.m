//
//  MLCalendarPopup.m
//  ModernLookOSX
//
//  Created by András Gyetván on 2015. 03. 08..
//  Copyright (c) 2015. DroidZONE. All rights reserved.
//

#import "MLCalendarView.h"
#import "MLCalendarCell.h"
#import "MLCalendarBackground.h"

@interface MLCalendarView ()

@property (weak) IBOutlet NSTextField *calendarTitle;
- (IBAction)nextMonth:(id)sender;
- (IBAction)prevMonth:(id)sender;

@property (strong) NSMutableArray* dayLabels;
@property (strong) NSMutableArray* dayCells;
//@property (nonatomic, strong) NSDate* date;

- (id) viewByID:(NSString*)_id;
- (void) layoutCalendar;
- (void) stepMonth:(NSInteger)dm;
@end

@implementation MLCalendarView

+ (BOOL) isSameDate:(NSDate*)d1 date:(NSDate*)d2 {
	if(d1 && d2) {
		NSCalendar *cal = [NSCalendar currentCalendar];
		unsigned unitFlags = NSCalendarUnitDay | NSCalendarUnitYear | NSCalendarUnitMonth;
		NSDateComponents *components = [cal components:unitFlags fromDate:d1];
		NSInteger ry = components.year;
		NSInteger rm = components.month;
		NSInteger rd = components.day;
		components = [cal components:unitFlags fromDate:d2];
		NSInteger ty = components.year;
		NSInteger tm = components.month;
		NSInteger td = components.day;
		return (ry == ty && rm == tm && rd == td);
	} else {
		return NO;
	}
}

//- (void) setBackgroundColor:(NSColor *)backgroundColor {
//	_backgroundColor = backgroundColor;
//	MLCalendarBackground* bv = (MLCalendarBackground*)self.view;
//	bv.backgroundColor = backgroundColor;
//}

- (instancetype) init {
	self = [super initWithNibName:@"MLCalendarView" bundle:[NSBundle bundleForClass:[self class]]];
	if (self != nil) {
		[self commonInit];
	}
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if(self) {
		[self commonInit];
	}
	return self;
}

- (void) commonInit {
//	self.backgroundColor = [NSColor whiteColor];
	self.textColor = [NSColor labelColor];
	self.selectionColor = [NSColor redColor];
    self.selectionTextColor = [NSColor blackColor];
	self.todayMarkerColor = [NSColor greenColor];
    self.todayTextColor = [NSColor whiteColor];
	self.dayMarkerColor = [NSColor darkGrayColor];
	self.dayCells = [NSMutableArray array];
	for(int i = 0; i < 6; i++) {
		[self.dayCells addObject:[NSMutableArray array]];
	}
	_date = [NSDate date];
}

//- (void) setBackgroundColor:(NSColor *)backgroundColor {
//	_backgroundColor = backgroundColor;
//	MLCalendarBackground* bv = (MLCalendarBackground*)self.view;
//	bv.backgroundColor = backgroundColor;
//}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.dayLabels = [NSMutableArray array];
	for(int i = 1; i < 8; i++) {
		NSString* _id = [NSString stringWithFormat:@"day%d",i];
		NSTextField* d = [self viewByID:_id];
		[self.dayLabels addObject:d];
	}
	for(int row = 0; row < 6;row++) {
		for(int col = 0; col < 7; col++) {
			int i = (row*7)+col+1;
			NSString* _id = [NSString stringWithFormat:@"c%d",i];
			MLCalendarCell* cell = [self viewByID:_id];
			cell.target = self;
			cell.action = @selector(cellClicked:);
			[self.dayCells[row] addObject:cell];
			cell.owner = self;
		}
	}
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	NSArray *days = [df shortStandaloneWeekdaySymbols];
	for(NSInteger i = 0; i < days.count;i++) {
		NSString* day = days[i];
		NSInteger col = [self colForDay:i+1];
		NSTextField* tf = self.dayLabels[col];
		tf.stringValue = day;
	}
//	MLCalendarBackground* bv = (MLCalendarBackground*)self.view;
//	bv.backgroundColor = self.backgroundColor;
    self.date = [NSDate date];
}

- (id) viewByID:(NSString*)_id {
	for (NSView *subview in self.view.subviews) {
		if([subview.identifier isEqualToString:_id]) {
			return subview;
		}
	}
	return nil;
}

- (void) setDate:(NSDate *)date {
    _date = date;
	[self layoutCalendar];

	NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMMYYYY" options:0 locale:[NSLocale currentLocale]];
	NSString *budgetDateSummary = [df stringFromDate:date];
	self.calendarTitle.stringValue = budgetDateSummary;
}

- (void) setSelectedDate:(NSDate *)selectedDate {
	_selectedDate = selectedDate;
	for(int row = 0; row < 6;row++) {
		for(int col = 0; col < 7; col++) {
			MLCalendarCell*cell = self.dayCells[row][col];
			BOOL selected = [MLCalendarView isSameDate:cell.representedDate date:_selectedDate];
			cell.selected = selected;
		}
	}
	
}

- (void)cellClicked:(id)sender {
	for(int row = 0; row < 6;row++) {
		for(int col = 0; col < 7; col++) {
			MLCalendarCell*cell = self.dayCells[row][col];
			cell.selected = NO;
		}
	}
	MLCalendarCell* cell = sender;
	cell.selected = YES;
	_selectedDate = cell.representedDate;
	if(self.delegate) {
		if([self.delegate respondsToSelector:@selector(didSelectDate:)]) {
			[self.delegate didSelectDate:self.selectedDate];
		}
	}
}

- (NSDate*) monthDay:(NSInteger)day {
	NSCalendar *cal = [NSCalendar currentCalendar];
	unsigned unitFlags = NSCalendarUnitDay| NSCalendarUnitYear | NSCalendarUnitMonth;
	NSDateComponents *components = [cal components:unitFlags fromDate:_date];
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	comps.day = day;
	comps.year = components.year;
	comps.month = components.month;
	return [cal dateFromComponents:comps];
}

- (NSInteger) lastDayOfTheMonth {
	NSCalendar *cal = [NSCalendar currentCalendar];
	NSRange daysRange = [cal rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:self.date];
	return daysRange.length;
}

- (NSInteger) colForDay:(NSInteger)day {
	NSCalendar *cal = [NSCalendar currentCalendar];
	
	NSInteger idx = day - cal.firstWeekday;
	if(idx < 0) idx = 7 + idx;
	return idx;
}

+ (NSString*) dd:(NSDate*)d {
	NSCalendar *cal = [NSCalendar currentCalendar];
	unsigned unitFlags = NSCalendarUnitDay | NSCalendarUnitYear | NSCalendarUnitMonth;
	NSDateComponents *cpt = [cal components:unitFlags fromDate:d];
	return [NSString stringWithFormat:@"%ld-%ld-%ld",cpt.year, cpt.month, cpt.day];
}

- (void) layoutCalendar {
	if(!self.view) return;
	for(int row = 0; row < 6;row++) {
		for(int col = 0; col < 7; col++) {
			MLCalendarCell*cell = self.dayCells[row][col];
			cell.representedDate = nil;
			cell.selected = NO;
		}
	}
	NSCalendar *cal = [NSCalendar currentCalendar];
	unsigned unitFlags = NSCalendarUnitWeekday;
	NSDateComponents *components = [cal components:unitFlags fromDate:[self monthDay:1]];
	NSInteger firstDay = components.weekday;
	NSInteger numDays = [self lastDayOfTheMonth];
	NSInteger colOfFirstDay = [self colForDay:firstDay];
	NSInteger day = 1 - colOfFirstDay;
	for (int row = 0; row < 6; row++) {
		for (int col = 0; col < 7; col++) {
            MLCalendarCell *cell = self.dayCells[row][col];
            NSDate *d = [self monthDay:day];
            cell.representedDate = d;
            BOOL selected = [MLCalendarView isSameDate:d date:_selectedDate];
            cell.selected = selected;
            cell.isInCurrentMonth = (day >= 1 && day <= numDays);
            day += 1;
		}
	}
}

- (void) stepMonth:(NSInteger)dm {
	NSCalendar *cal = [NSCalendar currentCalendar];
	unsigned unitFlags = NSCalendarUnitDay| NSCalendarUnitYear | NSCalendarUnitMonth;
	NSDateComponents *components = [cal components:unitFlags fromDate:self.date];
	NSInteger month = components.month + dm;
	NSInteger year = components.year;
	if(month > 12) {
		month = 1;
		year++;
	};
	if(month < 1) {
		month = 12;
		year--;
	}
	components.year = year;
	components.month = month;
	self.date = [cal dateFromComponents:components];
}

- (IBAction)nextMonth:(id)sender {
	[self stepMonth:1];
}

- (IBAction)prevMonth:(id)sender {
	[self stepMonth:-1];
}

@end
