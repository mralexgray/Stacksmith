/*
 *  WILDPropertyInstructions.m
 *  Leonie
 *
 *  Created by Uli Kusterer on 09.10.10.
 *  Copyright 2010 Uli Kusterer. All rights reserved.
 *
 */

/*!
	@header WILDPropertyInstructions
	While Forge knows how to parse property expressions, it does not know about
	the host-specific objects and how to ask them for their properties. So it
	assumes that the instructions for that will be defined by the host as defined
	by the constants and global declarations in "LEOPropertyInstructions.h". To
	register these properties at startup, call:
	<pre>
	LEOAddInstructionsToInstructionArray( gPropertyInstructions, LEO_NUMBER_OF_PROPERTY_INSTRUCTIONS, &kFirstPropertyInstruction );
	</pre>
	Forge will then use kFirstPropertyInstruction to offset all the instruction
	IDs as needed when generating code for a property expression.
*/

#import "Forge.h"
#import "WILDObjectValue.h"
#import "WILDObjCConversion.h"


void	LEOPushPropertyOfObjectInstruction( LEOContext* inContext );
void	LEOSetPropertyOfObjectInstruction( LEOContext* inContext );
void	LEOPushMeInstruction( LEOContext* inContext );


/*!
	Push the value of a property of an object onto the stack, ready for use e.g.
	in an expression. Two parameters need to be pushed on the stack before
	calling this and will be popped off the stack by this instruction before
	the property value is pushed:
	
	propertyName -	The name of the property to retrieve, as a string or some
					value that converts to a string.
	
	object -		The object from which to retrieve the property, as a
					WILDObjectValue (i.e. isa = kLeoValueTypeWILDObject).
	
	(PUSH_PROPERTY_OF_OBJECT_INSTR)
*/
void	LEOPushPropertyOfObjectInstruction( LEOContext* inContext )
{
	LEOValuePtr		thePropertyName = inContext->stackEndPtr -2;
	LEOValuePtr		theObject = inContext->stackEndPtr -1;
	
	char			propNameStr[1024] = { 0 };
	LEOGetValueAsString( thePropertyName, propNameStr, sizeof(propNameStr), inContext );
	
	LEOValuePtr		objectValue = LEOFollowReferencesAndReturnValueOfType( theObject, &kLeoValueTypeWILDObject, inContext );
	if( objectValue )
	{
		id propValueObj = [(id<WILDObject>)objectValue->object.object valueForWILDPropertyNamed: [NSString stringWithUTF8String: propNameStr] ofRange: NSMakeRange(0,0)];
		if( !propValueObj )
		{
			LEOContextStopWithError( inContext,"Object does not have property \"%s\".", propNameStr );
			return;
		}
		LEOCleanUpValue( thePropertyName, kLEOInvalidateReferences, inContext );
		
		if( !WILDObjCObjectToLEOValue( propValueObj, thePropertyName, inContext ) )
		{
			LEOContextStopWithError( inContext, "Internal Error: property '%s' returned unknown value.", propNameStr );
			return;
		}
	}
	else
	{
		LEOCleanUpValue( thePropertyName, kLEOInvalidateReferences, inContext );
		LEOValuePtr	theValue = LEOGetValueForKey( theObject, propNameStr, thePropertyName, kLEOInvalidateReferences, inContext );
		if( !theValue )
		{
			LEOContextStopWithError( inContext, "Can't get property \"%s\" of this.", propNameStr );
			return;
		}
		else if( theValue != thePropertyName )
			LEOInitCopy( theValue, thePropertyName, kLEOInvalidateReferences, inContext );
	}
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -1 );
	
	inContext->currentInstruction++;
}


/*!
	Change the value of a particular property of an object. Three parameters must
	have been pushed on the stack before this instruction is called, and will be
	popped off the stack:
	
	propertyName -	The name of the property to change, as a string value or value
					that converts to a string.
					
	object -		The object to change the property on. This must be a
					WILDObjectValue (i.e. isa = kLeoValueTypeWILDObject).
	
	value -			The new value to assign to the given property.
	
	(SET_PROPERTY_OF_OBJECT_INSTR)
*/
void	LEOSetPropertyOfObjectInstruction( LEOContext* inContext )
{
	LEOValuePtr		theValue = inContext->stackEndPtr -1;
	LEOValuePtr		theObject = inContext->stackEndPtr -2;
	LEOValuePtr		thePropertyName = inContext->stackEndPtr -3;
	
	char		propNameStr[1024] = { 0 };
	LEOGetValueAsString( thePropertyName, propNameStr, sizeof(propNameStr), inContext );
	
	LEOValuePtr	theObjectValue = LEOFollowReferencesAndReturnValueOfType( theObject, &kLeoValueTypeWILDObject, inContext );
	
	if( theObjectValue )
	{
		id<WILDObject>	theObjCObject = (id<WILDObject>)theObjectValue->object.object;
		NSString	*	propNameObjCStr = [NSString stringWithUTF8String: propNameStr];
		id				theObjCValue = WILDObjCObjectFromLEOValue( theValue, inContext, [theObjCObject typeForWILDPropertyNamed: propNameObjCStr] );
		
		@try
		{
			if( ![theObjCObject setValue: theObjCValue forWILDPropertyNamed: propNameObjCStr inRange: NSMakeRange(0,0)] )
			{
				LEOContextStopWithError( inContext, "Object does not have property \"%s\".", propNameStr );
				return;
			}
		}
		@catch( NSException* exc )
		{
			LEOContextStopWithError( inContext, "Error retrieving property \"%s\": %s", propNameStr, [[exc reason] UTF8String] );
			return;
		}
	}
	else
	{
		LEOSetValueForKey( theObject, propNameStr, theValue, inContext );
	}
	
	LEOCleanUpStackToPtr( inContext, inContext->stackEndPtr -3 );
	
	inContext->currentInstruction++;
}


/*!
	This instruction pushes a reference to the object owning the current script
	onto the stack. It implements the 'me' object specifier for Hammer.
	
	(PUSH_ME_INSTR)
*/

void	LEOPushMeInstruction( LEOContext* inContext )
{
	LEOScript	*	myScript = LEOContextPeekCurrentScript( inContext );
	
	inContext->stackEndPtr++;
	
	LEOInitReferenceValueWithIDs( inContext->stackEndPtr -1, myScript->ownerObject, myScript->ownerObjectSeed,
									  kLEOInvalidateReferences, inContext );
	
	inContext->currentInstruction++;
}


LEOINSTR_START(Property,LEO_NUMBER_OF_PROPERTY_INSTRUCTIONS)
LEOINSTR(LEOPushPropertyOfObjectInstruction)
LEOINSTR(LEOSetPropertyOfObjectInstruction)
LEOINSTR_LAST(LEOPushMeInstruction)


