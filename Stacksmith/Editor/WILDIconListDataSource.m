//
//  WILDIconListDataSource.m
//  Stacksmith
//
//  Created by Uli Kusterer on 05.04.10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "WILDIconListDataSource.h"
#import "WILDStack.h"
#import "WILDDocument.h"
#import <Quartz/Quartz.h>


@interface WILDSimpleImageBrowserItem : NSObject // IKImageBrowserItem
{
	NSImage*						mImage;
	NSString*						mName;
	NSString*						mFileName;
	BOOL							mIsBuiltIn;
	WILDObjectID					mID;
	WILDIconListDataSource*			mOwner;	
}

@property (retain) NSImage*							image;
@property (retain) NSString*						name;
@property (retain) NSString*						filename;
@property (assign) WILDObjectID						pictureID;
@property (assign) WILDIconListDataSource*			owner;
@property (assign) BOOL								isBuiltIn;

@end


@implementation WILDSimpleImageBrowserItem

@synthesize image = mImage;
@synthesize name = mName;
@synthesize filename = mFileName;
@synthesize pictureID = mID;
@synthesize owner = mOwner;
@synthesize isBuiltIn = mIsBuiltIn;

-(void)	dealloc
{
	[mImage release];
	mImage = nil;
	[mName release];
	mName = nil;
	[mFileName release];
	mFileName = nil;
	
	[super dealloc];
}


-(NSString *)  imageUID
{
	return [NSString stringWithFormat: @"%lld", mID];
}

-(NSString *) imageRepresentationType
{
	return IKImageBrowserNSImageRepresentationType;
}

-(id) imageRepresentation
{
	if( !mImage )
		mImage = [[[mOwner document] pictureOfType: @"icon" id: mID] retain];
	
	return mImage;
}

-(NSString *) imageTitle
{
	return mName;
}

@end


@implementation WILDIconListDataSource

@synthesize document = mDocument;
@synthesize iconListView = mIconListView;
@synthesize imagePathField = mImagePathField;
@synthesize delegate = mDelegate;

-(id)	initWithDocument: (WILDDocument*)inDocument
{
	if(( self = [super init] ))
	{
		mDocument = inDocument;
	}
	
	return self;
}


-(void)	dealloc
{
	[mIcons release];
	mIcons = nil;
	[mIconListView release];
	mIconListView = nil;
	[mImagePathField release];
	mImagePathField = nil;
	
	[super dealloc];
}


-(void)	setIconListView: (IKImageBrowserView*)inIconListView
{
	if( mIconListView != inIconListView )
	{
		[mIconListView release];
		mIconListView = [inIconListView retain];
		
		[mIconListView registerForDraggedTypes: [NSArray arrayWithObject: NSURLPboardType]];
	}
}


-(void)	ensureIconListExists
{
	if( !mIcons )
	{
		mIcons = [[NSMutableArray alloc] init];

		WILDSimpleImageBrowserItem	*sibi = [[[WILDSimpleImageBrowserItem alloc] init] autorelease];
		sibi.name = @"No Icon";
		sibi.filename = nil;
		sibi.pictureID = 0;
		sibi.image = [NSImage imageNamed: @"NoIcon"];
		sibi.owner = self;
		[mIcons addObject: sibi];

		NSInteger	x = 0, count = [mDocument numberOfPictures];
		for( x = 0; x < count; x++ )
		{
			NSString*		theName = nil;
			WILDObjectID	theID = 0;
			NSString*		fileName = nil;
			BOOL			isBuiltIn = NO;
			sibi = [[[WILDSimpleImageBrowserItem alloc] init] autorelease];
			
			[mDocument infoForPictureAtIndex: x name: &theName id: &theID
					image: nil fileName: &fileName isBuiltIn: &isBuiltIn];
			
			sibi.name = theName;
			sibi.filename = fileName;
			sibi.pictureID = theID;
			sibi.isBuiltIn = isBuiltIn;
			sibi.owner = self;
			
			[mIcons addObject: sibi];
		}
		
		[mIconListView setAllowsEmptySelection: NO];
		[mIconListView reloadData];
	}
}


-(void)	setSelectedIconID: (WILDObjectID)theID
{
	[self ensureIconListExists];
	
	NSInteger		x = 0;
	for( WILDSimpleImageBrowserItem* sibi in mIcons )
	{
		if( sibi.pictureID == theID )
		{
			[mIconListView setSelectionIndexes: [NSIndexSet indexSetWithIndex: x] byExtendingSelection: NO];
			[mIconListView scrollIndexToVisible: x];
			break;
		}
		x++;
	}
}


-(WILDObjectID)	selectedIconID
{
	NSInteger	selectedIndex = [[mIconListView selectionIndexes] firstIndex];
	return [[mIcons objectAtIndex: selectedIndex] pictureID];
}


-(NSUInteger) numberOfItemsInImageBrowser: (IKImageBrowserView *)aBrowser
{
	[self ensureIconListExists];
	
	return [mIcons count];
}


-(id /*IKImageBrowserItem*/) imageBrowser: (IKImageBrowserView *) aBrowser itemAtIndex: (NSUInteger)idx
{
	[self ensureIconListExists];
	
	return [mIcons objectAtIndex: idx];
}


-(void)	imageBrowserSelectionDidChange: (IKImageBrowserView *)aBrowser
{
	NSInteger							selectedIndex = [[mIconListView selectionIndexes] firstIndex];
	if( selectedIndex != NSNotFound )
	{
		WILDSimpleImageBrowserItem		*	theItem = [mIcons objectAtIndex: selectedIndex];
		NSString						*	thePath = theItem.isBuiltIn ? [[NSBundle mainBundle] bundlePath] : [[theItem filename] stringByDeletingLastPathComponent];
		NSString*							theName = [[NSFileManager defaultManager] displayNameAtPath: thePath];
		NSString*							statusMsg = @"No Icon";
		if( theName && [theItem pictureID] != 0 )
			statusMsg = [NSString stringWithFormat: @"ID = %lld, from %@", [theItem pictureID], theName];
		[mImagePathField setStringValue: statusMsg];
	}
	
	if( [mDelegate respondsToSelector: @selector(iconListDataSourceSelectionDidChange:)] )
		[mDelegate iconListDataSourceSelectionDidChange: self];
}


-(IBAction)	paste: (id)sender
{
	WILDObjectID	iconToSelect = 0;
	NSPasteboard*	thePastie = [NSPasteboard generalPasteboard];
	NSArray*		images = [thePastie readObjectsForClasses: [NSArray arrayWithObject: [NSImage class]] options:[NSDictionary dictionary]];
	for( NSImage* theImg in images )
	{
		NSString*		pictureName = @"From Clipboard";
		WILDObjectID	pictureID = [mDocument uniqueIDForMedia];
		[mDocument addMediaFile: nil withType: @"icon" name: pictureName
			andID: pictureID
			hotSpot: NSZeroPoint 
			imageOrCursor: theImg
			isBuiltIn: NO];
		
		WILDSimpleImageBrowserItem	*sibi = [[[WILDSimpleImageBrowserItem alloc] init] autorelease];
		sibi.name = pictureName;
		sibi.filename = nil;
		sibi.pictureID = pictureID;
		sibi.image = theImg;
		sibi.owner = self;
		[mIcons addObject: sibi];
		iconToSelect = pictureID;
	}
	[mIconListView reloadData];
	if( iconToSelect != 0 )
		[self setSelectedIconID: iconToSelect];
}


//-(void)	delete:(id)sender
//{
//	
//}


- (NSDragOperation)draggingEntered: (id <NSDraggingInfo>)sender
{
	return [self draggingUpdated: sender];
}


- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	NSPasteboard*	pb = [sender draggingPasteboard];
	if( [pb canReadObjectForClasses: [NSArray arrayWithObject: [NSURL class]] options: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: YES], NSPasteboardURLReadingFileURLsOnlyKey, [NSArray arrayWithObject: @"public.image"], NSPasteboardURLReadingContentsConformToTypesKey, nil]] )
	{
		[mIconListView setDropIndex: -1 dropOperation: IKImageBrowserDropOn];
		
		return NSDragOperationCopy;
	}
	else
		return NSDragOperationNone;
}


- (BOOL)performDragOperation: (id <NSDraggingInfo>)sender
{
	WILDObjectID	iconToSelect = 0;
	NSPasteboard*	pb = [sender draggingPasteboard];
	NSArray	*		urls = [pb readObjectsForClasses: [NSArray arrayWithObject: [NSURL class]] options: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: YES], NSPasteboardURLReadingFileURLsOnlyKey, [NSArray arrayWithObject: @"public.image"], NSPasteboardURLReadingContentsConformToTypesKey, nil]];
	
	if( urls.count > 0 )
	{
		for( NSURL* theImgFile in urls )
		{
			NSImage *		theImg = [[[NSImage alloc] initWithContentsOfURL: theImgFile] autorelease];
			NSString*		pictureName = [[NSFileManager defaultManager] displayNameAtPath: [theImgFile path]];
			WILDObjectID	pictureID = [mDocument uniqueIDForMedia];
			[mDocument addMediaFile: nil withType: @"icon" name: pictureName
				andID: pictureID
				hotSpot: NSZeroPoint 
				imageOrCursor: theImg
				isBuiltIn: NO];
			
			WILDSimpleImageBrowserItem	*sibi = [[[WILDSimpleImageBrowserItem alloc] init] autorelease];
			sibi.name = pictureName;
			sibi.filename = nil;
			sibi.pictureID = pictureID;
			sibi.image = theImg;
			sibi.owner = self;
			[mIcons addObject: sibi];
			iconToSelect = pictureID;
		}
	}
	else
	{
		NSArray*		images = [pb readObjectsForClasses: [NSArray arrayWithObject: [NSImage class]] options:[NSDictionary dictionary]];
		for( NSImage* img in images )
		{
			NSString*		pictureName = @"";
			WILDObjectID	pictureID = [mDocument uniqueIDForMedia];
			[mDocument addMediaFile: nil withType: @"icon" name: pictureName
				andID: pictureID
				hotSpot: NSZeroPoint 
				imageOrCursor: img
				isBuiltIn: NO];
			
			WILDSimpleImageBrowserItem	*sibi = [[[WILDSimpleImageBrowserItem alloc] init] autorelease];
			sibi.name = pictureName;
			sibi.filename = nil;
			sibi.pictureID = pictureID;
			sibi.image = img;
			sibi.owner = self;
			[mIcons addObject: sibi];
			iconToSelect = pictureID;
		}
	}
	[mIconListView reloadData];
	if( iconToSelect != 0 )
		[self setSelectedIconID: iconToSelect];
	
	return( urls != 0 && [urls count] > 0 );
}

@end
