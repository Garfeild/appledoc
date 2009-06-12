//
//  OutputGenerator.m
//  appledoc
//
//  Created by Tomaz Kragelj on 11.6.09.
//  Copyright (C) 2009, Tomaz Kragelj. All rights reserved.
//

#import "OutputGenerator.h"
#import "CommandLineParser.h"

@implementation OutputGenerator

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Initialization & disposal
//////////////////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------
- (id) initWithDatabase:(NSMutableDictionary*) data
{
	self = [super init];
	if (self)
	{
		cmd = [CommandLineParser sharedInstance];
		manager = [NSFileManager defaultManager];
		database = [data retain];
		dependentGenerators = [[NSMutableArray alloc] init];
	}
	return self;
}

//----------------------------------------------------------------------------------------
- (void) dealloc
{
	cmd = nil;
	manager = nil;
	[database release], database = nil;
	[dependentGenerators release], dependentGenerators = nil;
	[super dealloc];
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Dependencies handling
//////////////////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------
- (void) registerDependentGenerator:(id<OutputProcessing>) generator
{
	NSParameterAssert(generator != nil);
	[dependentGenerators addObject:generator];
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Subclass handling
//////////////////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------
- (void) generateSpecificOutput
{
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark OutputProcessing protocol implementation
//////////////////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------
- (void) outputGenerationStarting
{
}

//----------------------------------------------------------------------------------------
- (void) outputGenerationFinished
{
}

//----------------------------------------------------------------------------------------
- (void) generateOutput
{
	if (self.isOutputGenerationEnabled)
	{
		// Create required output directories.
		[self createOutputDirectories];
		
		// Generate the output for this class.
		[self outputGenerationStarting];
		[self generateSpecificOutput];
		[self outputGenerationFinished];
		
		// Process all dependent generators. Note that this recursively generates the
		// output for all nested dependencies as well. Note that we only need to send
		// generateOutput message, it will take care of creating directories and the rest.
		BOOL outputWasGenerated = NO;
		for (id<OutputProcessing> dependentGenerator in dependentGenerators)
		{
			if (dependentGenerator.isOutputGenerationEnabled)
			{
				[dependentGenerator generateOutput];
				outputWasGenerated = YES;
			}
		}
		
		// If temporary files should be removed after creating and at least one dependent
		// generator output was created, we can remove our files.
		if (cmd.cleanTempFilesAfterBuild && outputWasGenerated)
		{
			[self removeOutputDirectories];
		}
	}
}

//----------------------------------------------------------------------------------------
- (BOOL) isOutputGenerationEnabled
{
	// By default we always return yes, so concrete subclasses which should always be
	// enabled don't have to handle this. However subclasses which can optionally be
	// disabled, should override and return proper value.
	return YES;
}

//----------------------------------------------------------------------------------------
- (void) createOutputDirectories
{
}

//----------------------------------------------------------------------------------------
- (void) removeOutputDirectories
{
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark OutputInfoProvider protocol implementation
//////////////////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------
- (NSString*) outputObjectFilenameForObject:(NSDictionary*) objectData
{
	NSString* path = [objectData objectForKey:kTKDataObjectRelPathKey];
	return [self pathByReplacingTemplatePlaceholdersInPath:path];
}

//----------------------------------------------------------------------------------------
- (NSString*) outputIndexFilename
{
	return [NSString stringWithFormat:@"index%@", [self outputFilesExtension]];
}

//----------------------------------------------------------------------------------------
- (NSString*) outputHierarchyFilename
{
	return [NSString stringWithFormat:@"hierarchy%@", [self outputFilesExtension]];
}

//----------------------------------------------------------------------------------------
- (NSString*) outputFilesExtension
{
	return @"";
}

//----------------------------------------------------------------------------------------
- (NSString*) outputBasePath
{
	return @"";
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Helper methods
//////////////////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------
- (NSString*) pathByReplacingTemplatePlaceholdersInPath:(NSString*) path
{
	return [path stringByReplacingOccurrencesOfString:kTKPlaceholderExtension 
										   withString:[self outputFilesExtension]];
}

@end
