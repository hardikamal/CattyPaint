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

#import "BrushPickerViewController.h"
#import "UIViewController+KNSemiModal.h"
#import "PaintViewController.h"

@interface BrushPickerViewController ()
@property (nonatomic,strong)UIImageView *brushView;
@property (nonatomic,strong)UISlider *brushSlider;
@property (nonatomic,strong)UILabel *thicknessLabel;
@property (nonatomic,strong)UISegmentedControl *brushEndingControl;

@end

@implementation BrushPickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame andController:(PaintViewController *)controller
{
  self = [super init];
  if (self) {
      // Custom initialization
    self.view.frame = frame;
    self.brush = controller.thickness;
    self.brushEnding = controller.ending;
    self.color =[UIColor colorWithRed:controller.red green:controller.green blue:controller.blue alpha:controller.opacity];
  }
  return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
  [self setupToolBar];

  
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self setupBrushPreview];
  [self setupSegmentedControl];
  [self setupBrushSlider];
}

-(void)setupToolBar
{
  self.toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40)];
  [self.view addSubview:self.toolBar];
  self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
  [self.toolBar setItems:@[self.doneButton]];
  self.toolBar.frame = CGRectMake(0, 0, self.view.frame.size.width, self.toolBar.frame.size.height);
  self.toolBar.tintColor = [UIColor lightOrangeColor];
  
}


-(void)setupSegmentedControl
{
  NSArray *mySegments = [[NSArray alloc] initWithObjects: @"Round",
                         @"Square", nil];
  self.brushEndingControl = [[UISegmentedControl alloc] initWithItems:mySegments];
  self.brushEndingControl.frame =CGRectMake(20, self.view.frame.size.height*0.9f, self.view.frame.size.width-40, 20);
  self.brushEndingControl.tintColor = [UIColor lightOrangeColor];
  switch (self.brushEnding) {
    case Round:
      self.brushEndingControl.selectedSegmentIndex = 0;
      break;
    case Square:
      self.brushEndingControl.selectedSegmentIndex = 1;
      break;
    default:
      break;
  }
  
  [self.brushEndingControl addTarget:self
                       action:@selector(whichBrushEnding:)
                    forControlEvents:UIControlEventValueChanged];
  [self.view addSubview:self.brushEndingControl];
}

-(void)setupBrushSlider
{
  self.brushSlider = [[UISlider alloc] init];
  self.brushSlider.frame =CGRectMake(self.view.frame.size.width*0.2f, self.view.frame.size.height*0.7f, self.view.frame.size.width-200, 5);
  [self.brushSlider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
  [self.brushSlider setBackgroundColor:[UIColor clearColor]];
  self.brushSlider.minimumValue = 1.0f;
  self.brushSlider.maximumValue = 75.0f;
  self.brushSlider.continuous = YES;
  self.brushSlider.value = self.brush;
  self.brushSlider.tintColor = [UIColor darkBlueColor];
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width*0.1f, self.view.frame.size.height*0.55f, 40, 10)];
  label.text = @"Thickness";
  [label sizeToFit];
  self.thicknessLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.brushSlider.frame.origin.x+self.brushSlider.frame.size.width +20, self.view.frame.size.height*0.7f-7, 40, 10)];
  self.thicknessLabel.text = [NSString stringWithFormat:@"%.0f",roundf(self.brush)];
  [self.thicknessLabel sizeToFit];
  
  [self.view addSubview:label];
  [self.view addSubview:self.thicknessLabel];
  [self.view addSubview:self.brushSlider];
  
}

-(void)setupBrushPreview
{
  self.brushView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.center.x-50, 40, 125, 125)];
  UIGraphicsBeginImageContext(self.brushView.frame.size);
  switch (self.brushEnding) {
    case Round:
      CGContextSetLineCap(UIGraphicsGetCurrentContext(),kCGLineCapRound);
      break;
    case Square:
      CGContextSetLineCap(UIGraphicsGetCurrentContext(),kCGLineCapSquare);
      break;
    default:
      break;
  }
  CGContextSetLineWidth(UIGraphicsGetCurrentContext(), self.brush);
  CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), self.color.CGColor);
  CGContextMoveToPoint(UIGraphicsGetCurrentContext(),55, 55);
  CGContextAddLineToPoint(UIGraphicsGetCurrentContext(),55, 55);
  CGContextStrokePath(UIGraphicsGetCurrentContext());
  self.brushView.image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  [self.view addSubview:self.brushView];
  [self.view setNeedsDisplay];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)whichBrushEnding:(UISegmentedControl *)paramSender
{
  NSInteger selectedIndex = [paramSender selectedSegmentIndex];
  switch (selectedIndex) {
    case 0:
      self.brushEnding = Round;
      break;
    case 1:
      self.brushEnding = Square;
      break;
    default:
      break;
  }
  
  
  UIGraphicsBeginImageContext(self.brushView.frame.size);
  switch (self.brushEnding) {
    case Round:
      CGContextSetLineCap(UIGraphicsGetCurrentContext(),kCGLineCapRound);
      break;
    case Square:
      CGContextSetLineCap(UIGraphicsGetCurrentContext(),kCGLineCapSquare);
      break;
    default:
      break;
  }
  CGContextSetLineWidth(UIGraphicsGetCurrentContext(), self.brush);
  CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), self.color.CGColor);
  CGContextMoveToPoint(UIGraphicsGetCurrentContext(),55, 55);
  CGContextAddLineToPoint(UIGraphicsGetCurrentContext(),55, 55);
  CGContextStrokePath(UIGraphicsGetCurrentContext());
  self.brushView.image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
//TODO Change ImageView
  NSLog(@"Segment at position %ld ",
        (long)selectedIndex);
}

-(void)sliderAction:(id)sender
{
  UISlider *slider = (UISlider*)sender;
  float value = slider.value;
  self.thicknessLabel.text = [NSString stringWithFormat:@"%.0f",roundf(value)];
  [self.thicknessLabel sizeToFit];
  
  self.brush = roundf(value);
  
  UIGraphicsBeginImageContext(self.brushView.frame.size);
  switch (self.brushEnding) {
    case Round:
      CGContextSetLineCap(UIGraphicsGetCurrentContext(),kCGLineCapRound);
      break;
    case Square:
      CGContextSetLineCap(UIGraphicsGetCurrentContext(),kCGLineCapSquare);
      break;
    default:
      break;
  }
  CGContextSetLineWidth(UIGraphicsGetCurrentContext(), self.brush);
  CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), self.color.CGColor);
  CGContextMoveToPoint(UIGraphicsGetCurrentContext(),55, 55);
  CGContextAddLineToPoint(UIGraphicsGetCurrentContext(),55, 55);
  CGContextStrokePath(UIGraphicsGetCurrentContext());
  self.brushView.image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  
}

- (IBAction)doneAction:(UIBarButtonItem *)sender {
  [self.delegate closeBrushPicker:self];
}


@end
