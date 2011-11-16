//
//  Brain.m
//  CnotiMind
//
//  Created by Gonçalo Rodrigues on 11/04/27.
//  Copyright 2011 Cnotinfor. All rights reserved.
//

#import "Brain.h"

#import "GDataXMLNode.h"

#import "NSMutableArray+QueueAdditions.h"

#import "RootNode.h"
#import "ConditionPerceptionNode.h"
#import "ActionNode.h"

#import "CnotiMind.h"

@implementation Brain

NSString* const SEND_ACTION = @"SEND_ACTION";
NSString* const SEND_EMOTIONAL_STATE = @"SEND_EMOTIONAL_STATE";

@synthesize emotions = _emotions;
@synthesize receivedPerceptions = _receivedPerceptions;

@synthesize properties = _properties;

- (id) init
{
    if (self == [super init]) {
        _validPerceptions = [[NSMutableArray alloc] init];
        _validActions = [[NSMutableArray alloc] init];
        _emotions = [[NSMutableArray alloc] init];
        
        _crutches = [[NSMutableArray alloc] init];
        
        _receivedPerceptions = [[NSMutableArray alloc] init];
        
        _receivedPerceptions = [[NSMutableArray alloc] init];
        _emotionsChanged = [[NSMutableArray alloc] init];
        _longTermMemory = [[NSMutableArray alloc] init];
        _workingMemory = [[NSMutableArray alloc] init];
        
        _properties = [[NSMutableDictionary alloc] init];
        
        _semaphoreBrain = [[NSConditionLock alloc] initWithCondition:NO_DATA];
        
        _quit = false;
        
        _crutchEnabled = false;
        
    }
    
    _settingsXMLHandler = [[SettingsXmlHandler alloc] initWithBrain:self];
    _crutchesXMLHandler = [[CrutchesXmlHandler alloc] initWithBrain:self];
    
    return self;
}


- (id) initWithPath:(NSString*)aPath
{
    if (self == [super init]) {
        
        _semaphoreBrain = [[NSConditionLock alloc] initWithCondition:NO_DATA];       
        
        
        //  [self loadXmlSettings:aPath];
        //  TODO
        //  [self initWithTarget:self selector:@selector(run) object:nil];
        //  [self run];
        
        //  [NSThread detachNewThreadSelector:@selector(startThreadRun) toTarget:self withObject:nil];
    }
    return self;
}


- (IBAction) startThreadRun
{
    [NSThread detachNewThreadSelector:@selector(run) toTarget:self withObject:nil];
}


- (void) addValidPerception:(NSString*)aPerception
{
    [_validPerceptions enqueue:aPerception];
}


- (void) addValidAction:(NSString*)aAction
{
    [_validActions enqueue:aAction];
}


- (void) addEmotion:(Emotion*)aEmotion
{
    [_emotions enqueue:aEmotion];
}

- (void) addCrutch:(Crutch*)aCrutch
{
    [_crutches enqueue:aCrutch];
}

/**
 Load a XML file with settings.
 This method can me called several times, append new settings to the Brain.
 XML file can have Perceptions, Actions and Emotions
 */
- (BOOL) loadXmlSettings:(NSString*)aFilePath
{
    DLog(@"%@", aFilePath);
    
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:aFilePath];  
    NSError *error;
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData 
														   options:0 error:&error];
    
    if (error) {
        DLog(@"[Brain::loadXmlSettings] File not found");
        return false;
    }
    
    else {
        //  Make the parsing - must be recursive!!!
        NSArray *settingsMembers = [doc.rootElement children];
        
        DLog(@"settingsMembers: %@", settingsMembers);
        
        [_settingsXMLHandler startElement:nil localName:nil qName:@"Settings" atts:nil];
        [self loadXMLRecursiveSettings: settingsMembers];
        [_settingsXMLHandler endElement:nil localName:nil qName:@"Settings"];
    }
    
    [doc release];
    [xmlData release];
    
    DLog(@"[Brain::loadXmlSettings] done");
    
    return true;
}

/**
 Load a XML file with crutches.
 This method can me called several times, append new settings to the Brain.
 XML file can have Crutches
 */
- (BOOL) loadXmlCrutches:(NSString*)aFilePath
{
    DLog(@"%@", aFilePath);
    
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:aFilePath];  
    NSError *error;
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData 
														   options:0 
                                                             error:&error];
    
    if (error) {
        DLog(@"[Brain::loadXmlCrutches] File not found");
        return false;
    }
    
    else {
        //  Make the parsing - must be recursive!!!
        NSArray *crutchesMembers = [doc.rootElement children];
        
        DLog(@"crutchesMembers: %@", crutchesMembers);
        
        [_crutchesXMLHandler startElement:nil localName:nil qName:@"Crutches" atts:nil];
        [self loadXMLRecursiveCrutches: crutchesMembers];
        [_crutchesXMLHandler endElement:nil localName:nil qName:@"Crutches"];
    }
    
    [doc release];
    [xmlData release];
    
    DLog(@"[Brain::loadXmlCrutches] done");
    
    return true;
}

- (BOOL) loadXmlRules:(NSString*)aFilePath
{
    
    _rulesXMLHandler = [[RulesXmlHandler alloc] initWithBrain:self rules:_rules];

    DLog(@"%@", aFilePath);
    
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:aFilePath];  
    NSError *error;
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData 
														   options:0 error:&error];
    
    if (error) {
        DLog(@"[Brain::loadXmlRules] File not found");
        return false;
    }
    
    else {
        //  Make the parsing - must be recursive!!!
        NSArray *rulesMembers = [doc.rootElement children];
        
        DLog(@"rulesMembers: %@", rulesMembers);
        
        [_rulesXMLHandler startElement:nil localName:nil qName:@"Rules" atts:nil];
        [self loadXMLRecursive: rulesMembers];
        [_rulesXMLHandler endElement:nil localName:nil qName:@"Rules"];
    }
    
    [doc release];
    [xmlData release];
    
    _rules = [_rulesXMLHandler rootNode];
    DLog(@"[Brain::loadXmlRules] done rules: %@",_rules);

    return true;
}


- (BOOL) loadXMLRecursive:(NSArray*)rulesMembers
{
    if ([rulesMembers count]==0) {
        return false;
    }
    
    for (GDataXMLElement* rulesMember in rulesMembers) {
        NSString* elementName = [NSString stringWithString:[rulesMember name]];

        [_rulesXMLHandler startElement:nil localName:nil qName:elementName atts:rulesMember];
    
        NSArray* childArray = [rulesMember children];        
        [self loadXMLRecursive:childArray];
    
        [_rulesXMLHandler endElement:nil localName:nil qName:elementName];
    }
    return true;
}


- (BOOL) loadXMLRecursiveSettings:(NSArray*)settingsMembers
{
    if ([settingsMembers count]==0) {
        return false;
    }
    
    for (GDataXMLElement* settingMember in settingsMembers) {
        NSString* elementName = [NSString stringWithString:[settingMember name]];
        
        [_settingsXMLHandler startElement:nil localName:nil qName:elementName atts:settingMember];
        
        NSArray* childArray = [settingMember children];        
        [self loadXMLRecursiveSettings:childArray];
        
        [_settingsXMLHandler endElement:nil localName:nil qName:elementName];
    }
    return true;
}


- (BOOL) loadXMLRecursiveCrutches:(NSArray*)crutchesMembers
{
    if ([crutchesMembers count]==0) {
        return false;
    }
    
    for (GDataXMLElement* crutchMember in crutchesMembers) {
        NSString* elementName = [NSString stringWithString:[crutchMember name]];
        
        [_crutchesXMLHandler startElement:nil localName:nil qName:elementName atts:crutchMember];
        
        NSArray* childArray = [crutchMember children];        
        [self loadXMLRecursiveSettings:childArray];
        
        [_crutchesXMLHandler endElement:nil localName:nil qName:elementName];
    }
    return true;
}


- (BOOL) validateXml:(NSString*)aFilename
{
    return true;
}


- (BOOL) saveMemory:(NSString*)aFilename
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* filenameToSave = [documentsDirectory stringByAppendingFormat:@"%@", aFilename];
    
    
    NSString* xmlMemory = [NSString stringWithFormat:@""];
    xmlMemory = [xmlMemory stringByAppendingString:@"<Memory>\n"];
    xmlMemory = [xmlMemory stringByAppendingString:@"<LongTermMemory>\n"];    
    
    NSEnumerator* eLongTermMemory = [_longTermMemory objectEnumerator];
    MemoryEvent* objectLongTermMemory;
    while (objectLongTermMemory = [eLongTermMemory nextObject]) {
        xmlMemory = [xmlMemory stringByAppendingFormat:@"%@", [objectLongTermMemory toXML]];
    }
    
    xmlMemory = [xmlMemory stringByAppendingString:@"</LongTermMemory>\n"];
    xmlMemory = [xmlMemory stringByAppendingString:@"<WorkingMemory>\n"];
    
    NSEnumerator* eWorkingMemory = [_workingMemory objectEnumerator];
    MemoryEvent* objectWorkingMemory;
    while (objectWorkingMemory = [eWorkingMemory nextObject]) {
        xmlMemory = [xmlMemory stringByAppendingFormat:@"%@", [objectWorkingMemory toXML]];
    }
    
    xmlMemory = [xmlMemory stringByAppendingString:@"</WorkingMemory>\n"];    
    xmlMemory = [xmlMemory stringByAppendingString:@"</Memory>\n"];
    
    NSData *xmlMemoryData = [xmlMemory dataUsingEncoding:NSUTF8StringEncoding];
    [xmlMemoryData writeToFile:filenameToSave atomically:YES];
    
    return true;
}


//  TODO
- (BOOL) loadMemory:(NSString*)aFilename
{
    
    return false;
}


//  TODO
- (BOOL) saveEmotionalState:(NSString*)aFilename
{
    
    return false;
}


//  TODO
- (BOOL) loadEmotionalState:(NSString*)aFilename
{
    
    return false;
}



- (void) clearWorkingMemory
{
    [_workingMemory removeAllObjects];
}


- (void) clearMemory
{
    [_longTermMemory removeAllObjects];
    [_workingMemory removeAllObjects];
}


- (void) printSettings;
{
    NSString* settings = [NSString stringWithFormat:@"\n--- Print Brain Settings ---"];
    settings = [settings stringByAppendingString:@"\n--- Valid Perceptions ---"];    
    
    if ([_validPerceptions count] == 0) {
        settings = [settings stringByAppendingString:@"No Perceptions defined"];            
    }
    else {
        NSEnumerator* ePerceptions = [_validPerceptions objectEnumerator];
        Perception* objectPerception;
        while (objectPerception = [ePerceptions nextObject]) {
            settings = [settings stringByAppendingFormat:@"\n%@", [objectPerception description]];
        }
    }
    
    
    settings = [settings stringByAppendingString:@"\n--- Valid Actions ---"];    
    
    if ([_validActions count] == 0) {
        settings = [settings stringByAppendingString:@"\nNo Actions defined"];            
    }
    else {
        NSEnumerator* eActions = [_validActions objectEnumerator];
        Perception* objectAction;
        while (objectAction = [eActions nextObject]) {
            settings = [settings stringByAppendingFormat:@"\n%@", [objectAction description]];
        }
    }
    
    
    settings = [settings stringByAppendingString:@"\n--- Emotions ---"];    
    
    if ([_emotions count] == 0) {
        settings = [settings stringByAppendingString:@"\nNo Emotions defined"];            
    }
    else {
        NSEnumerator* eEmotions = [_emotions objectEnumerator];
        Perception* objectEmotion;
        while (objectEmotion = [eEmotions nextObject]) {
            settings = [settings stringByAppendingFormat:@"\n%@", [objectEmotion description]];
        }
    }
    
    DLog(@"%@",settings);
}


- (void) printRules
{
    DLog(@"printRules");
    DLog(@"%@", [_rules info:1]);
}

- (void) printMemory:(enum MemoryType) aType
{
    NSEnumerator* eMemory;
    
    if (aType == WorkingMemory) {
        DLog(@"--- Print Memory WorkingMemory---");
        @synchronized(_workingMemory) {
            eMemory = [_workingMemory objectEnumerator];
            MemoryEvent* objectMemoryEvent;
            while (objectMemoryEvent = [eMemory nextObject]) {
                DLog(@"\nEvent: %@ Value: %@", [objectMemoryEvent event], [objectMemoryEvent value]);
            }
        }
    }
    else if (aType == LongTermMemory) {
        DLog(@"--- Print Memory LongTermMemory---");
        @synchronized(_longTermMemory) {
            eMemory = [_longTermMemory objectEnumerator];
            MemoryEvent* objectMemoryEvent;
            while (objectMemoryEvent = [eMemory nextObject]) {
                DLog(@"\nEvent: %@ Value: %@", [objectMemoryEvent event], [objectMemoryEvent value]);
            }
        }
    }
    
}


- (void) receivePerception:(Perception*)aPerception
{
    [_semaphoreBrain lockWhenCondition:NO_DATA];

    [_receivedPerceptions enqueue:aPerception];
    
    [_semaphoreBrain unlockWithCondition:HAS_DATA];
}


//  TODO - not tested
- (void) stop
{
    _quit = true;
    [_semaphoreBrain unlockWithCondition:HAS_DATA];
}


- (void) sendAction:(NSString*)aKey value:(NSString*)aValue
{
    NSMutableDictionary* action = [[NSMutableDictionary alloc] init];
    [action setObject:aValue forKey:aKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:SEND_ACTION object:action];
    [action release];
}


- (void) sendEmotionalState:(NSString*)aKey value:(NSString*)aValue
{
    NSMutableDictionary* action = [[NSMutableDictionary alloc] init];
    [action setObject:aValue forKey:aKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:SEND_EMOTIONAL_STATE object:action];
    [action release];
}


- (void) updateEmotionValue:(NSString*)aEmotionName variation:(double)aVariation
{
    [self updateEmotionValue:aEmotionName variation:aVariation max:INT8_MAX min:INT8_MIN];
}

- (void) updateEmotionValue:(NSString*)aEmotionName variation:(double)aVariation max:(double)aMax min:(double)aMin
{
    NSEnumerator* eEmotions = [_emotions objectEnumerator];
    Emotion* objectEmotion;
    while (objectEmotion = [eEmotions nextObject]) {
        
        if (![[objectEmotion name] caseInsensitiveCompare:aEmotionName] == TRUE) {
            
            [objectEmotion addValue:aVariation max:aMax min:aMin];
            
            [self sendEmotionalState:[objectEmotion name] value:[NSString stringWithFormat:@"%f", [objectEmotion value]]];
            
            [_emotionsChanged enqueue:aEmotionName];
            
            if ([_semaphoreBrain tryLock]) {
                [_semaphoreBrain unlockWithCondition:HAS_DATA];
            }
            
            break;
        }
    }
}

- (void) updatePropertyValue:(NSString*)aPropertyName value:(NSString*)aValue
{
    DLog(@"aPropertyName: %@", aPropertyName);
    DLog(@"aValue: %@", aValue);
    
    [_properties setObject:aValue forKey:aPropertyName];
}


- (void) storeToMemory:(MemoryEvent*)aMemoryEvent memoryType:(enum MemoryType)aMemoryType
{
    switch((int)aMemoryType)
    {
		case LongTermMemory:
            @synchronized(_longTermMemory) {
                [_longTermMemory addObject:aMemoryEvent];
            }
			break;
		case WorkingMemory:
            @synchronized(_workingMemory) {
                [_workingMemory addObject:aMemoryEvent];
            }
			break;
    }
}

- (void) executeActionWithVariables:(NSString*)aKey value:(NSString*)aValue
{
    NSMutableDictionary* action = [[NSMutableDictionary alloc] init];
    [action setObject:aValue forKey:aKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SEND_ACTION" object:action];
    [action release];
}


- (void)executeAction:(NSString *)aKey value:(NSString *)aValue
{
    NSMutableDictionary* action = [[NSMutableDictionary alloc] init];
    [action setObject:aValue forKey:aKey];
    
    DLog(@"action key: %@", aKey);
    DLog(@"action value: %@", aValue);
    
    enum EnumCrutchOrder orderOfCrutch = -1;
    NSMutableArray* tempCrutchesArray = [[NSMutableArray alloc] initWithCapacity:100];
    BOOL foundCrutch = false;
    
    for (Crutch* crutchObject in _crutches) {
    // current emotional state (must search emotions array for particular emotion)
        for (Emotion* emotionObject in _emotions) {
            // if name are the same and action are same        
            if ( ![[emotionObject name] caseInsensitiveCompare:[crutchObject emotion]] && ![aKey caseInsensitiveCompare:[crutchObject action]] ) {
                
                // check if between min and max values
                if ( [emotionObject value] >= [crutchObject min] && [emotionObject value] <= [crutchObject max] ) {
                    [tempCrutchesArray addObject:crutchObject];
                    
                    //check order
                    orderOfCrutch = [crutchObject order];
                    foundCrutch = true;
                }
            }
        }
    }

    if ( foundCrutch && [tempCrutchesArray count]>0 && _crutchEnabled) {
        DLog(@"I found a crutch!");
        // search for a crutch in the crutches temp array        
        int n = arc4random() % [tempCrutchesArray count];
        DLog(@"n: %d", n);
        Crutch* randomCrutch = [tempCrutchesArray objectAtIndex:n];
        
        NSMutableDictionary* actionCrutch = [[NSMutableDictionary alloc] init];
        [actionCrutch setObject:[randomCrutch name] forKey:[randomCrutch action]];
        
        if ( orderOfCrutch == CrutchOrder_BEGIN ) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SEND_ACTION object:actionCrutch];
            [[NSNotificationCenter defaultCenter] postNotificationName:SEND_ACTION object:action];
        }
        else if ( orderOfCrutch == CrutchOrder_BEGIN_AND_END ) {
        
            int foo = arc4random() % 1;

            if ( foo == 0 ) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SEND_ACTION object:actionCrutch];
                [[NSNotificationCenter defaultCenter] postNotificationName:SEND_ACTION object:action];
                
            }
            else if ( foo == 1 ) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SEND_ACTION object:action];
                [[NSNotificationCenter defaultCenter] postNotificationName:SEND_ACTION object:actionCrutch];
            }            
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:SEND_ACTION object:action];
            [[NSNotificationCenter defaultCenter] postNotificationName:SEND_ACTION object:actionCrutch];
        }
        
        [actionCrutch release];
        
        _crutchEnabled = false;
    }
    
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:SEND_ACTION object:action];
    }
    
    [action release];
    [tempCrutchesArray removeAllObjects];
    [tempCrutchesArray release];
}

- (void) deleteEvent:(NSString*)aKey position:(enum DeletePosition)aPosition memory:(enum MemoryType)aMemory
{
    NSMutableArray* mem = aMemory == LongTermMemory ? _longTermMemory : _workingMemory;
    
    NSEnumerator* eMem = [mem objectEnumerator];
    
    BOOL removeLast = false;
    BOOL removeFirst = false;
    BOOL removeAll = false;
    
    switch ((int)aPosition) {
        case DeleteLast:
            @synchronized(mem) {
                for (MemoryEvent* aKey2 in eMem) {
                    NSString* k = [NSString stringWithFormat:@"%@", [aKey2 event]];
                    if (![aKey caseInsensitiveCompare: k]) {
                        removeLast = true;
                    }
                }
            }
            if (removeLast) {
                [mem removeLastObject];    
            }
            break;
        case DeleteFirst:
            @synchronized(mem) {
                for (MemoryEvent* aKey2 in eMem) {
                    NSString* k = [NSString stringWithFormat:@"%@", [aKey2 event]];
                    if (![aKey caseInsensitiveCompare: k]) {
                        removeFirst = true;
                    }
                }
            }
            if (removeFirst) {
                [mem removeObjectAtIndex:0];
            }
            break;
        case DeleteAll:
            @synchronized(mem) {
                for (MemoryEvent* aKey2 in eMem) {
                    NSString* k = [NSString stringWithFormat:@"%@", [aKey2 event]];
                    if (![aKey caseInsensitiveCompare: k]) {
                        removeAll = true;
                    }
                }
            }
            if (removeAll) {
                [mem removeAllObjects];
            }

            break;    

        default:
            break;
    }
    
}

//TODO
- (void) deleteEvent:(NSString*)aKey value:(NSString*)aValue position:(enum DeletePosition)aPosition memory:(enum MemoryType)aMemory
{

}


- (id) dataMining: (enum DataMiningOperation)aOperation event:(NSString*)aEvent memoryType:(enum MemoryType)aMemoryType valid:(BOOL*)aValid
{
    // test if parameters are valid for datamining
    if( [aEvent length]==0 )
    {
        DLog(@"aEvent: %@", aEvent);
        [self setValid: aValid value:false];
        return [[NSString alloc] initWithFormat:@""];
    }
    
    NSMutableArray* memory = (aMemoryType == WorkingMemory ? _workingMemory : _longTermMemory);
    
    [self setValid:aValid value:true];
    
    switch (aOperation) {
        case DMO_Max:
            return [[NSNumber alloc] initWithFloat:[self dataMiningMax: aEvent memory: memory valid:aValid]];
            break;
        case DMO_Min:
            return [[NSNumber alloc] initWithFloat:[self dataMiningMin: aEvent memory: memory valid:aValid]];
            break;
        case DMO_Sum:
            DLog(@"%f", [self dataMiningSum: aEvent memory: memory valid:aValid]);
            DLog(@"%@", [[NSNumber alloc] initWithFloat:[self dataMiningSum: aEvent memory: memory valid:aValid]]);
            return [[NSNumber alloc] initWithFloat:[self dataMiningSum: aEvent memory: memory valid:aValid]];
            break;
        case DMO_Count:
            return [[NSNumber alloc] initWithFloat:[self dataMiningCount: aEvent memory: memory valid:aValid]];
            break;
        case DMO_Mean:
            return [[NSNumber alloc] initWithFloat:[self dataMiningMean: aEvent memory: memory valid:aValid]];
            break;
        case DMO_Exists:
            return [[NSNumber alloc] initWithFloat:[self dataMiningExists: aEvent memory: memory valid:aValid]];
            break;
        case DMO_Last:
            return [self dataMiningLast: aEvent memory: memory valid:aValid];
            break;
        case DMO_First:
            return [self dataMiningFirst: aEvent memory: memory valid:aValid];
            break;
            
        default:
            break;
    }
    
    [self setValid: aValid value:false];
    
    return [NSString stringWithFormat:@""];
}


- (id) dataMining: (enum DataMiningOperation)aOperation event:(NSString*)aEvent value:(NSString*)aValue memoryType:(enum MemoryType)aMemoryType valid:(BOOL*)aValid
{
    
    NSString* result = [[NSString alloc] initWithString:@""];
    
    // test if parameters are valid for datamining
    if( [aEvent length]==0 )
    {
        [self setValid: aValid value:false];
        return result;
    }
    
    DLog(@"aValue: %@", aValue);
    // if value is empty, do datamining without the value
    if( [aValue length]==0 )
    {
        DLog(@"tete");
        return [[self dataMining:aOperation event:aEvent memoryType:aMemoryType valid:aValid] autorelease];
    }
    
    // get the memory to performe data mining
    NSMutableArray* memory = (aMemoryType == WorkingMemory ? _workingMemory : _longTermMemory);
    [self setValid: aValid value:true];
    
    switch (aOperation) {
        case DMO_Count:
            return [[NSString alloc] initWithFormat:@"%f",[self dataMiningCount:aEvent value:aValue memory:memory valid:aValid]];
            break;
        case DMO_Exists:
            return [[NSString alloc] initWithFormat:@"%d",[self dataMiningExists:aEvent value:aValue memory:memory valid:aValid]];
            break;
            
        default:
            break;
    }
    
    [self setValid: aValid value:false];
    return result;
}

/*
 Datamining Max only works if the values are numbers.
 
 If any value of the event is not a number, it will set valid to false.
 If the memory is empty it will set valid to false.
 If no event is found it also set valid to false.
 
 Valid becomes true, if it founds one element.
 */
- (float) dataMiningMax:(NSString*)aEvent memory:(NSMutableArray*)aMemory valid:(BOOL*)aValid
{
    // by defaulf the data mining is not valid
    aValid = false;
    
    if([aMemory count] == 0)
    {
        return 0;
    }
    
    bool ok;
    float max = INT_MIN;
    float aux;
    
    NSEnumerator* eMemoryEvent = [aMemory objectEnumerator];
    
    MemoryEvent* objectMemoryEvent;
    while( objectMemoryEvent = [eMemoryEvent nextObject] ) // Iterate all memory
    {
        //  MemoryEvent* me = [eMemoryEvent nextObject];
        
        if( ![[objectMemoryEvent event] caseInsensitiveCompare:aEvent] ) // Event found
        {
            if (strcmp([[objectMemoryEvent value] objCType], "f") || strcmp([[objectMemoryEvent value] objCType], "i") || strcmp([[objectMemoryEvent value] objCType], "d") || strcmp([[objectMemoryEvent value] objCType], "l")) {
                ok = true;
            }
            
            aux = [[objectMemoryEvent value] floatValue]; // convert value to qreal
            
            if( !ok ) // if the event value is not numeric
            {
                [self setValid:aValid value:false]; // mark has invalid datamining
                return 0;
            }
            
            if( aux > max )
            {
                max = aux;
                [self setValid: aValid value:true];// Max found, mark data mining has valid
            }
        }
    }
    
    return max;
}


- (float) dataMiningMin:(NSString*)aEvent memory:(NSMutableArray*)aMemory valid:(BOOL*)aValid
{
    // by defaulf the data mining is not valid
    aValid = false;
    
    if([aMemory count] == 0)
    {
        return 0;
    }
    
    bool ok;
    float min = INT_MAX;
    float aux;
    
    NSEnumerator* eMemoryEvent = [aMemory objectEnumerator];
    
    MemoryEvent* objectMemoryEvent;
    while( objectMemoryEvent = [eMemoryEvent nextObject] ) // Iterate all memory
    {
        //  MemoryEvent* me = [eMemoryEvent nextObject];
        
        if( ![[objectMemoryEvent event] caseInsensitiveCompare:aEvent] ) // Event found
        {
            if (strcmp([[objectMemoryEvent value] objCType], "f") || strcmp([[objectMemoryEvent value] objCType], "i") || strcmp([[objectMemoryEvent value] objCType], "d") || strcmp([[objectMemoryEvent value] objCType], "l")) {
                ok = true;
            }
            
            aux = [[objectMemoryEvent value] floatValue]; // convert value to qreal
            
            if( !ok ) // if the event value is not numeric
            {
                [self setValid:aValid value:false]; // mark has invalid datamining
                return 0;
            }
            
            if( aux < min )
            {
                min = aux;
                [self setValid: aValid value:true];// Max found, mark data mining has valid
            }
        }
    }
    
    return min;
}


- (float) dataMiningSum:(NSString*)aEvent memory:(NSMutableArray*)aMemory valid:(BOOL*)aValid
{
    // by defaulf the data mining is valid
    [self setValid:aValid value:true];
    
    if([aMemory count] == 0)
    {
        return 0;
    }
    
    bool ok;
    float sum = 0;
    float aux;
    
    NSEnumerator* eMemoryEvent = [aMemory objectEnumerator];
    
    MemoryEvent* objectMemoryEvent;
    while( objectMemoryEvent = [eMemoryEvent nextObject] ) // Iterate all memory
    {
        if( ![[objectMemoryEvent event] caseInsensitiveCompare:aEvent] ) // Event found
        {
            if ([self isNumeric: [objectMemoryEvent value]]) {
                ok = true;
            }
            
            aux = [[objectMemoryEvent value] floatValue]; // convert value to qreal
            if( !ok ) // if the event value is not numeric
            {
                [self setValid: aValid value:false]; // mark has invalid datamining
                return 0;
            }
            sum += aux; // increment
        }
    }
    return sum;
}

- (BOOL)isNumeric:(NSString*)s
{
    NSScanner *sc = [NSScanner scannerWithString: s];
    // We can pass NULL because we don't actually need the value to test
    // for if the string is numeric. This is allowable.
    if ( [sc scanFloat:NULL] )
    {
        // Ensure nothing left in scanner so that "42foo" is not accepted.
        // ("42" would be consumed by scanFloat above leaving "foo".)
        return [sc isAtEnd];
    }
    // Couldn't even scan a float :(
    return NO;
}



- (float) dataMiningSum:(NSString*)aEvent value:(float)aValue memory:(NSMutableArray*)aMemory valid:(BOOL*)aValid
{
    // by defaulf the data mining is valid
    [self setValid:aValid value:true];
    
    if([aMemory count] == 0)
    {
        return 0;
    }
    
    bool ok;
    float sum = 0;
    float aux;
    
    NSEnumerator* eMemoryEvent = [aMemory objectEnumerator];
    
    MemoryEvent* objectMemoryEvent;
    while( objectMemoryEvent = [eMemoryEvent nextObject] ) // Iterate all memory
    {
        if( ![[objectMemoryEvent event] caseInsensitiveCompare:aEvent] ) // Event found
        {
            if (strcmp([[objectMemoryEvent value] objCType], "f") || strcmp([[objectMemoryEvent value] objCType], "i") || strcmp([[objectMemoryEvent value] objCType], "d") || strcmp([[objectMemoryEvent value] objCType], "l")) {
                ok = true;
            }
            
            aux = [[objectMemoryEvent value] floatValue]; // convert value to qreal
            if( !ok ) // if the event value is not numeric
            {
                [self setValid: aValid value:false]; // mark has invalid datamining
                return 0;
            }
            
            if( aValue == aux )
            {
                sum += aux; // increment
            }        
        }
    }
    return sum;
}


/*
 Datamining Count counts all events with name event in memory 
 It is always valid datamining.
 */
- (float) dataMiningCount:(NSString*)aEvent memory:(NSMutableArray*)aMemory valid:(BOOL*)aValid
{
    // by defaulf the data mining is valid
    [self setValid:aValid value:true];
    
    if([aMemory count] == 0)
    {
        return 0;
    }
    
    int n = 0;
    
    NSEnumerator* eMemoryEvent = [aMemory objectEnumerator];
    MemoryEvent* objectMemoryEvent;
    while( objectMemoryEvent = [eMemoryEvent nextObject] ) // Iterate all memory
    {
        if( ![[objectMemoryEvent event] caseInsensitiveCompare:aEvent] ) // Event found
        {
            n++;
        }   
    }
    return n;
}

/*
 Datamining Count counts all events with name event and value in memory
 It is always valid datamining.
 */
- (float) dataMiningCount:(NSString*)aEvent value:(NSString*)aValue memory:(NSMutableArray*)aMemory valid:(BOOL*)aValid
{
    // by defaulf the data mining is valid
    [self setValid:aValid value:true];
    
    if([aMemory count] == 0)
    {
        return 0;
    }
    
    int n = 0;
    
    NSEnumerator* eMemoryEvent = [aMemory objectEnumerator];
    
    MemoryEvent* objectMemoryEvent;
    while( objectMemoryEvent = [eMemoryEvent nextObject] ) // Iterate all memory
    {
//        DLog(@"%@ - %@", [objectMemoryEvent event], [objectMemoryEvent value]);
//        DLog(@"%@ - %@", aEvent, aValue);
        
        if( ![[objectMemoryEvent event] caseInsensitiveCompare:aEvent] && ![[objectMemoryEvent value] caseInsensitiveCompare:aValue]) // Event found
        {
            n++;
        }   
    }
    DLog(@"dataMiningCount: %d",n);
    return n;
}


/*
 Datamining Mean only works if the values are numbers.
 If any value of the event is not a number, it will set valid to false.
 If the memory is empty or no event is found it will set valid to true, and return 0.
 */
- (float) dataMiningMean:(NSString*)aEvent memory:(NSMutableArray*)aMemory valid:(BOOL*)aValid
{
    // by defaulf the data mining is not valid
    [self setValid:aValid value:false];
    
    if([aMemory count] == 0)
    {
        return 0;
    }
    
    BOOL ok;
    float sum = 0;
    int n = 0;
    float aux;
    
    NSEnumerator* eMemoryEvent = [aMemory objectEnumerator];
    
    MemoryEvent* objectMemoryEvent;
    while( objectMemoryEvent = [eMemoryEvent nextObject] ) // Iterate all memory
    {
        if( ![[objectMemoryEvent event] caseInsensitiveCompare:aEvent] ) // Event found
        {
            if (strcmp([[objectMemoryEvent value] objCType], "f") || strcmp([[objectMemoryEvent value] objCType], "i") || strcmp([[objectMemoryEvent value] objCType], "d") || strcmp([[objectMemoryEvent value] objCType], "l")) {
                ok = true;
            }
            
            aux = [[objectMemoryEvent value] floatValue]; // convert value to qreal
            if( !ok ) // if the event value is not numeric
            {
                [self setValid: aValid value:false]; // mark has invalid datamining
                return 0;
            }
            
            sum += aux;
            n++;
        }
    }
    
    // Return 0, if no events were found
    return (n > 0 ? sum / n : 0); // return mean = sum / n
}



- (bool) dataMiningExists: (NSString*)aEvent memory:(NSMutableArray*)aMemory valid:(BOOL*)aValid
{
    // by defaulf the data mining is valid
    [self setValid:aValid value:true];
    
    if([aMemory count] == 0)
    {
        return 0;
    }
    
    
    NSEnumerator* eMemoryEvent = [aMemory objectEnumerator];
    
    MemoryEvent* objectMemoryEvent;
    while( objectMemoryEvent = [eMemoryEvent nextObject] ) // Iterate all memory
    {
        
        DLog(@"objectMemoryEvent event: %@", [objectMemoryEvent event]);
        if( ![[objectMemoryEvent event] caseInsensitiveCompare:aEvent] ) // Event found
        {
            return true;
        }
    }
    return false;
}



- (bool) dataMiningExists: (NSString*)aEvent value:(NSString*)aValue memory:(NSMutableArray*)aMemory valid:(BOOL*)aValid
{
    // by defaulf the data mining is valid
    [self setValid:aValid value:true];
    
    if([aMemory count] == 0)
    {
        return 0;
    }
    
    
    NSEnumerator* eMemoryEvent = [aMemory objectEnumerator];
    
    MemoryEvent* objectMemoryEvent;
    while( objectMemoryEvent = [eMemoryEvent nextObject] ) // Iterate all memory
    {
        if( ![[objectMemoryEvent event] caseInsensitiveCompare:aEvent] && ![[objectMemoryEvent value] caseInsensitiveCompare:aValue]) // Event found
        {
            return true;
        }
    }
    return false;
}


/*
 Dataminign Last. Return the value of the last event found
 If the memory is empty or the event is not found, set valid to false. Return an emtpy QString.
 */
- (NSString*) dataMiningLast: (NSString*)aEvent memory:(NSMutableArray*)aMemory valid:(BOOL*)aValid
{
    
//    DLog(@"dataMiningLast: %@",aEvent);
    
    // by defaulf the data mining is not valid
    [self setValid:aValid value:false];
    
    if([aMemory count] == 0)
    {
        return [NSString stringWithFormat:@""];
    }
    
    NSEnumerator* eMemoryEvent = [aMemory objectEnumerator];
    
    NSArray* aMemoryEvents = [eMemoryEvent allObjects];
    // start search from back
    MemoryEvent* objectMemoryEvent;
    
    for (int i = [aMemoryEvents count]-1; i>=0; i--) {
        objectMemoryEvent = [aMemoryEvents objectAtIndex:i];
        
        if( ![[objectMemoryEvent event] caseInsensitiveCompare:aEvent] ) // Event found
        {
            [self setValid:aValid value:true];
            return [objectMemoryEvent value];
            
        }
        
    }
    return [NSString stringWithFormat:@""];
}

/*
 Dataminign First. Return the value of the first event found
 If the memory is empty or the event is not found, set valid to false. Return an emtpy QString.
 */
- (NSString*) dataMiningFirst: (NSString*)aEvent memory:(NSMutableArray*)aMemory valid:(BOOL*)aValid
{
    // by defaulf the data mining is not valid
    [self setValid:aValid value:false];
    
    if([aMemory count] == 0)
    {
        return [NSString stringWithFormat:@""];
    }
    
    NSEnumerator* eMemoryEvent = [aMemory objectEnumerator];
    
    NSArray* aMemoryEvents = [eMemoryEvent allObjects];
    // start search from back
    MemoryEvent* objectMemoryEvent;
    
    for (int i = 0; i<[aMemoryEvents count]-1; i++) {
        objectMemoryEvent = [aMemoryEvents objectAtIndex:i];
        
        if( ![[objectMemoryEvent event] caseInsensitiveCompare:aEvent] ) // Event found
        {
            [self setValid:aValid value:true];
            return [objectMemoryEvent value];
            
        }
        
    }
    return [NSString stringWithFormat:@""];
}


- (NSString*) dataMiningDuration: (NSString*)aEvent memory:(NSMutableArray*)aMemory
{
    return [NSString stringWithFormat:@""];
}


- (NSString*) dataMiningTime: (NSString*)aEvent memory:(NSMutableArray*)aMemory;
{
    return [NSString stringWithFormat:@""];
}


- (void) setValid:(BOOL*)aValid value:(BOOL)aValue
{
    if (aValid != NULL) {
        *aValid = aValue;
    }
}

- (void) run
{        
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    while (true) {
        
        [_semaphoreBrain lockWhenCondition:HAS_DATA];
        
        if (_quit) {
            return;
        }
        
        DLog(@"Brain - run - HAS_DATA");
        int nEmotions;
        nEmotions = [_emotionsChanged count];
        
        // Execute the rules
        if ( _rules!=nil ) {
            _crutchEnabled = true;
            [_rules exec];
        }
        
        // remove the emotions changed since the last rules exection
        // if new emotions were added during the rules execution, they are not removed,
        // so that in the next iteration they can be handled
        for(int i = 0; i < nEmotions; i++)
        {
            NSString* emotionName = [_emotionsChanged dequeue];
            Emotion* e = [[Emotion alloc] init];
            
            for (Emotion* objectE in _emotions) {
                if (![[objectE name] caseInsensitiveCompare:emotionName]) {
                    e = objectE;
                }
            }
        }
        
        // Remove first perception added.
        if( [_receivedPerceptions count] != 0 )
        {
            Perception* p = [_receivedPerceptions dequeue];
            DLog(@"dequeue from _receivedPerceptions: %@ %@", [p name], [p value]);
        }
        
        [_semaphoreBrain unlockWithCondition:NO_DATA];
        
    }
    
    [pool release];
}



@end
