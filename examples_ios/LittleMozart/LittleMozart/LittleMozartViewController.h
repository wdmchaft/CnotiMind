//
//  LittleMozartViewController.h
//  LittleMozart
//
//  Created by Gonçalo Rodrigues on 10/10/11.
//  Copyright 2011 Universidade de Coimbra. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LittleMozartViewController : UIViewController {
    UIButton *btnNoteDo;
    UIButton *btnNoteRe;
    UIButton *btnNoteMi;
    UIButton *btnNoteFa;
    UIButton *btnNoteSol;
    UIButton *btnNoteLa;
    UIButton *btnNoteSi;
    UIButton *btnNoteDo2;
    UIButton *btnNotePause;
    UIButton *btnDuration01;
    UIButton *btnDuration02;
    UIButton *btnDuration03;
    UIButton *btnDuration04;
}

@property (nonatomic, retain) IBOutlet UIButton *btnNoteDo;
@property (nonatomic, retain) IBOutlet UIButton *btnNoteRe;
@property (nonatomic, retain) IBOutlet UIButton *btnNoteMi;
@property (nonatomic, retain) IBOutlet UIButton *btnNoteFa;
@property (nonatomic, retain) IBOutlet UIButton *btnNoteSol;
@property (nonatomic, retain) IBOutlet UIButton *btnNoteLa;
@property (nonatomic, retain) IBOutlet UIButton *btnNoteSi;
@property (nonatomic, retain) IBOutlet UIButton *btnNoteDo2;
@property (nonatomic, retain) IBOutlet UIButton *btnNotePause;

@property (nonatomic, retain) IBOutlet UIButton *btnDuration01;
@property (nonatomic, retain) IBOutlet UIButton *btnDuration02;
@property (nonatomic, retain) IBOutlet UIButton *btnDuration03;
@property (nonatomic, retain) IBOutlet UIButton *btnDuration04;


- (IBAction)btnNoteDoTouch:(id)sender;
- (IBAction)btnNotereTouch:(id)sender;
- (IBAction)btnNoteMiTouch:(id)sender;
- (IBAction)btnNoteFaTouch:(id)sender;
- (IBAction)btnNoteSolTouch:(id)sender;
- (IBAction)btnNoteLaTouch:(id)sender;
- (IBAction)btnNoteSiTouch:(id)sender;
- (IBAction)btnNoteDo2Touch:(id)sender;
- (IBAction)btnNotePauseTouch:(id)sender;

@end