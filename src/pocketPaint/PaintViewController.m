/**
 *  Copyright (C) 2010-2014 The Catrobat Team
 *  (http://developer.catrobat.org/credits)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or (at your option) any later version.
 *
 *  An additional term exception under section 7 of the GNU Affero
 *  General Public License, version 3, is available at
 *  (http://developer.catrobat.org/license_additional_term)
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program.  If not, see http://www.gnu.org/licenses/.
 */

#import "PaintViewController.h"
#import "ColorPickerViewController.h"
#import "BrushPickerViewController.h"
#import "YKImageCropperView.h"
#import "LCTableViewPickerControl.h"
#import "UIImage+Rotate.h"
#import "ImageHelper.h"
#import "UIViewController+KNSemiModal.h"
#import "UIColor+CatrobatUIColorExtensions.h"

//Helper
#import "RGBAHelper.h"
//Tools
#import "FillTool.h"
#import "DrawTool.h"
#import "LineTool.h"
#import "PipetteTool.h"
#import "MirrorRotationZoomTool.h"
#import "ImagePicker.h"
#import "UndoManager.h"
#import "HandTool.h"
#import "ResizeViewManager.h"
#import "PointerTool.h"


#define kStackSize 5
#define kFillTolerance 70
#define kMaxZoomScale 5.0f
#define kMinZoomScale 0.25f
#define kControlSize 45.0f
@interface PaintViewController ()

@property (nonatomic,strong) NSArray *actionTypeArray;
@property (nonatomic,strong) UIToolbar *toolBar;
@property (nonatomic,strong) YKImageCropperView *cropperView;


//Gestures
@property (nonatomic,strong) UITapGestureRecognizer *fillRecognizer;

@property (nonatomic,strong) UIBarButtonItem* colorBarButtonItem;
@property (nonatomic,strong) NSMutableArray *undoArray;
@property (nonatomic,strong) NSMutableArray *redoArray;

@property (nonatomic,strong) DrawTool* drawTool;
@property (nonatomic,strong) LineTool* lineTool;
@property (nonatomic,strong) PipetteTool* pipetteTool;
@property (nonatomic,strong) FillTool* fillTool;
@property (nonatomic,strong) MirrorRotationZoomTool* mirrorRotationZoomTool;
@property (nonatomic,strong) ImagePicker* imagePicker;
@property (nonatomic,strong) UndoManager* undoManager;
@property (nonatomic,strong) HandTool* handTool;
@property (nonatomic,strong) ResizeViewManager* resizeViewManager;
@property (nonatomic,strong) PointerTool* pointerTool;

@end

@implementation PaintViewController
@synthesize undoManager = _undomanager;
- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  _red = 0.0/255.0;
  _green = 0.0/255.0;
  _blue = 0.0/255.0;
  _thickness = 10.0;
  _opacity = 1.0;
//  enabled = YES;
  _isEraser = NO;
  _horizontal = NO;
  _vertical = NO;
  _ending = Round;
  _activeAction = brush;
  _degrees = 0;

  self.actionTypeArray = @[@(brush),@(eraser),@(crop),@(pipette),@(mirror),@(image),@(line),@(rectangle),@(ellipse),@(stamp),@(rotate),@(zoom),@(fillTool),@(pointer)];
  
  self.drawTool = [[DrawTool alloc] initWithDrawViewCanvas:self];
  self.lineTool = [[LineTool alloc] initWithDrawViewCanvas:self];
  self.pipetteTool = [[PipetteTool alloc] initWithDrawViewCanvas:self];
  self.fillTool = [[FillTool alloc] initWithDrawViewCanvas:self];
  self.mirrorRotationZoomTool = [[MirrorRotationZoomTool alloc] initWithDrawViewCanvas:self];
  self.imagePicker = [[ImagePicker alloc] initWithDrawViewCanvas:self];
  self.resizeViewManager = [[ResizeViewManager alloc] initWithDrawViewCanvas:self andImagePicker:self.imagePicker];
  self.pointerTool = [[PointerTool alloc] initWithDrawViewCanvas:self];
  self.undoManager  = [[UndoManager alloc] initWithDrawViewCanvas:self];
  self.handTool = [[HandTool alloc] initWithDrawViewCanvas:self];
  
  [self setupCanvas];
  [self setupZoom];
  [self setupToolbar];
  [self setupUndoManager];
  [self setupNavigationBar];
  self.colorBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"color"] style:UIBarButtonItemStylePlain target:self action:@selector(colorAction)];

}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark initView

-(void)setupCanvas
{
  NSInteger height = (NSInteger)self.view.frame.size.height-self.navigationController.toolbar.frame.size.height;
  CGRect rect = CGRectMake(0, 0, self.view.frame.size.width, height);
  self.drawView = [[UIImageView alloc] initWithFrame:rect];
  self.saveView = [[UIImageView alloc] initWithFrame:rect];
  //add blank image at the beginning
  UIGraphicsBeginImageContextWithOptions(self.saveView.frame.size, NO, 0.0);
  UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  self.saveView.image = blank;
  
//  [self manageUndo:image];
  self.saveView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]];
//  self.drawView.backgroundColor = [UIColor yellowColor];

  self.helper = [[UIView alloc] initWithFrame:rect];
//  self.helper.backgroundColor = [UIColor redColor];

  self.drawGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self.drawTool action:@selector(draw:)];
  self.drawGesture.delegate = self;
  [self.view addGestureRecognizer:self.drawGesture];
  
  self.lineToolGesture  = [[UIPanGestureRecognizer alloc] initWithTarget:self.lineTool action:@selector(drawLine:)];
  self.lineToolGesture.delegate = self;
  [self.view addGestureRecognizer:self.lineToolGesture];
  self.lineToolGesture.enabled = NO;
  
  self.pipetteRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self.pipetteTool action:@selector(pipetteAction:)];
  self.pipetteRecognizer.delegate = self;
  [self.view addGestureRecognizer:self.pipetteRecognizer];
  self.pipetteRecognizer.enabled = NO;
  
  self.fillRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self.fillTool action:@selector(fillAction:)];
  self.fillRecognizer.delegate = self;
  [self.view addGestureRecognizer:self.fillRecognizer];
  self.fillRecognizer.enabled = NO;

  [self.helper addSubview:self.saveView];
  [self.helper addSubview:self.drawView];
//  [self.helper addSubview:self.resizeViewManager.resizeImageView];
  [self.helper addSubview:self.resizeViewManager.resizeViewer];
  [self.helper addSubview:self.pointerTool.pointerView];
  
}


-(void)setupZoom
{
  self.scrollView = [[UIScrollView alloc] initWithFrame:self.saveView.frame];
  self.scrollView.scrollEnabled = NO;
  self.scrollView.maximumZoomScale = kMaxZoomScale;
  self.scrollView.minimumZoomScale = kMinZoomScale;
  self.scrollView.zoomScale = 0.25f;
  self.scrollView.delegate = self;
  
  [self.scrollView addSubview:self.helper];
  [self.view addSubview:self.scrollView];
}

-(void)setupToolbar
{
  [self.navigationController setToolbarHidden:NO];
  self.navigationController.toolbar.barStyle = UIBarStyleBlack;
  self.navigationController.toolbar.barTintColor = [UIColor navBarColor];
  self.navigationController.toolbar.tintColor = [UIColor lightOrangeColor];
  self.navigationController.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
  [self updateToolbar];
  
}

-(void)setupNavigationBar
{
  self.navigationController.navigationBarHidden = NO;
  self.navigationController.navigationBar.tintColor = [UIColor lightOrangeColor];
  self.navigationItem.title = @"Pocket Paint";
  UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(editAction)];
  self.navigationItem.rightBarButtonItem = editButton;
}

-(void)editAction
{
  UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Select option:" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
                          @"Save to CameraRoll",
                          @"Save & Close Paint",
                          @"Discard & Close",
                          @"New Canvas",
                          nil];
  popup.tag = 1;
  [popup showInView:[UIApplication sharedApplication].keyWindow];
}

-(void)setupUndoManager
{
  self.undoArray = [[NSMutableArray alloc] initWithCapacity:kStackSize];
  self.redoArray = [[NSMutableArray alloc] initWithCapacity:kStackSize];
}

#pragma mark scrollView delegate

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
  return self.helper;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
  
  // center the image as it becomes smaller than the size of the screen
  CGSize boundsSize = scrollView.bounds.size;
  CGRect frameToCenter = self.helper.frame;
  
  // center horizontally
  if (frameToCenter.size.width < boundsSize.width)
  {
    frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
  } else {
    frameToCenter.origin.x = 0;
  }
  
  // center vertically
  if (frameToCenter.size.height < boundsSize.height)
  {
    frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2 - self.navigationController.navigationBar.frame.size.height / 2;
  } else {
    frameToCenter.origin.y = 0;
  }
  self.helper.frame = frameToCenter;

}

#pragma mark changing tool / toolbarItems

-(void)changeAction
{
  LCTableViewPickerControl *pickerView = [[LCTableViewPickerControl alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, kPickerControlAgeHeight) title:@"Please pick an item" value:self.activeAction items:self.actionTypeArray offset:CGPointMake(0, 0)];
  [pickerView setDelegate:self];
  self.navigationController.toolbarHidden = YES;
  [pickerView setTag:0];
  [self setBackAllActions];
  self.drawGesture.enabled = NO;
  self.lineToolGesture.enabled = NO;
  [self.view addSubview:pickerView];
  self.pipetteRecognizer.enabled = NO;
  [pickerView showInView:self.scrollView];
}

-(void) updateToolbar
{
  UIBarButtonItem* action = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tools"] style:UIBarButtonItemStylePlain target:self action:@selector(changeAction)];
  self.handToolBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hand"] style:UIBarButtonItemStylePlain target:self.handTool action:@selector(changeHandToolAction)];
  self.undo = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"undo"] style:UIBarButtonItemStylePlain target:self action:@selector(undoAction)];
  self.redo = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"redo"] style:UIBarButtonItemStylePlain target:self action:@selector(redoAction)];
  [self.undoManager updateUndoToolBarItems];
  
  self.colorBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"color"] style:UIBarButtonItemStylePlain target:self action:@selector(colorAction)];
  self.colorBarButtonItem.tintColor = [UIColor colorWithRed:self.red green:self.green blue:self.blue alpha:self.opacity];
  switch (self.activeAction) {
    case brush:{
      UIBarButtonItem* brushPicker = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"thickness"] style:UIBarButtonItemStylePlain target:self action:@selector(brushAction)];
      self.toolbarItems = [NSArray arrayWithObjects: action, self.handToolBarButtonItem ,brushPicker,self.colorBarButtonItem,self.undo,self.redo, nil];
      }
      break;
    case eraser:{
      UIBarButtonItem* brushPicker = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"thickness"] style:UIBarButtonItemStylePlain target:self action:@selector(brushAction)];
      self.toolbarItems = [NSArray arrayWithObjects: action, self.handToolBarButtonItem ,brushPicker,self.undo,self.redo, nil];
    }
      break;
    case crop:{
      UIBarButtonItem* crop = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"crop_cut"] style:UIBarButtonItemStylePlain target:self action:@selector(cropAction)];
      self.toolbarItems = [NSArray arrayWithObjects: action, self.handToolBarButtonItem ,crop,self.undo,self.redo, nil];
    }
      break;
    case pipette:{
      self.toolbarItems = [NSArray arrayWithObjects: action, self.handToolBarButtonItem, self.colorBarButtonItem,self.undo,self.redo, nil];
    }
      break;
    case mirror:{
      UIBarButtonItem* mirrorVertical = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mirror_vertical"] style:UIBarButtonItemStylePlain target:self.mirrorRotationZoomTool action:@selector(mirrorVerticalAction)];
      UIBarButtonItem* mirrorHorizontal = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mirror_horizontal"] style:UIBarButtonItemStylePlain target:self.mirrorRotationZoomTool action:@selector(mirrorHorizontalAction)];
      self.toolbarItems = [NSArray arrayWithObjects: action, self.handToolBarButtonItem ,mirrorVertical,mirrorHorizontal,self.undo,self.redo, nil];
    }
      break;
    case image:{
      UIBarButtonItem* camera = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self.imagePicker action:@selector(cameraImagePickerAction)];
      UIBarButtonItem* cameraRoll = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"image_select"] style:UIBarButtonItemStylePlain target:self.imagePicker action:@selector(imagePickerAction)];
      self.toolbarItems = [NSArray arrayWithObjects: action, self.handToolBarButtonItem , camera, cameraRoll,self.undo,self.redo, nil];
    }
      break;
    case line:{
      UIBarButtonItem* brushPicker = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"thickness"] style:UIBarButtonItemStylePlain target:self action:@selector(brushAction)];
      self.toolbarItems = [NSArray arrayWithObjects: action, self.handToolBarButtonItem ,brushPicker, self.colorBarButtonItem,self.undo,self.redo, nil];
    }
      break;
    case ellipse:
    case rectangle:
    {
      self.toolbarItems = [NSArray arrayWithObjects: action, self.handToolBarButtonItem ,self.colorBarButtonItem,self.undo,self.redo, nil];
    }
      break;
      
    case stamp:
    {
      UIBarButtonItem* newStamp = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"stamp"] style:UIBarButtonItemStylePlain target:self action:@selector(stampAction)];
      self.toolbarItems = [NSArray arrayWithObjects: action, self.handToolBarButtonItem ,newStamp,self.undo,self.redo, nil];
    }
      break;
    case rotate:{
      UIBarButtonItem* rotateRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self.mirrorRotationZoomTool action:@selector(rotateRight)];
      UIBarButtonItem* rotateLeft = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self.mirrorRotationZoomTool action:@selector(rotateLeft)];
      self.toolbarItems = [NSArray arrayWithObjects: action, self.handToolBarButtonItem ,rotateLeft,rotateRight,self.undo,self.redo, nil];
    }
      break;
    case zoom:{
      UIBarButtonItem* zoomIn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"zoom_in"] style:UIBarButtonItemStylePlain target:self.mirrorRotationZoomTool action:@selector(zoomIn)];
      UIBarButtonItem* zoomOut = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"zoom_out"] style:UIBarButtonItemStylePlain target:self.mirrorRotationZoomTool action:@selector(zoomOut)];
      self.toolbarItems = [NSArray arrayWithObjects: action, self.handToolBarButtonItem ,zoomIn,zoomOut,self.undo,self.redo, nil];
    }
      break;
    case fillTool:{
      self.toolbarItems = [NSArray arrayWithObjects: action, self.handToolBarButtonItem ,self.colorBarButtonItem,self.undo,self.redo, nil];
    }
      break;
    case pointer:{
      UIBarButtonItem* brushPicker = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"thickness"] style:UIBarButtonItemStylePlain target:self action:@selector(brushAction)];
     self.pointerToolBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"pointer"] style:UIBarButtonItemStylePlain target:self.pointerTool action:@selector(drawingChangeAction)];
    self.toolbarItems = [NSArray arrayWithObjects: action, self.handToolBarButtonItem ,brushPicker,self.colorBarButtonItem,self.pointerToolBarButtonItem,self.undo,self.redo, nil];
    }
      break;
    default:
      break;
  }
  self.navigationController.toolbarHidden = NO;
}

-(void)setBackAllActions
{
  self.isEraser = NO;
  self.resizeViewManager.gotImage = NO;
  self.saveView.hidden = NO;
  
  self.drawGesture.enabled = NO;
  self.lineToolGesture.enabled = NO;
  self.pipetteRecognizer.enabled = NO;
  self.fillRecognizer.enabled = NO;
  
  [self.handTool disableHandTool];
  self.pointerToolBarButtonItem.tintColor = [UIColor lightOrangeColor];
  if (self.resizeViewManager.resizeViewer.hidden == NO) {
      [self.resizeViewManager hideResizeView];
  }
  if (self.pointerTool.pointerView.hidden == NO) {
      [self.pointerTool disable];
  }
  if (self.cropperView) {
    [self.cropperView removeFromSuperview];
    self.cropperView = nil;
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.drawView.hidden = NO;
    self.saveView.hidden = NO;
    self.helper.hidden = NO;
//    enabled = YES;
    for (UIGestureRecognizer *recognizer in [self.scrollView gestureRecognizers]) {
      recognizer.enabled = YES;
    }
  }
}

-(void)updateActiveAction:(id)item
{
  self.activeAction = [item intValue];
  [self setBackAllActions];
  
  switch (self.activeAction) {
    case brush:
      self.drawGesture.enabled = YES;
      break;
    case eraser:
      [self eraserAction];
      break;
    case crop:
      [self cropInitAction];
      break;
    case pipette:
      [self initPipette];
      break;
    case mirror:
      break;
    case image:
      break;
    case stamp:
      [self initStamp];
      [self.resizeViewManager showResizeView];
      break;
    case line:
      self.lineToolGesture.enabled = YES;
      break;
    case rectangle:
    case ellipse:
      [self.resizeViewManager showResizeView];
      [self initShape];
      break;
    case rotate:
      break;
    case fillTool:
      [self initFillTool];
      break;
    case pointer:
      [self initPointerTool];
      break;
    default:
      break;
  }

}

#pragma mark undo/redo

- (void)undoAction
{

  if (self.undoManager.canUndo) {
    [self.undoManager undo];
    NSLog(@"undo");
  }else{
  }
  [self.undoManager updateUndoToolBarItems];
 
}
- (void)redoAction
{
  
  if (self.undoManager.canRedo) {
    [self.undoManager redo];
     NSLog(@"redo");
  }else{
  }
  [self.undoManager updateUndoToolBarItems];
}

#pragma mark initActions for tools

- (void)eraserAction
{
  self.isEraser = YES;
  self.drawView.image = self.saveView.image;
  self.drawGesture.enabled = YES;
  self.saveView.hidden = YES;
}

-(void)cropInitAction
{
  if (self.saveView.image) {
    self.cropperView = [[YKImageCropperView alloc] initWithImage:self.saveView.image andFrame:self.view.frame];
    [self.view addSubview:self.cropperView];
    self.drawView.hidden = YES;
    self.saveView.hidden = YES;
    self.helper.hidden = YES;
//    enabled = NO;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    for (UIGestureRecognizer *recognizer in [self.scrollView gestureRecognizers]) {
      recognizer.enabled = NO;
    }
  } else {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Nothing to crop!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
  }
  
}

-(void)initPipette
{
  //PipetteAction
  self.pipetteRecognizer.enabled = YES;
}

-(void)initFillTool
{
  self.fillRecognizer.enabled = YES;
}

-(void)initPointerTool
{
  self.pointerTool.drawingEnabled = NO;
  self.pointerTool.pointerView.hidden = NO;
  self.pointerTool.moveView.enabled = YES;
  self.pointerTool.colorView.hidden = YES;
  self.drawView.userInteractionEnabled = YES;
}

-(void)initShape
{
  self.resizeViewManager.resizeViewer.frame = CGRectMake(0, 0, 150, 150);
  self.resizeViewManager.resizeViewer.bounds = CGRectMake(self.resizeViewManager.resizeViewer.bounds.origin.x , self.resizeViewManager.resizeViewer.bounds.origin.y , 150 , 150);
//  [self.scrollView zoomToRect:CGRectMake(0, 0, 500, 500) animated:YES];
  [self.resizeViewManager updateShape];
}

-(void)initStamp
{
//  self.resizeViewManager.border.hidden = NO;
  self.resizeViewManager.resizeViewer.contentView.image = nil;
}

#pragma mark tool actions

-(void)cropAction
{
  if ([self.cropperView superview] == self.view) {
    UIImage* croppedImage = [self.cropperView editedImage];
    self.drawView.image = nil;
    CGSize boundsSize = croppedImage.size;
    self.helper.frame = CGRectMake(0, 0, boundsSize.width*self.scrollView.zoomScale, boundsSize.height*self.scrollView.zoomScale);
    self.saveView.frame =CGRectMake(0, 0, (NSInteger)boundsSize.width, (NSInteger)boundsSize.height);
    self.drawView.frame =CGRectMake(0, 0, (NSInteger)boundsSize.width, (NSInteger)boundsSize.height);
    self.saveView.image = croppedImage;
    self.drawView.image = nil;
    self.drawView.hidden = NO;
    self.saveView.hidden = NO;
    self.helper.hidden = NO;
      //  enabled = YES;
    [self.cropperView removeFromSuperview];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    for (UIGestureRecognizer *recognizer in [self.scrollView gestureRecognizers]) {
      recognizer.enabled = YES;
    }
    [self.scrollView zoomToRect:CGRectMake(0, 0, 500, 500) animated:YES];
  } else {
    [self cropInitAction];
  }
  
}

-(void)stampAction
{
  self.resizeViewManager.gotImage = NO;
  self.resizeViewManager.resizeViewer.contentView.image = nil;
}


#pragma mark change color/thickness

-(void)colorAction
{
  UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
  ColorPickerViewController *cvc = [storyboard instantiateViewControllerWithIdentifier:@"colorPicker"];
  cvc.delegate = self;
  cvc.red = self.red;
  cvc.green = self.green;
  cvc.blue = self.blue;
  cvc.opacity = self.opacity;
//  self.view.userInteractionEnabled = NO;
//  enabled = NO;
  [self presentViewController:cvc animated:YES completion:nil];
}

-(void)brushAction
{
  BrushPickerViewController *bvc = [[BrushPickerViewController alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height*0.5, self.view.frame.size.width, self.view.frame.size.height*0.5) andController:self];
  bvc.delegate = self;
  
  [self presentSemiViewController:bvc];
}




#pragma mark tool helpers

-(void)setImagePickerImage:(UIImage*)image
{
  CGFloat width = image.size.width;
  CGFloat height = image.size.height;
  
  self.resizeViewManager.scale = 150.0f / width;
  height = height * self.resizeViewManager.scale;
  width = width * self.resizeViewManager.scale;
  image = [RGBAHelper resizeImage:image withWidth:(int)width withHeight:(int)height];
//  self.resizeViewManager.border.frame = CGRectMake(0, 0,
//                                 (int)width,
//                                 (int)height);
  self.resizeViewManager.resizeViewer.bounds = CGRectMake(self.resizeViewManager.resizeViewer.bounds.origin.x, self.resizeViewManager.resizeViewer.bounds.origin.y,
                                           (int)width,
                                           (int)height);
  
  self.resizeViewManager.resizeViewer.contentView.image = image;
  self.resizeViewManager.resizeViewer.contentMode = UIViewContentModeTop;
  [self.resizeViewManager showResizeView];
}
#pragma mark actionPicker delegate

- (void)dismissPickerControl:(LCTableViewPickerControl*)view
{
  [view dismiss];
}

- (void)selectControl:(LCTableViewPickerControl*)view didSelectWithItem:(id)item
{
  /*
   Check item is NSString or NSNumber , if it is necessary
   */
  if (view.tag == 0)
  {
    [self updateActiveAction:item];
    [self updateToolbar];
  }
  
  [self dismissPickerControl:view];
}

- (void)selectControl:(LCTableViewPickerControl *)view didCancelWithItem:(id)item
{
  [self updateActiveAction:item];
  [self updateToolbar];
  [self dismissPickerControl:view];
}

#pragma mark brush/color delegate

-(void)closeBrushPicker:(id)sender
{
  self.thickness = ((BrushPickerViewController*)sender).brush;
  self.ending = ((BrushPickerViewController*)sender).brushEnding;
//  self.view.userInteractionEnabled = YES;
//  enabled = YES;
  if (self.activeAction == pointer) {
    [self.pointerTool updateColorView];
  }
  [self dismissSemiModalView];
}
-(void)closeColorPicker:(id)sender
{
  self.red =((ColorPickerViewController*)sender).red;
  self.green =((ColorPickerViewController*)sender).green;
  self.blue =((ColorPickerViewController*)sender).blue;
  self.opacity =((ColorPickerViewController*)sender).opacity;
//  self.view.userInteractionEnabled = YES;
  [self updateToolbar];
//  enabled = YES;
  if (self.activeAction == rectangle || self.activeAction == ellipse) {
    [self.resizeViewManager updateShape];
  }
  if (self.activeAction == pointer) {
    [self.pointerTool updateColorView];
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark actionSheetDelegate

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
  
  switch (popup.tag) {
    case 1: {
      switch (buttonIndex) {
        case 0:
          [self saveAction];
          break;
        case 1:
          [self saveAndCloseAction];
          break;
        case 2:
          [self discardAndCloseAction];
          break;
        case 3:
          [self newCanvasAction];
          break;
        default:
          break;
      }
      break;
    }
    default:
      break;
  }
}



#pragma mark actionSheetActions

- (void)saveAction
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    UIImageWriteToSavedPhotosAlbum(self.saveView.image, nil, nil, nil);
  });
    NSLog(@"saved to Camera Roll");
}
- (void)saveAndCloseAction
{
  NSLog(@"save and close");
}
- (void)discardAndCloseAction
{
  NSLog(@"don't save and close");
}
- (void)newCanvasAction
{
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New Canvas"
                                                  message:@"Do you really want to delete the current drawing?"
                                                 delegate:self
                                        cancelButtonTitle:@"YES"
                                        otherButtonTitles:@"NO", nil];
  [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 0) {
    UIGraphicsBeginImageContextWithOptions(self.saveView.frame.size, NO, 0.0);
    UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.saveView.image = blank;
  }
}

#pragma mark Getter

-(id)getUndoManager
{
  return self.undoManager;
}

-(id)getResizeViewManager
{
  return self.resizeViewManager;
}

-(id)getPointerTool
{
  return self.pointerTool;
}

#pragma mark - gestureRecognizer Delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  return YES;
}

#pragma mark - statusBar Delegate
-(UIStatusBarStyle)preferredStatusBarStyle{
  return UIStatusBarStyleLightContent;
}


@end
