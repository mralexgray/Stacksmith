//
//  WILDLicensePanelController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 01.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WILDLicensePanelController : NSWindowController
{
@private
    NSTextField			*		mLicenseTextField;
	NSButton			*		mOKButton;
	BOOL						mUserChangedText;
}

@property (retain,nonatomic) IBOutlet NSTextField	*	licenseTextField;
@property (retain,nonatomic) IBOutlet NSButton		*	OKButton;

+(WILDLicensePanelController*)	currentLicensePanelController;	// Returns NIL if no license panel is currently open.

-(NSInteger)	runModal;

-(IBAction)	doOK: (id)sender;
-(IBAction)	doCancel: (id)sender;

-(void)	setLicenseKeyString: (NSString*)inLicenseKey;

-(void)	updateLicenseKeyButtonEnableState;

@end
