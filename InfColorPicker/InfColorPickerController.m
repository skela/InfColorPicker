//==============================================================================
//
//  MainViewController.m
//  InfColorPicker
//
//  Created by Troy Gaul on 7 Aug 2010.
//
//  Copyright (c) 2011 InfinitApps LLC - http://infinitapps.com
//	Some rights reserved: http://opensource.org/licenses/MIT
//
//==============================================================================

#import "InfColorPickerController.h"

#import <objc/runtime.h>

#import "InfColorBarPicker.h"
#import "InfColorSquarePicker.h"
#import "InfHSBSupport.h"

#define kNibName @"InfColorPickerView"

//------------------------------------------------------------------------------

static void HSVFromUIColor( UIColor* color, float* h, float* s, float* v )
{
	CGColorRef colorRef = [ color CGColor ];
	
	const CGFloat* components = CGColorGetComponents( colorRef );
	size_t numComponents = CGColorGetNumberOfComponents( colorRef );
	
	CGFloat r, g, b;
	if( numComponents < 3 ) {
		r = g = b = components[ 0 ];
	}
	else {
		r = components[ 0 ];
		g = components[ 1 ];
		b = components[ 2 ];
	}
	
	RGBToHSV( r, g, b, h, s, v, YES );
}

//==============================================================================

@interface InfColorPickerController()

- (void) updateResultColor;

// Outlets and actions:

- (IBAction) takeBarValue: (id) sender;
- (IBAction) takeSquareValue: (id) sender;
- (IBAction) takeBackgroundColor: (UIView*) sender;
- (IBAction) done: (id) sender;

@end

//==============================================================================

@implementation InfColorPickerController

//------------------------------------------------------------------------------

@synthesize delegate, resultColor, sourceColor;
@synthesize barView, squareView;
@synthesize barPicker, squarePicker;
@synthesize sourceColorView,  resultColorView;
@synthesize topStrip;

//------------------------------------------------------------------------------
#pragma mark	Class methods
//------------------------------------------------------------------------------

+ (InfColorPickerController*) colorPickerViewController
{
	return [ [ [ self alloc ] initWithNibName:kNibName bundle: nil ] autorelease ];
}

//------------------------------------------------------------------------------
#pragma mark	Memory management
//------------------------------------------------------------------------------

- (void) dealloc
{
	[ barView release ];
	[ squareView release ];
	[ barPicker release ];
	[ squarePicker release ];
	[ sourceColorView release ];
	[ resultColorView release ];
	[ topStrip release ];
    
	[ sourceColor release ];
	[ resultColor release ];
	
	[ super dealloc ];
}

//------------------------------------------------------------------------------
#pragma mark	Creation
//------------------------------------------------------------------------------

- (void)commonInit
{
    self.navigationItem.title = NSLocalizedString( @"Set Color",
                                                  @"InfColorPicker default nav item title" );
    self.idealSizeForViewInPopover = CGSizeMake( 256 + ( 1 + 20 ) * 2, 420 );
}

- (id) initWithNibName: (NSString*) nibNameOrNil bundle: (NSBundle*) nibBundleOrNil
{
	self = [ super initWithNibName: nibNameOrNil bundle: nibBundleOrNil ];
	if( self )
    {
		[self commonInit];
	}
	return self;
}

- (id) initWithSize:(CGSize)size
{
    self = [self initWithNibName:kNibName bundle:nil];
    if (self)
    {
        self.idealSizeForViewInPopover = size;
    }
    return self;
}

//------------------------------------------------------------------------------

- (void) viewDidLoad
{
	[ super viewDidLoad ];

	self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

	barPicker.value = hue;
	squareView.hue = hue;
	squarePicker.hue = hue;
	squarePicker.value = CGPointMake( saturation, brightness );

	if( sourceColor )
		sourceColorView.backgroundColor = sourceColor;
	
	if( resultColor )
		resultColorView.backgroundColor = resultColor;
}

//------------------------------------------------------------------------------

- (void) viewDidUnload
{
	[ super viewDidUnload ];
	
	// Release any retained subviews of the main view.
	
	self.barView = nil;
	self.squareView = nil;
	self.barPicker = nil;
	self.squarePicker = nil;
	self.sourceColorView = nil;
	self.resultColorView = nil;
    self.topStrip = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.resultIsFinal = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.resultIsFinal = YES;
    
    [self informDelegateDidChangeColor];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    CGFloat x = 10;
    CGFloat w = self.view.bounds.size.width - 2*x;
    
    CGFloat sy = self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height;
    sy = 10;

    CGRect f = self.topStrip.frame;
    f.origin.y=sy;
    self.topStrip.frame=f;
    
    CGRect bp = self.barPicker.frame;
    bp = CGRectMake(x,self.view.bounds.size.height-bp.size.height-10,w,bp.size.height);
    self.barPicker.frame = bp;
    
    CGFloat y = f.origin.y + f.size.height + 10;
    CGFloat h = bp.origin.y - 10 - y;
    
    self.squarePicker.frame = CGRectMake(x,y,w,h);
}

- (UIRectEdge)edgesForExtendedLayout
{
    return UIRectEdgeNone;
}

- (BOOL)extendedLayoutIncludesOpaqueBars
{
    return YES;
}

//------------------------------------------------------------------------------

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
	return interfaceOrientation == UIInterfaceOrientationPortrait;
}

//------------------------------------------------------------------------------

- (void) presentModallyOverViewController: (UIViewController*) controller
{
	UINavigationController* nav = [ [ [ UINavigationController alloc ] initWithRootViewController: self ] autorelease ];
	
	nav.navigationBar.barStyle = UIBarStyleBlackOpaque;
	
	self.navigationItem.rightBarButtonItem = [ [ [ UIBarButtonItem alloc ] initWithBarButtonSystemItem: UIBarButtonSystemItemDone target: self action: @selector( done: ) ] autorelease ];
				
	[ controller presentViewController: nav animated: YES completion:nil ];
}

//------------------------------------------------------------------------------
#pragma mark	IB actions
//------------------------------------------------------------------------------

- (IBAction) takeBarValue: (InfColorBarPicker*) sender
{
	hue = sender.value;
	
	squareView.hue = hue;
	squarePicker.hue = hue;
	
	[ self updateResultColor ];
}

//------------------------------------------------------------------------------

- (IBAction) takeSquareValue: (InfColorSquarePicker*) sender
{
	saturation = sender.value.x;
	brightness = sender.value.y;

	[ self updateResultColor ];
}

//------------------------------------------------------------------------------

- (IBAction) takeBackgroundColor: (UIView*) sender
{
	self.resultColor = sender.backgroundColor;
}

//------------------------------------------------------------------------------

- (IBAction) done: (id) sender
{
    if ([(id)self.delegate respondsToSelector:@selector(colorPickerControllerDidFinish:)])
        [self.delegate colorPickerControllerDidFinish:self];
    else
        [self dismissViewControllerAnimated:YES completion:nil];
}

//------------------------------------------------------------------------------
#pragma mark	Properties
//------------------------------------------------------------------------------

- (void) informDelegateDidChangeColor
{
	if(self.delegate && [(id)self.delegate respondsToSelector:@selector(colorPickerControllerDidChangeColor:)])
		[self.delegate colorPickerControllerDidChangeColor:self];
    else
    {
        void (^block)(InfColorPickerController*picker) = objc_getAssociatedObject(self, "changedBlock");
        if (block!=NULL)
        {
            block(self);
        }
    }
}

- (void)setChangedBlock:(void (^)(InfColorPickerController *picker))block
{
    objc_setAssociatedObject(self, "changedBlock", [block copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//------------------------------------------------------------------------------

- (void) updateResultColor
{
	// This is used when code internally causes the update.  We do this so that
	// we don't cause push-back on the HSV values in case there are rounding
	// differences or anything.  However, given protections from hue and sat
	// changes when not necessary elsewhere it's probably not actually needed.
	
	[ self willChangeValueForKey: @"resultColor" ];
	
	[ resultColor release ];
	resultColor = [ [ UIColor colorWithHue: hue saturation: saturation 
								brightness: brightness alpha: 1.0f ] retain ];
	
	[ self didChangeValueForKey: @"resultColor" ];
	
	resultColorView.backgroundColor = resultColor;
	
	[ self informDelegateDidChangeColor ];
}

//------------------------------------------------------------------------------

- (void) setResultColor: (UIColor*) newValue
{
	if( ![ resultColor isEqual: newValue ] ) {
		[ resultColor release ];
		resultColor = [ newValue retain ];
		
		float h = hue;
		HSVFromUIColor( newValue, &h, &saturation, &brightness );
		
		if( h != hue ) {
			hue = h;
			
			barPicker.value = hue;
			squareView.hue = hue;
			squarePicker.hue = hue;
		}
		
		squarePicker.value = CGPointMake( saturation, brightness );

		resultColorView.backgroundColor = resultColor;

		[ self informDelegateDidChangeColor ];
	}
}

//------------------------------------------------------------------------------

- (void) setSourceColor: (UIColor*) newValue
{
	if( ![ sourceColor isEqual: newValue ] ) {
		[ sourceColor release ];
		sourceColor = [ newValue retain ];
		
		sourceColorView.backgroundColor = sourceColor;
		
		self.resultColor = newValue;
	}
}

//------------------------------------------------------------------------------
#pragma mark	UIViewController( UIPopoverController ) methods
//------------------------------------------------------------------------------

- (CGSize) contentSizeForViewInPopover
{
	return [self idealSizeForViewInPopover ];
}

- (CGSize) preferredContentSize
{
    return [self idealSizeForViewInPopover ];
}

//------------------------------------------------------------------------------

@end

//==============================================================================
