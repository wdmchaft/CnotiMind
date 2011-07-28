//
//  Brain.m
//  CnotiMind
//
//  Created by Gonçalo Rodrigues on 11/04/27.
//  Copyright 2011 Universidade de Coimbra. All rights reserved.
//

#import "Brain.h"

#import "GDataXMLNode.h"

#import "NSMutableArray+QueueAdditions.h"


#import "RootNode.h"
#import "ConditionPerceptionNode.h"
#import "ActionNode.h"


#import "CnotiMind.h"

@implementation Brain

@synthesize emotions = _emotions;
@synthesize receivedPerceptions = _receivedPerceptions;

- (id) init
{
    if (self == [super init]) {
        _emotions = [[NSMutableArray alloc] init];
        _receivedPerceptions = [[NSMutableArray alloc] init];
        
//        _semaphoreBrain = [[NSRecursiveLock alloc] init];       
//        [NSThread detachNewThreadSelector:@selector(startThreadRun) toTarget:self withObject:nil];
    }
    return self;
}


- (id) initWithPath:(NSString*)aPath
{
    if (self == [super init]) {
        
        _semaphoreBrain = [[NSLock alloc] init];
    
        //  [self loadXmlSettings:aPath];
        //  TODO
        //  [self initWithTarget:self selector:@selector(run) object:nil];
        //  [self run];

//        [NSThread detachNewThreadSelector:@selector(startThreadRun) toTarget:self withObject:nil];
    }
    return self;
}


//- (IBAction) startThreadRun
//{
//    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
//    // wait for 1 seconds before starting the thread, you don't have to do that. This is just an example how to stop the NSThread for some time  
//    [NSThread sleepForTimeInterval:1];  
//    [self performSelectorInBackground: @selector(run:) withObject:nil];  
//    [pool release];
//}


/**
 Load a XML file with settings.
 
 This method can me called several times, append new settings to the Brain.
 
 XML file can have Perceptions, Actions and Emotions
 */
- (BOOL) loadXmlSettings:(NSString*)aFilename
{
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:aFilename];
    NSError *error;
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData 
														   options:0 error:&error];    
    
    if (error) {
        return false;
    }
    
    else {
        //  Make the parsing
        NSArray *settingsMembers = [doc.rootElement elementsForName:@"Settings"];
        
        for (GDataXMLElement* settingsMember in settingsMembers) {
            
            //  Perceptions
            NSArray* perceptions = [settingsMember elementsForName:@"Perception"];
            
            int perceptionsCounter=0;
            for (GDataXMLElement* perceptionsMember in perceptions) {
                GDataXMLElement* perception = (GDataXMLElement*)[perceptions objectAtIndex:perceptionsCounter];
                
                NSString* name = [NSString stringWithFormat:@"%@", [perception attributeForName:@"name"]];
                NSString* type = [NSString stringWithFormat:@"%@", [perception attributeForName:@"type"]];
                
                //  TODO set brain
                [self addValidPerception:name];
                
                perceptionsCounter++;
            }
            
            //  Actions
            NSArray* actions = [settingsMember elementsForName:@"Action"];
            
            int actionsCounter=0;
            for (GDataXMLElement* actionsMember in actions) {
                GDataXMLElement* action = (GDataXMLElement*)[actions objectAtIndex:actionsCounter];
                
                NSString* name = [NSString stringWithFormat:@"%@", [action attributeForName:@"name"]];
                NSString* type = [NSString stringWithFormat:@"%@", [action attributeForName:@"type"]];
                
                //  TODO set brain
                [self addValidAction:name];
                
                actionsCounter++;
            }
            
            
            //  Emotions
            NSArray* emotions = [settingsMember elementsForName:@"Emotion"];
            
            int emotionsCounter=0;
            for (GDataXMLElement* emotionsMember in emotions) {
                GDataXMLElement* emotion = (GDataXMLElement*)[emotions objectAtIndex:emotionsCounter];
                
                NSString* name = [NSString stringWithFormat:@"%@", [emotion attributeForName:@"name"]];
                NSString* value = [NSString stringWithFormat:@"%@", [emotion attributeForName:@"value"]];
                NSString* min = [NSString stringWithFormat:@"%@", [emotion attributeForName:@"min"]];
                NSString* max = [NSString stringWithFormat:@"%@", [emotion attributeForName:@"max"]];
                NSString* decay = [NSString stringWithFormat:@"%@", [emotion attributeForName:@"decay"]];
                
                //  TODO set brain
                Emotion* e = [[Emotion alloc] initWithKeyAndValueAndMaxAndMin:name value:[value floatValue] max:[max floatValue] min:[min floatValue]];
                
                [self addEmotion:e];
                
                emotionsCounter++;
            }
            
        }
    }
    
    [doc release];
    [xmlData release];
    
    return true;
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

//  TODO
- (BOOL) loadXmlRules:(NSString*)aFilename
{
    
    RootNode* rootNode = [[RootNode alloc] initWithBrainAndParent:self parent:nil];
    _currentNode = rootNode;
    
    ConditionPerceptionNode* conditionPerceptionNode = [[ConditionPerceptionNode alloc] initWithKeyAndValueAndOperatorAndBrainAndParent:@"User Talk" value:@"Hello" operator:ConditionOperatorUndefined brain:self parent:rootNode];
    _parentNode = _currentNode;
    _currentNode = conditionPerceptionNode;
    
    ConditionDataMiningNode* conditionDataMiningNode = [[ConditionDataMiningNode alloc] initWithKeyAndValueAndOperatorAndOperationAndMemoryAndVariableAndCompareValueBrainAndParent:@"last" value:@"Hello" operator:ConditionOperatorUndefined operation:DMO_Undefined memory:UndefinedMemory variable:@"" compareValue:@"" brain:self parent:conditionPerceptionNode];
    _parentNode = _currentNode;
    _currentNode = conditionDataMiningNode;
    
    ActionNode* actionNode = [[ActionNode alloc] initWithKeyAndValueAndBrainAndParent:@"Talk" value:@"Hi there!" brain:self parent:conditionDataMiningNode];
    _parentNode = _currentNode;
    _currentNode = actionNode;
    
    _rules = rootNode;
    
    NSLog(@"Brain: loadXmlRules");
    
//    [actionNode exec];
    
    
    //    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:aFilename];
    //    NSError *error;
    //    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData 
    //														   options:0 error:&error];    
    //    
    //    if (error) {
    //        return false;
    //    }
    //    
    //    else {
    //        //  Make the parsing - must be recursive!!!
    //        NSArray *rulesMembers = [doc.rootElement elementsForName:@"Rules"];
    //        
    //        for (GDataXMLElement* rulesMember in rulesMembers) {
    //            
    //        }
    //    }
    //    
    //    [doc release];
    //    [xmlData release];
    //    
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
    while (objectLongTermMemory == [eLongTermMemory nextObject]) {
        xmlMemory = [xmlMemory stringByAppendingFormat:@"%@", [objectLongTermMemory toXML]];
    }
    
    xmlMemory = [xmlMemory stringByAppendingString:@"</LongTermMemory>\n"];
    xmlMemory = [xmlMemory stringByAppendingString:@"<WorkingMemory>\n"];
    
    NSEnumerator* eWorkingMemory = [_workingMemory objectEnumerator];
    MemoryEvent* objectWorkingMemory;
    while (objectWorkingMemory == [eWorkingMemory nextObject]) {
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
    NSString* settings = [NSString stringWithFormat:@""];
    settings = [settings stringByAppendingString:@"--- Valid Perceptions ---\n"];    
    
    if ([_validPerceptions count] == 0) {
        settings = [settings stringByAppendingString:@"No Perceptions defined\n"];            
    }
    else {
        NSEnumerator* ePerceptions = [_workingMemory objectEnumerator];
        Perception* objectPerception;
        while (objectPerception == [ePerceptions nextObject]) {
            settings = [settings stringByAppendingFormat:@"%@", [objectPerception description]];
        }
    }
    
    
    settings = [settings stringByAppendingString:@"--- Valid Actions ---\n"];    
    
    if ([_validActions count] == 0) {
        settings = [settings stringByAppendingString:@"No Actions defined\n"];            
    }
    else {
        NSEnumerator* eActions = [_validActions objectEnumerator];
        Perception* objectAction;
        while (objectAction == [eActions nextObject]) {
            settings = [settings stringByAppendingFormat:@"%@", [objectAction description]];
        }
    }
    
    
    settings = [settings stringByAppendingString:@"--- Emotions ---\n"];    
    
    if ([_validActions count] == 0) {
        settings = [settings stringByAppendingString:@"No Emotions defined\n"];            
    }
    else {
        NSEnumerator* eEmotions = [_emotions objectEnumerator];
        Perception* objectEmotion;
        while (objectEmotion == [eEmotions nextObject]) {
            settings = [settings stringByAppendingFormat:@"%@", [objectEmotion description]];
        }
    }
    
    NSLog(@"--- %@", settings);
}


- (void) printRules
{
    [_rules description];
}


- (void) receivePerception:(Perception*)aPerception
{
    [_receivedPerceptions enqueue:aPerception];
    
    //  Trigger the brain
    [self run];
}


//  TODO
- (void) stop
{
    
}


//  TODO (just check if it's ok)
- (void) sendAction:(NSString*)aKey value:(NSString*)aValue
{
    
    NSMutableDictionary* action = [[NSMutableDictionary alloc] init];
    [action setObject:aValue forKey:aKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SEND_ACTION" object:action];
    
}


//  TODO (just check if it's ok)
- (void) sendEmotionalState:(NSString*)aKey value:(NSString*)aValue
{
    NSMutableDictionary* action = [[NSMutableDictionary alloc] init];
    [action setObject:aValue forKey:aKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SEND_EMOTIONAL_STATE" object:action];  
}




- (void) updateEmotionValue:(NSString*)aEmotionName variation:(NSNumber*)aVariation
{
    [self updateEmotionValue:aEmotionName variation:aVariation max:[NSNumber numberWithInt: INT8_MAX] min:[NSNumber numberWithInt: INT8_MIN] ];
}

- (void) updateEmotionValue:(NSString*)aEmotionName variation:(NSNumber*)aVariation max:(NSNumber*)aMax min:(NSNumber*)aMin
{
    
    NSEnumerator* eEmotions = [_emotions objectEnumerator];
    Perception* objectEmotion;
    while (objectEmotion == [eEmotions nextObject]) {
        
        if ([[objectEmotion value] isEqual:aEmotionName] == TRUE) {
            
            //  TODO: send signal
            //  emit sendEmotionalState( emotionName, e.value() );
            
            [_emotionsChanged enqueue:aEmotionName];
            [self run];
            
            //  TODO: release signal
            //  if(_semaphoreBrain.available() == 0)
            //  {
            //      _semaphoreBrain.release();
            //  }
            //  break;
        }
    }
}


- (void) executeAction:(NSString*)aKey value:(NSString*)aValue
{
    //  TODO: send signal
    NSMutableDictionary* action = [[NSMutableDictionary alloc] init];
    [action setObject:aValue forKey:aKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EXECUTE_ACTION" object:action];
}


- (id) dataMining: (enum DataMiningOperation)aOperation event:(NSString*)aEvent memoryType:(enum MemoryType)aMemoryType valid:(BOOL*)aValid
{
    // test if parameters are valid for datamining
    if( [aEvent length]==0 )
    {
        [self setValid: aValid value:false];
        return [NSString stringWithFormat:@""];
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
    
    // test if parameters are valid for datamining
    if( [aEvent length]==0 )
    {
        [self setValid: aValid value:false];
        return [NSString stringWithFormat:@""];
    }
    
    
    // if value is empty, do datamining without the value
    if( [aValue length]==0 )
    {
        return [self dataMining:aOperation event:aEvent value:aValue memoryType:aMemoryType valid:aValid];
    }
    
    // get the memory to performe data mining
    NSMutableArray* memory = (aMemoryType == WorkingMemory ? _workingMemory : _longTermMemory);
    [self setValid: aValid value:true];
    
    switch (aOperation) {
        case DMO_Count:
            return [[NSNumber alloc] initWithFloat:[self dataMiningCount:aEvent value:aValue memory:memory valid:aValid]];
            break;
        case DMO_Exists:
            return [[NSNumber alloc] initWithBool:[self dataMiningExists:aEvent value:aValue memory:memory valid:aValid]];
            break;
            
        default:
            break;
    }
    
    [self setValid: aValid value:false];
    return [NSString stringWithFormat:@""];
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
    while( objectMemoryEvent == [eMemoryEvent nextObject] ) // Iterate all memory
    {
        //  MemoryEvent* me = [eMemoryEvent nextObject];
        
        if( [[objectMemoryEvent event] isEqualToString:aEvent] ) // Event found
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
    while( objectMemoryEvent == [eMemoryEvent nextObject] ) // Iterate all memory
    {
        //  MemoryEvent* me = [eMemoryEvent nextObject];
        
        if( [[objectMemoryEvent event] isEqualToString:aEvent] ) // Event found
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
    while( objectMemoryEvent == [eMemoryEvent nextObject] ) // Iterate all memory
    {
        if( [[objectMemoryEvent event] isEqualToString:aEvent] ) // Event found
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
            sum += aux; // increment
        }
    }
    return sum;
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
    while( objectMemoryEvent == [eMemoryEvent nextObject] ) // Iterate all memory
    {
        if( [[objectMemoryEvent event] isEqualToString:aEvent] ) // Event found
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
    while( objectMemoryEvent == [eMemoryEvent nextObject] ) // Iterate all memory
    {
        if( [[objectMemoryEvent event] isEqualToString:aEvent] ) // Event found
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
    while( objectMemoryEvent == [eMemoryEvent nextObject] ) // Iterate all memory
    {
        if( [[objectMemoryEvent event] isEqualToString:aEvent] && [[objectMemoryEvent value] isEqual:aValue]) // Event found
        {
            n++;
        }   
    }
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
    while( objectMemoryEvent == [eMemoryEvent nextObject] ) // Iterate all memory
    {
        if( [[objectMemoryEvent event] isEqualToString:aEvent] ) // Event found
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
    while( objectMemoryEvent == [eMemoryEvent nextObject] ) // Iterate all memory
    {
        if( [[objectMemoryEvent event] isEqualToString:aEvent] ) // Event found
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
    while( objectMemoryEvent == [eMemoryEvent nextObject] ) // Iterate all memory
    {
        if( [[objectMemoryEvent event] isEqualToString:aEvent] && [[objectMemoryEvent value] isEqual:aValue]) // Event found
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
    
    for (int i = [aMemoryEvents count]-1; i>0; i--) {
        objectMemoryEvent = [aMemoryEvents objectAtIndex:i];
        
        if( [[objectMemoryEvent event] isEqualToString:aEvent] ) // Event found
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
        
        if( [[objectMemoryEvent event] isEqualToString:aEvent] ) // Event found
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
        aValid = &aValue;
    }
}

- (void) run
{        
    NSLog(@"brain running...");
    
    int nEmotions;
    nEmotions = [_emotionsChanged count];

    
    NSLog(@"---1");
    // Execute the rules
    if (_rules!=nil) {
        
        NSLog(@"---2");
        [_rules info:1];
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
            if ([[objectE key] isEqual:emotionName]) {
                e = objectE;
            }
        }
    }
    
    // Remove first perception added.
    if( [_receivedPerceptions count] != 0 )
    {
        Perception* p = [_receivedPerceptions dequeue];
    }
}



@end