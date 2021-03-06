//
//  WILDGlobalProperties.m
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDGlobalProperties.h"
#import "StacksmithVersion.h"
#import <string.h>
#import <Foundation/Foundation.h>
#import "UKSystemInfo.h"
#import "WILDObjectValue.h"
#import "WILDScriptContainer.h"


#define TOSTRING2(x)	#x
#define TOSTRING(x)		TOSTRING2(x)


size_t	kFirstGlobalPropertyInstruction = 0;


void	LEOSetCursorInstruction( LEOContext* inContext );
void	LEOPushCursorInstruction( LEOContext* inContext );
void	LEOSetVersionInstruction( LEOContext* inContext );
void	LEOPushVersionInstruction( LEOContext* inContext );
void	LEOPushShortVersionInstruction( LEOContext* inContext );
void	LEOPushLongVersionInstruction( LEOContext* inContext );
void	LEOPushPlatformInstruction( LEOContext* inContext );
void	LEOPushPhysicalMemoryInstruction( LEOContext* inContext );
void	LEOPushMachineInstruction( LEOContext* inContext );
void	LEOPushSystemVersionInstruction( LEOContext* inContext );
void	LEOPushTargetInstruction( LEOContext* inContext );



void	LEOSetCursorInstruction( LEOContext* inContext )
{
	char		propValueStr[1024] = { 0 };
	LEOGetValueAsString( inContext->stackEndPtr -1, propValueStr, sizeof(propValueStr), inContext );
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	// TODO: Set the cursor with propValueStr here.
	
	inContext->currentInstruction++;
}


void	LEOPushCursorInstruction( LEOContext* inContext )
{
	LEOPushIntegerOnStack( inContext, 128 );	// TODO: Actually retrieve actual cursor ID here.
	
	inContext->currentInstruction++;
}


void	LEOSetVersionInstruction( LEOContext* inContext )
{
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	LEOContextStopWithError( inContext, "You can't change the version number." );
	
	inContext->currentInstruction++;
}


void	LEOPushVersionInstruction( LEOContext* inContext )
{
	const char*		theVersion = TOSTRING(STACKSMITH_VERSION);
	
	LEOPushStringValueOnStack( inContext, theVersion, strlen(theVersion) );
	
	inContext->currentInstruction++;
}


void	LEOPushShortVersionInstruction( LEOContext* inContext )
{
	const char*		theVersion = TOSTRING(STACKSMITH_SHORT_VERSION);
	
	LEOPushStringValueOnStack( inContext, theVersion, strlen(theVersion) );
	
	inContext->currentInstruction++;
}


void	LEOPushLongVersionInstruction( LEOContext* inContext )
{
	const char*		theVersion = "Stacksmith " TOSTRING(STACKSMITH_VERSION);
	
	LEOPushStringValueOnStack( inContext, theVersion, strlen(theVersion) );
	
	inContext->currentInstruction++;
}


void	LEOPushPlatformInstruction( LEOContext* inContext )
{
	const char*		theOSStr = "MacOS";
	LEOPushStringValueOnStack( inContext, theOSStr, strlen(theOSStr) );
	
	inContext->currentInstruction++;
}


void	LEOPushSystemVersionInstruction( LEOContext* inContext )
{
	const char*	theSysVersion = [UKSystemVersionString() UTF8String];
	LEOPushStringValueOnStack( inContext, theSysVersion, strlen(theSysVersion) );
	
	inContext->currentInstruction++;
}


void	LEOPushPhysicalMemoryInstruction( LEOContext* inContext )
{
	unsigned 	physMemory = UKPhysicalRAMSize() / 1024U;
	NSString	*physMemoryObjCStr = [NSString stringWithFormat: @"%u GB", physMemory];
	const char*	physMemoryStr = [physMemoryObjCStr UTF8String];
	LEOPushStringValueOnStack( inContext, physMemoryStr, strlen(physMemoryStr) );
	
	inContext->currentInstruction++;
}


void	LEOPushMachineInstruction( LEOContext* inContext )
{
	NSString	*	machineStr = UKMachineName();
	const char	*	machineCStr = [machineStr UTF8String];
	LEOPushStringValueOnStack( inContext, machineCStr, strlen(machineCStr) );
	
	inContext->currentInstruction++;
}


void	LEOPushTargetInstruction( LEOContext* inContext )
{
	LEOValuePtr	newVal = LEOPushValueOnStack( inContext, NULL );
	WILDInitObjectValue( &newVal->object, ((WILDScriptContextUserData*) inContext->userData).target, kLEOInvalidateReferences, inContext );
	
	inContext->currentInstruction++;
}


LEOINSTR_START(GlobalProperty,LEO_NUMBER_OF_GLOBAL_PROPERTY_INSTRUCTIONS)
LEOINSTR(LEOSetCursorInstruction)
LEOINSTR(LEOPushCursorInstruction)
LEOINSTR(LEOPushVersionInstruction)
LEOINSTR(LEOPushShortVersionInstruction)
LEOINSTR(LEOPushLongVersionInstruction)
LEOINSTR(LEOPushPlatformInstruction)
LEOINSTR(LEOPushPhysicalMemoryInstruction)
LEOINSTR(LEOPushMachineInstruction)
LEOINSTR(LEOPushSystemVersionInstruction)
LEOINSTR_LAST(LEOPushTargetInstruction)


struct TGlobalPropertyEntry	gHostGlobalProperties[] =
{
	{ ECursorIdentifier, ELastIdentifier_Sentinel, SET_CURSOR_INSTR, PUSH_CURSOR_INSTR },
	{ EVersionIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_VERSION_INSTR },
	{ EVersionIdentifier, EShortIdentifier, INVALID_INSTR2, PUSH_SHORT_VERSION_INSTR },
	{ EVersionIdentifier, ELongIdentifier, INVALID_INSTR2, PUSH_LONG_VERSION_INSTR },
	{ EPlatformIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_PLATFORM_INSTR },
	{ ESystemVersionIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_SYSTEMVERSION_INSTR },
	{ EPhysicalMemoryIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_PHYSICALMEMORY_INSTR },
	{ EMachineIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_MACHINE_INSTR },
	{ ETargetIdentifier, ELastIdentifier_Sentinel, INVALID_INSTR2, PUSH_TARGET_INSTR },
	{ ELastIdentifier_Sentinel, ELastIdentifier_Sentinel, INVALID_INSTR2, INVALID_INSTR2 }
};
