//
//  LCTableViewPickerControl.m
//  InsurancePig
//
//  Created by Leo Chang on 10/21/13.
//  Copyright (c) 2013 Good-idea Consunting Inc. All rights reserved.
//

#import "LCTableViewPickerControl.h"

#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define kNavBarHeight 44
#define cellIdentifier @"itemPickerCellIdentifier"

@interface LCTableViewPickerControl () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSArray *items;
@property (nonatomic) actionType currentVale;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UITableView *aTableView;
@property (nonatomic, assign) CGPoint offset;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;

@end

@implementation LCTableViewPickerControl

- (id)initWithFrame:(CGRect)frame title:(NSString*)title value:(actionType)value items:(NSArray *)array offset:(CGPoint)offset
{
    if (self = [super initWithFrame:frame])
    {
        self.currentVale = value;
        self.items = [NSArray arrayWithArray:array];
        self.title = title;
        self.offset = offset;
        
        [self initializeControlWithFrame:frame];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)initializeControlWithFrame:(CGRect)frame
{
    /*
     create navigation bar
     */
    self.navBar = [[UINavigationBar alloc] init];
    [_navBar setFrame:CGRectMake(0, 0, frame.size.width, 44)];
    if ([_navBar respondsToSelector:@selector(setBarTintColor:)])
    {
        _navBar.barTintColor = kPickerTitleBarColor;
    }
    else
    {
        _navBar.tintColor = kPickerTitleBarColor;
    }
    /*
     create dismissItem
     */
  
  UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                  style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
  rightButton.tintColor = [UIColor lightOrangeColor];
  UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:_title];
  item.rightBarButtonItem = rightButton;
  item.hidesBackButton = YES;
  item.titleView.tintColor = [UIColor yellowColor];
  [_navBar pushNavigationItem:item animated:NO];
    self.aTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, kNavBarHeight, frame.size.width, frame.size.height - kNavBarHeight) style:UITableViewStylePlain];
  self.aTableView.backgroundColor = [UIColor cellBlueColor];
  self.aTableView.separatorColor = [UIColor lightBlueColor];
    [_aTableView setDelegate:self];
    [_aTableView setDataSource:self];
    [self addSubview:_navBar];
    [self addSubview:_aTableView];
    
    //add UIPanGesture
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    [self.panRecognizer setMinimumNumberOfTouches:1];
    [self.panRecognizer setMaximumNumberOfTouches:1];
    [self.panRecognizer setDelegate:self];
    [_navBar addGestureRecognizer:self.panRecognizer];

}

- (void)showInView:(UIView *)view
{
    //add mask
    self.maskView = [[UIView alloc] initWithFrame:view.bounds];
    [_maskView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0]];
    [view insertSubview:_maskView atIndex:0];
    
    //add a Tap gesture in maskView
    if (!_tapGesture)
    {
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [_maskView addGestureRecognizer:_tapGesture];
    }
    
    [_maskView addGestureRecognizer:_tapGesture];
    
    [UIView animateWithDuration:kAnimationDuration delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
        [self setFrame:CGRectMake(0, SCREEN_HEIGHT - kPickerControlAgeHeight - 10, self.frame.size.width, kPickerControlAgeHeight)];
        [_maskView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.6]];
    } completion:^(BOOL finished){
        //scroll to currentValue
        [UIView animateWithDuration:0.2 animations:^{
            [self setFrame:CGRectMake(0, SCREEN_HEIGHT - kPickerControlAgeHeight + 5, self.frame.size.width, kPickerControlAgeHeight)];
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.1 animations:^{
                [self setFrame:CGRectMake(0, SCREEN_HEIGHT - kPickerControlAgeHeight, self.frame.size.width, kPickerControlAgeHeight)];
            } completion:^(BOOL finished){
                //configure your settings after view animation completion
            }];
        }];

        NSInteger index = [_items indexOfObject:@(_currentVale)];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [_aTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }];
}

- (void)tap:(UITapGestureRecognizer*)sender
{
    //common delegate way
    if ([self.delegate respondsToSelector:@selector(selectControl:didCancelWithItem:)])
      [self.delegate selectControl:self didCancelWithItem:@(self.currentVale)];
}

- (void)dismiss
{
    //animation to dismiss
    [UIView animateWithDuration:kAnimationDuration delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
        [self setFrame:CGRectMake(0, SCREEN_HEIGHT, kPickerControlAgeHeight, self.frame.size.width)];
        [_maskView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0]];
    } completion:^(BOOL finished){
        [self removeFromSuperview];
        [_maskView removeFromSuperview];
        self.panRecognizer.enabled = NO;
    }];

}

- (void)dismissPickerView:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(selectControl:didSelectWithItem:)])
        [self.delegate selectControl:self didSelectWithItem:[NSString stringWithFormat:@""]];
}

#pragma mark - handle PanGesture
- (void)move:(UIPanGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [gestureRecognizer translationInView:self];
        
        if(translation.y < 0)
            return;
        
        CGPoint translatedCenter = CGPointMake([self center].x, [self center].y + translation.y);
        [self setCenter:translatedCenter];
        [gestureRecognizer setTranslation:CGPointZero inView:self];
    }
    if ([gestureRecognizer state] == UIGestureRecognizerStateEnded)
    {
        CGPoint translation = [gestureRecognizer translationInView:self];
        if(translation.y < 0)
            return;
      if ([self.delegate respondsToSelector:@selector(selectControl:didCancelWithItem:)])
        [self.delegate selectControl:self didCancelWithItem:@(self.currentVale)];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_items count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    NSInteger row = [indexPath row];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    actionType item = [[_items objectAtIndex:row] intValue];
    if (item == _currentVale) {
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else{
      cell.accessoryType = UITableViewCellAccessoryNone;
    }
  cell.imageView.backgroundColor = [UIColor darkBlueColor];
  cell.textLabel.textColor = [UIColor lightBlueColor];
  cell.backgroundColor = [UIColor cellBlueColor];
  
  switch (item) {
    case brush:{
      [cell.textLabel setText:NSLocalizedString(@"brush", nil)];
      cell.imageView.image = [UIImage imageNamed:@"brush"];
    }
      break;
    case eraser:{
      [cell.textLabel setText:NSLocalizedString(@"eraser", nil)];
      cell.imageView.image = [UIImage imageNamed:@"eraser"];
    }
      break;
    case crop:{
      [cell.textLabel setText:NSLocalizedString(@"crop", nil)];
      cell.imageView.image = [UIImage imageNamed:@"crop"];
    }
      break;
    case pipette:{
      [cell.textLabel setText:NSLocalizedString(@"pipette", nil)];
      cell.imageView.image = [UIImage imageNamed:@"pipette"];
    }
      break;
    case mirror:{
      [cell.textLabel setText:NSLocalizedString(@"mirror", nil)];
      cell.imageView.image = [UIImage imageNamed:@"mirror"];
    }
      break;
    case image:{
      [cell.textLabel setText:NSLocalizedString(@"image", nil)];
      cell.imageView.image = [UIImage imageNamed:@"image_select"];
    }
      break;
    case line:{
      [cell.textLabel setText:NSLocalizedString(@"line", nil)];
      cell.imageView.image = [UIImage imageNamed:@"line"];
    }
      break;
    case rectangle:{
      [cell.textLabel setText:NSLocalizedString(@"rectangle / square", nil)];
      cell.imageView.image = [UIImage imageNamed:@"rect"];
    }
      break;
    case ellipse:{
      [cell.textLabel setText:NSLocalizedString(@"ellipse / circle", nil)];
      cell.imageView.image = [UIImage imageNamed:@"circle"];
    }
      break;
    case stamp:{
      [cell.textLabel setText:NSLocalizedString(@"stamp", nil)];
      cell.imageView.image = [UIImage imageNamed:@"stamp"];
    }
      break;
    case rotate:{
      [cell.textLabel setText:NSLocalizedString(@"rotate", nil)];
      cell.imageView.image = [UIImage imageNamed:@"rotate"];
    }
      break;
    case fillTool:{
      [cell.textLabel setText:NSLocalizedString(@"fill", nil)];
      cell.imageView.image = [UIImage imageNamed:@"fill"];
    }
      break;
    case zoom:{
      [cell.textLabel setText:NSLocalizedString(@"zoom", nil)];
      cell.imageView.image = [UIImage imageNamed:@"zoom"];
    }
      break;
    case pointer:{
      [cell.textLabel setText:NSLocalizedString(@"pointer", nil)];
      cell.imageView.image = [UIImage imageNamed:@"pointer"];
    }
      break;
    default:
      break;
  }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(selectControl:didSelectWithItem:)])
        [self.delegate selectControl:self didSelectWithItem:[_items objectAtIndex:indexPath.row]];
}

-(void)cancel
{
  if ([self.delegate respondsToSelector:@selector(selectControl:didCancelWithItem:)])
    [self.delegate selectControl:self didCancelWithItem:@(self.currentVale)];
}


@end
