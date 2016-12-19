//
//  YUSegment.m
//  Created by YyGqQq on 2016/12/15.
//  Copyright © 2016年 Yu Guanqun. All rights reserved.
//

#import "YUSegment.h"
#import "YULabel.h"
#import "YUImageView.h"
#import "YUImageTextView.h"
#import "YUIndicatorView.h"

@interface YUSegment ()

/// @name Views

@property (nonatomic, strong) UIView                                 *containerView;
@property (nonatomic, strong) UIView                                 *selectedContainerView;
@property (nonatomic, strong) UIScrollView                           *scrollView;
@property (nonatomic, strong) YUIndicatorView                        *indicatorView;
@property (nonatomic, assign) BOOL                                   needsUpdateAppearance;
@property (nonatomic, assign) BOOL                                   needsUpdateViewHierarchy;

/// @name Constraints

@property (nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *widthConstraints;
@property (nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *leadingConstraints;

/// @name Contents

@property (nonatomic, strong) NSMutableArray <NSString *>    *internalTitles;
@property (nonatomic, strong) NSMutableArray <UIImage *>     *internalImages;
@property (nonatomic, strong) NSMutableArray <YULabel *>     *labels;
@property (nonatomic, strong) NSMutableArray <YUImageView *> *imageViews;
@property (nonatomic, strong) NSMutableArray <YULabel *>     *selectedLabels;
@property (nonatomic, strong) NSMutableArray <YUImageView *> *selectedImageViews;

/// @name Appearance

@property (nonatomic, copy) NSDictionary *textAttributesNormal;
@property (nonatomic, copy) NSDictionary *textAttributesSelected;

/// @name Gesture

@property (nonatomic, assign) CGFloat panCorrection;

@end

@implementation YUSegment {
    CGFloat _segmentWidth;
    UIColor *_textColor;
    UIColor *_selectedTextColor;
    UIFont  *_font;
    UIFont  *_selectedFont;
}

@dynamic segmentWidth;
@dynamic textColor;
@dynamic selectedTextColor;
@dynamic font;
@dynamic selectedFont;

#pragma mark - Initialization

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setDefaultValueForProperties];
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithTitles:(NSArray <NSString *> *)titles {
    return [self initWithTitles:titles style:YUSegmentStyleLine];
}

- (instancetype)initWithImages:(NSArray <UIImage *> *)images {
    return [self initWithImages:images style:YUSegmentStyleLine];
}

- (instancetype)initWithTitles:(NSArray <NSString *> *)titles forImages:(NSArray <UIImage *> *)images {
    NSAssert([titles count] == [images count], @"The count of titles should be equal to the count of images.");
    return [self initWithTitles:titles forImages:images style:YUSegmentStyleLine];
}

- (instancetype)initWithTitles:(NSArray <NSString *> *)titles style:(YUSegmentStyle)style {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _internalTitles = [titles mutableCopy];
        _numberOfSegments = [titles count];
        _style = style;
        [self setDefaultValueForProperties];
        [self commonInit];
        [self configureLabels];
    }
    return self;
}

- (instancetype)initWithImages:(NSArray <UIImage *> *)images style:(YUSegmentStyle)style {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _internalImages = [images mutableCopy];
        _numberOfSegments = [images count];
        _style = style;
        [self setDefaultValueForProperties];
        [self commonInit];
        [self configureImages];
    }
    return self;
}

- (instancetype)initWithTitles:(NSArray <NSString *> *)titles forImages:(NSArray <UIImage *> *)images style:(YUSegmentStyle)style {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _internalTitles = [titles mutableCopy];
        _internalImages = [images mutableCopy];
        _numberOfSegments = [titles count];
        _style = style;
        [self setDefaultValueForProperties];
        [self commonInit];
        [self configureMixtureViews];
    }
    return self;
}

- (void)setDefaultValueForProperties {
    _needsUpdateViewHierarchy = NO;
    _needsUpdateAppearance = NO;
    _selectedIndex = 0;
//    self.backgroundColor = [UIColor whiteColor];
}

- (void)commonInit {
    // Build UI
    [self setupContainerView];
    [self setupSelectedContainerView];
    [self setupIndicatorView];
    [self buildUI];
    // Add gestures
    if (_style == YUSegmentStyleBox) {
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:pan];
    }
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:tap];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSLog(@"Segment layoutSubviews");
    
    CGFloat segmentWidth = self.segmentWidth;
    switch (_style) {
        case YUSegmentStyleLine: {
            CGFloat indicatorWidth = [self calculateIndicatorWidthPlusConstant];
            CGFloat x = segmentWidth * _selectedIndex + (segmentWidth - indicatorWidth) / 2.0;
            CGRect indicatorFrame = (CGRect){x, 0, indicatorWidth, CGRectGetHeight(self.frame)};
            _indicatorView.frame = indicatorFrame;
            break;
        }
        case YUSegmentStyleBox: {
            CGRect indicatorFrame = (CGRect){segmentWidth * _selectedIndex, 0, segmentWidth, CGRectGetHeight(self.frame)};
            _indicatorView.frame = CGRectInset(indicatorFrame, _indicatorMargin, _indicatorMargin);
            break;
        }
    }
}

#pragma mark - Content Setting

- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)index {
    NSAssert(_internalTitles, @"You should use this method when the content of segment is `NSString` object.");
    if (index > _numberOfSegments - 1) {
        index = _numberOfSegments - 1;
    }
    [self updateTitle:title image:nil forSegmentAtIndex:index];
}

- (void)setImage:(UIImage *)image forSegmentAtIndex:(NSUInteger)index {
    NSAssert(_internalImages, @"You should use this method when the content of segment is `UImage` object.");
    if (index > _numberOfSegments - 1) {
        index = _numberOfSegments - 1;
    }
    [self updateTitle:nil image:image forSegmentAtIndex:index];
}

- (void)setTitle:(NSString *)title forImage:(UIImage *)image forSegmentAtIndex:(NSUInteger)index {
    NSAssert(_internalTitles && _internalImages, @"You should use this method when the content of segment includes title and image.");
    if (index > _numberOfSegments - 1) {
        index = _numberOfSegments - 1;
    }
    [self updateTitle:title image:image forSegmentAtIndex:index];
}

- (void)updateTitle:(NSString *)title image:(UIImage *)image forSegmentAtIndex:(NSUInteger)index {
    if (title) {
        self.internalTitles[index] = title;
        if (_textAttributesNormal) {
            _labels[index].attributedText = [[NSAttributedString alloc] initWithString:title
                                                                            attributes:_textAttributesNormal];
        } else {
            _labels[index].text = title;
        }
        if (_textAttributesSelected) {
            _selectedLabels[index].attributedText = [[NSAttributedString alloc] initWithString:title
                                                                                    attributes:_textAttributesSelected];
        } else {
            _selectedLabels[index].text = title;
        }
    }
    if (image) {
        self.internalImages[index] = image;
        _selectedImageViews[index].image = image;
        _imageViews[index].image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
}

#pragma mark - Content Getting

- (NSString *)titleForSegmentAtIndex:(NSUInteger)index {
    NSAssert(_internalTitles, @"You should use this method when the content of segment is `NSString` object.");
    if (index > _numberOfSegments - 1) {
        index = _numberOfSegments - 1;
    }
    return _internalTitles[index];
}

- (UIImage *)imageForSegmentAtIndex:(NSUInteger)index {
    NSAssert(_internalImages, @"You should use this method when the content of segment is `UImage` object.");
    if (index > _numberOfSegments - 1) {
        index = _numberOfSegments - 1;
    }
    return _internalImages[index];
}

#pragma mark - Content Insert

- (void)addSegmentWithTitle:(NSString *)title {
    [self insertSegmentWithTitle:title atIndex:_numberOfSegments];
}

- (void)addSegmentWithImage:(UIImage *)image {
    [self insertSegmentWithImage:image atIndex:_numberOfSegments];
}

- (void)addSegmentWithTitle:(NSString *)title forImage:(UIImage *)image {
    [self insertSegmentWithTitle:title forImage:image atIndex:_numberOfSegments];
}

- (void)insertSegmentWithTitle:(NSString *)title atIndex:(NSUInteger)index {
    NSAssert(_internalTitles, @"You should use this method when the content of segment is `NSString` objcet.");
    if (index > _numberOfSegments) {
        index = _numberOfSegments;
    }
    [self.internalTitles insertObject:title atIndex:index];
    _numberOfSegments++;
}

- (void)insertSegmentWithImage:(UIImage *)image atIndex:(NSUInteger)index {
    NSAssert(_internalImages, @"You should use this method when the content of segment is `UIImage` objcet.");
    if (index > _numberOfSegments) {
        index = _numberOfSegments;
    }
    [self.internalImages insertObject:image atIndex:index];
    _numberOfSegments++;
}

- (void)insertSegmentWithTitle:(NSString *)title forImage:(UIImage *)image atIndex:(NSUInteger)index {
    NSAssert(_internalTitles && _internalImages, @"You should use this method when the content of the segment including `NSString` object and `UIImage` object.");
    if (index > _numberOfSegments) {
        index = _numberOfSegments;
    }
    [self.internalTitles insertObject:title atIndex:index];
    [self.internalImages insertObject:image atIndex:index];
    _numberOfSegments++;
}

- (void)insertViewWithTitle:(NSString *)title atIndex:(NSUInteger)index {
    // setup view
//    [self setupSegmentViewWithTitle:title selected:NO];
//    [self setupSegmentViewWithTitle:title selected:YES];
    // update c
//    [self updateConstraintsWithInsertSegmentView:segmentView atIndex:index];
}

- (void)insertViewWithImage:(UIImage *)image atIndex:(NSUInteger)index {
    
}

- (void)insertViewWithTitle:(NSString *)title forImage:(UIImage *)image atIndex:(NSUInteger)index {
    
}

#pragma mark - Content Delete

- (void)removeAllItems {
    
}

- (void)removeLastItem {
    [self removeItemAtIndex:_numberOfSegments - 1];
}

- (void)removeItemAtIndex:(NSUInteger)index {
    
}

#pragma mark - Views Setup

- (void)configureBasicLabels {
    YULabel *label;
    NSString *title;
    for (int i = 0; i < _numberOfSegments; i++) {
        title = _internalTitles[i];
        label = [[YULabel alloc] initWithText:title];
        label.font = self.font;
        label.textColor = self.textColor;
        [self.labels addObject:label];
        [_containerView addSubview:label];
    }
    [self setupConstraintsWithSegments:_labels toContainerView:_containerView];
}

- (void)configureSelectedLabels {
    YULabel *label;
    NSString *title;
    for (int i = 0; i < _numberOfSegments; i++) {
        title = _internalTitles[i];
        label = [[YULabel alloc] initWithText:title];
        label.font = self.selectedFont;
        label.textColor = self.selectedTextColor;
        [self.selectedLabels addObject:label];
        [_selectedContainerView addSubview:label];
    }
    [self setupConstraintsWithSegments:_selectedLabels toContainerView:_selectedContainerView];
}

- (void)configureLabels {
    [self configureBasicLabels];
    [self configureSelectedLabels];
}

- (void)configureBasicImages {
    YUImageView *imageView;
    UIImage *image;
    for (int i = 0; i < _numberOfSegments; i++) {
        image = _internalImages[i];
        imageView = [[YUImageView alloc] initWithImage:image renderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.imageViews addObject:imageView];
        [_containerView addSubview:imageView];
    }
    [self setupConstraintsWithSegments:_imageViews toContainerView:_containerView];
}

- (void)configureSelectedImages {
    YUImageView *imageView;
    UIImage *image;
    for (int i = 0; i < _numberOfSegments; i++) {
        image = _internalImages[i];
        imageView = [[YUImageView alloc] initWithImage:image renderingMode:UIImageRenderingModeAutomatic];
        [self.selectedImageViews addObject:imageView];
        [_selectedContainerView addSubview:imageView];
    }
    [self setupConstraintsWithSegments:_selectedImageViews toContainerView:_selectedContainerView];
}

- (void)configureImages {
    [self configureBasicImages];
    [self configureSelectedImages];
}

- (void)configureBasicMixtureViews {
    YULabel *label;
    YUImageView *imageView;
    YUImageTextView *mixtrueView;
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < _numberOfSegments; i++) {
        label = [[YULabel alloc] initWithText:_internalTitles[i]];
        label.font = self.font;
        label.textColor = self.textColor;
        [self.labels addObject:label];
        imageView = [[YUImageView alloc] initWithImage:_internalImages[i] renderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.imageViews addObject:imageView];
        mixtrueView = [[YUImageTextView alloc] initWithLabel:label imageView:imageView];
        [array addObject:mixtrueView];
        [_containerView addSubview:mixtrueView];
    }
    [self setupConstraintsWithSegments:array toContainerView:_containerView];
}

- (void)configureSelectedMixtureViews {
    YULabel *label;
    YUImageView *imageView;
    YUImageTextView *mixtrueView;
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < _numberOfSegments; i++) {
        label = [[YULabel alloc] initWithText:_internalTitles[i]];
        label.font = self.selectedFont;
        label.textColor = self.selectedTextColor;
        [self.selectedLabels addObject:label];
        imageView = [[YUImageView alloc] initWithImage:_internalImages[i] renderingMode:UIImageRenderingModeAutomatic];
        [self.selectedImageViews addObject:imageView];
        mixtrueView = [[YUImageTextView alloc] initWithLabel:label imageView:imageView];
        [array addObject:mixtrueView];
        [_selectedContainerView addSubview:mixtrueView];
    }
    [self setupConstraintsWithSegments:array toContainerView:_selectedContainerView];
}

- (void)configureMixtureViews {
    [self configureBasicMixtureViews];
    [self configureSelectedMixtureViews];
}

- (void)setupContainerView {
    _containerView = ({
        UIView *containerView = [UIView new];
        containerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:containerView];
        
        containerView;
    });
    [self setupConstraintsToSelfWithView:_containerView];
}

- (void)setupSelectedContainerView {
    _selectedContainerView = ({
        UIView *containerView = [UIView new];
        containerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:containerView];
        
        containerView;
    });
    [self setupConstraintsToSelfWithView:_selectedContainerView];
}

- (void)setupIndicatorView {
    _indicatorView = [[YUIndicatorView alloc] initWithStyle:(YUIndicatorViewStyle)_style];
    [self insertSubview:_indicatorView atIndex:1];
    _selectedContainerView.layer.mask = _indicatorView.maskView.layer;
}

- (void)buildUI {
    if (!self.backgroundColor) {
        self.backgroundColor = [UIColor whiteColor];
    }
    switch (_style) {
        case YUSegmentStyleLine: {
            _indicatorView.backgroundColor = self.backgroundColor;
            break;
        }
        case YUSegmentStyleBox: {
            self.layer.cornerRadius = 5.0;
            _indicatorView.indicatorColor = [UIColor colorWithWhite:0.2 alpha:1.0];
            _indicatorMargin = 3.0;
            _indicatorView.cornerRadius = 5.0;
            break;
        }
    }
}

- (void)configureIndicatorWithBackgroundColor:(UIColor *)color {
    if (![color isEqual:[UIColor clearColor]]) {
        _indicatorView.backgroundColor = color;
    } else {
        _indicatorView.backgroundColor = [UIColor whiteColor];
    }
}

#pragma mark - Views Update

- (void)updateTitleWithColor:(UIColor *)color {
    if (!_labels) {
        return;
    }
    for (int i = 0; i < _numberOfSegments; i++) {
        _labels[i].textColor = color;
    }
}

- (void)updateTitleWithSelectedColor:(UIColor *)color {
    if (!_selectedLabels) {
        if (!_labels) {
            return;
        } else {
            _labels[_selectedIndex].textColor = color;
        }
    } else {
        for (int i = 0; i < _numberOfSegments; i++) {
            _selectedLabels[i].textColor = color;
        }
    }
}

- (void)updateTitleWithFont:(UIFont *)font {
    if (!_labels) {
        return;
    }
    for (int i = 0; i < _numberOfSegments; i++) {
        _labels[i].font = font;
    }
}

- (void)updateTitleWithSelectedFont:(UIFont *)font {
    if (!_selectedLabels) {
        if (!_labels) {
            return;
        } else {
            _labels[_selectedIndex].font = font;
        }
    } else {
        for (int i = 0; i < _numberOfSegments ; i++) {
            _selectedLabels[i].font = font;
        }
    }
}

- (void)updateViewHierarchy {
    // Add container to scroll view
    [_containerView removeFromSuperview];
    [self.scrollView addSubview:_containerView];
    [self setupConstraintsToScrollViewWithView:_containerView];
    
    // Add indicator to scroll view
    [_indicatorView removeFromSuperview];
    [_scrollView addSubview:_indicatorView];
    
    // Add selected container to scroll view
    [_selectedContainerView removeFromSuperview];
    [_scrollView addSubview:_selectedContainerView];
    [self setupConstraintsToScrollViewWithView:_selectedContainerView];
    
    [self updateWidthConstraintsForSegments];
}

- (void)setTitleTextAttributes:(NSDictionary *)attributes forState:(YUSegmentedControlState)state {
    // If don't have titles, return
    if (!_internalTitles) {
        return;
    }
    NSAssert(attributes, @"The attributes should not be nil.");
    switch (state) {
        case YUSegmentedControlStateNormal: {
            _textAttributesNormal = attributes;
            for (int i = 0; i < _numberOfSegments; i++) {
                _labels[i].attributedText = [[NSAttributedString alloc] initWithString:_internalTitles[i]
                                                                            attributes:attributes];
            }
            break;
        }
        case YUSegmentedControlStateSelected: {
            _textAttributesSelected = attributes;
            for (int i = 0; i < _numberOfSegments; i++) {
                _selectedLabels[i].attributedText = [[NSAttributedString alloc] initWithString:_internalTitles[i]
                                                                                    attributes:attributes];
            }
            break;
        }
    }
}

- (NSDictionary *)titleTextAttributesForState:(YUSegmentedControlState)state {
    switch (state) {
        case YUSegmentedControlStateNormal:
            return _textAttributesNormal;
        case YUSegmentedControlStateSelected:
            return _textAttributesSelected;
    }
}

- (void)makeCurrentSegmentCenterInSelf {
    CGFloat finalOffset = self.segmentWidth * (_selectedIndex + 0.5) - CGRectGetWidth(self.frame) / 2;
    CGFloat maxOffset = _scrollView.contentSize.width - CGRectGetWidth(self.frame);
    CGPoint contentOffset = _scrollView.contentOffset;
    if (finalOffset <= 0) {
        contentOffset.x = 0;
    }
    else if (finalOffset >= maxOffset) {
        contentOffset.x = maxOffset;
    }
    else {
        contentOffset.x = finalOffset;
    }
    _scrollView.contentOffset = contentOffset;
}

#pragma mark - Event Response

- (void)tap:(UITapGestureRecognizer *)gestureRecognizer {
    CGPoint location = [gestureRecognizer locationInView:_containerView];
    NSUInteger fromIndex = self.selectedIndex;
    _selectedIndex = [self nearestIndexOfSegmentAtXCoordinate:location.x];
    if (fromIndex != _selectedIndex) {
        switch (_style) {
            case YUSegmentStyleLine:
            case YUSegmentStyleBox:
                [self moveIndicatorFromIndex:fromIndex toIndex:_selectedIndex animated:YES];
                break;
        }
    }
}

- (void)pan:(UIPanGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            _panCorrection = [gestureRecognizer locationInView:_indicatorView].x - CGRectGetWidth(_indicatorView.frame) / 2;
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGPoint panLocation = [gestureRecognizer locationInView:_containerView];
            [self.indicatorView setCenterX:(panLocation.x - _panCorrection)];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            CGFloat indicatorCenterX = [_indicatorView getCenterX];
            NSUInteger fromIndex = _selectedIndex;
            _selectedIndex = [self nearestIndexOfSegmentAtXCoordinate:indicatorCenterX];
            [self moveIndicatorFromIndex:fromIndex toIndex:_selectedIndex animated:YES];
        }
        default:
            break;
    }
}

- (NSUInteger)nearestIndexOfSegmentAtXCoordinate:(CGFloat)x {
    NSUInteger index = x / self.segmentWidth;
    return index < _numberOfSegments ? index : _numberOfSegments - 1;
}

- (void)moveIndicatorFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex animated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            [_indicatorView setCenterX:self.segmentWidth * (0.5 + toIndex)];
        } completion:^(BOOL finished) {
            if (finished) {
                [self sendActionsForControlEvents:UIControlEventValueChanged];
                [self makeCurrentSegmentCenterInSelf];
            }
        }];
    }
    else {
        [_indicatorView setCenterX:self.segmentWidth * (0.5 + toIndex)];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
        [self makeCurrentSegmentCenterInSelf];
    }
}

#pragma mark -

- (CGFloat)calculateIndicatorWidthPlusConstant {
    CGFloat maxWidth = 0.0;
    CGFloat width;
    if (_internalTitles && _internalImages) {
        maxWidth = _selectedImageViews[0].intrinsicContentSize.width;
        for (YULabel *label in _selectedLabels) {
            width = label.intrinsicContentSize.width;
            if (width > maxWidth) {
                maxWidth = width;
            }
        }
    }
    else if (_internalImages) {
        maxWidth = _selectedImageViews[0].intrinsicContentSize.width;
    }
    else {
        for (YULabel *label in _selectedLabels) {
            width = label.intrinsicContentSize.width;
            if (width > maxWidth) {
                maxWidth = width;
            }
        }
    }
    maxWidth += 32.0;
    CGFloat segmentWidth = self.segmentWidth;
    if (maxWidth > segmentWidth) {
        maxWidth = segmentWidth;
    }
    return maxWidth;
}

#pragma mark - Setters

- (void)setBoxStyle:(BOOL)boxStyle {
    if (boxStyle) {
        [_indicatorView removeFromSuperview];
        [self setupIndicatorView];
    }
}

- (void)setSegmentTitles:(NSString *)titles {
    _internalTitles = [[titles componentsSeparatedByString:@"\n"] mutableCopy];
    _numberOfSegments = [_internalTitles count];
    if (_internalImages) {
        for (UIView *view in _containerView.subviews) {
            [view removeFromSuperview];
        }
        for (UIView *view in _selectedContainerView.subviews) {
            [view removeFromSuperview];
        }
        [self configureMixtureViews];
    } else {
        [self configureLabels];
    }
}

- (void)setSegmentImages:(NSString *)images {
    NSArray *internalImages = [images componentsSeparatedByString:@"\n"];
    _internalImages = [NSMutableArray array];
    for (NSString *name in internalImages) {
        [_internalImages addObject:[UIImage imageNamed:name]];
    }
    _numberOfSegments = [internalImages count];
    if (_internalTitles) {
        for (UIView *view in _containerView.subviews) {
            [view removeFromSuperview];
        }
        for (UIView *view in _selectedContainerView.subviews) {
            [view removeFromSuperview];
        }
        [self configureMixtureViews];
    } else {
        [self configureImages];
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    if (_selectedIndex == selectedIndex) {
        return;
    }
    _selectedIndex = selectedIndex;
    [_indicatorView setCenterX:self.segmentWidth * (0.5 + selectedIndex)];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.layer.cornerRadius = cornerRadius;
    _indicatorView.cornerRadius = cornerRadius;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    self.layer.borderWidth = borderWidth;
}

- (void)setBorderColor:(UIColor *)borderColor {
    self.layer.borderColor = borderColor.CGColor;
}

- (void)setSegmentWidth:(CGFloat)segmentWidth {
    if (segmentWidth < 1.0 || _segmentWidth == segmentWidth) {
        return;
    }
    _segmentWidth = segmentWidth;
    if (_numberOfSegments) {
        [self updateViewHierarchy];
    } else {
        _needsUpdateViewHierarchy = YES;
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    NSAssert(backgroundColor, @"The color should not be nil.");
    [super setBackgroundColor:backgroundColor];
    if (_indicatorView) {
        if (_style == YUSegmentStyleLine) {
            if ([backgroundColor isEqual:[UIColor clearColor]]) {
                _indicatorView.backgroundColor = [UIColor whiteColor];
            } else {
                _indicatorView.backgroundColor = backgroundColor;
            }
        }
    }
}

- (void)setIndicatorColor:(UIColor *)indicatorColor {
    if (!_indicatorView) {
        return;
    }
    NSAssert(indicatorColor, @"The color should not be nil.");
    if (indicatorColor != _indicatorColor && ![indicatorColor isEqual:_indicatorColor]) {
        _indicatorColor = indicatorColor;
        _indicatorView.indicatorColor = indicatorColor;
    }
}

- (void)setTextColor:(UIColor *)textColor {
    NSAssert(textColor, @"The color should not be nil.");
    if (textColor != _textColor && ![textColor isEqual:_textColor]) {
        _textColor = textColor;
        if (_numberOfSegments) {
            [self updateTitleWithColor:textColor];
        } else {
            _needsUpdateAppearance = YES;
        }
    }
}

- (void)setSelectedTextColor:(UIColor *)selectedTextColor {
    NSAssert(selectedTextColor, @"The color should not be nil.");
    if (selectedTextColor != _selectedTextColor && ![selectedTextColor isEqual:_selectedTextColor]) {
        _selectedTextColor = selectedTextColor;
        if (_numberOfSegments) {
            [self updateTitleWithSelectedColor:selectedTextColor];
        } else {
            _needsUpdateAppearance = YES;
        }
    }
}

- (void)setFont:(UIFont *)font {
    NSAssert(font, @"The font should not be nil.");
    _font = font;
    if (_numberOfSegments) {
        [self updateTitleWithFont:font];
    } else {
        _needsUpdateAppearance = YES;
    }
}

- (void)setSelectedFont:(UIFont *)selectedFont {
    NSAssert(selectedFont, @"The font should not be nil.");
    _selectedFont = selectedFont;
    if (_numberOfSegments) {
        [self updateTitleWithSelectedFont:selectedFont];
    } else {
        _needsUpdateAppearance = YES;
    }
}

#pragma mark - Getters

- (NSArray <NSString *> *)titles {
    return [_internalTitles copy];
}

- (NSArray <UIImage *> *)images {
    return [_internalImages copy];
}

- (CGFloat)segmentWidth {
    if (!_segmentWidth) {
        return CGRectGetWidth(self.bounds) / _numberOfSegments;
    }
    return _segmentWidth;
}

- (UIFont *)font {
    if (_font) {
        return _font;
    }
    _font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    return _font;
}

- (UIColor *)textColor {
    if (_textColor) {
        return _textColor;
    }
    if (_style == YUSegmentStyleBox) {
        _textColor = [UIColor blackColor];
    } else {
        _textColor = [UIColor lightGrayColor];
    }
    return _textColor;
}

- (UIFont *)selectedFont {
    if (_selectedFont) {
        return _selectedFont;
    }
    _selectedFont = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    return _selectedFont;
}

- (UIColor *)selectedTextColor {
    if (_selectedTextColor) {
        return _selectedTextColor;
    }
    if (_style == YUSegmentStyleBox) {
        _selectedTextColor = [UIColor whiteColor];
    } else {
        _selectedTextColor = [UIColor blackColor];
    }
    return _selectedTextColor;
}

- (UIScrollView *)scrollView {
    if (_scrollView) {
        return _scrollView;
    }
    _scrollView = ({
        UIScrollView *scrollView = [UIScrollView new];
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:scrollView];
        
        scrollView;
    });
    [self setupConstraintsToSelfWithView:_scrollView];
    
    return _scrollView;
}

- (NSMutableArray <NSLayoutConstraint *> *)leadingConstraints {
    if (_leadingConstraints) {
        return _leadingConstraints;
    }
    _leadingConstraints = [NSMutableArray array];
    return _leadingConstraints;
}

- (NSMutableArray <NSLayoutConstraint *> *)widthConstraints {
    if (_widthConstraints) {
        return _widthConstraints;
    }
    _widthConstraints = [NSMutableArray array];
    return _widthConstraints;
}

- (NSMutableArray <YULabel *> *)labels {
    if (_labels) {
        return _labels;
    }
    _labels = [NSMutableArray array];
    return _labels;
}

- (NSMutableArray <YUImageView *> *)imageViews {
    if (_imageViews) {
        return _imageViews;
    }
    _imageViews = [NSMutableArray array];
    return _imageViews;
}

- (NSMutableArray <YULabel *> *)selectedLabels {
    if (_selectedLabels) {
        return _selectedLabels;
    }
    _selectedLabels = [NSMutableArray array];
    return _selectedLabels;
}

- (NSMutableArray <YUImageView *> *)selectedImageViews {
    if (_selectedImageViews) {
        return _selectedImageViews;
    }
    _selectedImageViews = [NSMutableArray array];
    return _selectedImageViews;
}

#pragma mark - Constraints

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)setupConstraintsWithSegments:(NSArray *)segments toContainerView:(UIView *)containerView {
    UIView *lastView;
    for (UIView *view in segments) {
        [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeTop multiplier:1.0 constant:8.0].active = YES;
        
        [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-8.0].active = YES;
        
        if (lastView) {
            NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:lastView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];
            leading.active = YES;
//            [self.leadingConstraints addObject:leading];
            
            NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:lastView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
            width.active = YES;
            [self.widthConstraints addObject:width];
        }
        else {
            NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0];
            leading.active = YES;
//            [self.leadingConstraints addObject:leading];
        }
        
        lastView = view;
    }
    [NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:lastView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0].active = YES;
}

- (void)setupConstraintsToSelfWithView:(UIView *)view {
    [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0].active = YES;
    
    [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0].active = YES;
    
    [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0].active = YES;
    
    [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0].active = YES;
}

- (void)setupConstraintsToScrollViewWithView:(UIView *)view {
    [NSLayoutConstraint constraintWithItem:_scrollView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0].active = YES;
    
    [NSLayoutConstraint constraintWithItem:_scrollView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0].active = YES;
    
    [NSLayoutConstraint constraintWithItem:_scrollView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0].active = YES;
    
    [NSLayoutConstraint constraintWithItem:_scrollView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0].active = YES;
    
    [NSLayoutConstraint constraintWithItem:_scrollView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0].active = YES;
}

- (void)updateWidthConstraintsForSegments {
    for (NSLayoutConstraint *width in _widthConstraints) {
        width.active = NO;
    }
    [self.widthConstraints removeAllObjects];
    for (UIView *view in _containerView.subviews) {
        NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_segmentWidth];
        width.active = YES;
        [self.widthConstraints addObject:width];
    }
    for (UIView *view in _selectedContainerView.subviews) {
        NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_segmentWidth];
        width.active = YES;
        [self.widthConstraints addObject:width];
    }
}

- (void)updateConstraintsWithInsertSegmentView:(UIView *)segmentView atIndex:(NSUInteger)index {
    if (_leadingConstraints) {
        NSLayoutConstraint *oldLeading = _leadingConstraints[index];
        id item = oldLeading.firstItem;
        id toItem = oldLeading.secondItem;
        oldLeading.active = NO;
        
        NSLayoutConstraint *newLeading = [NSLayoutConstraint constraintWithItem:segmentView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:toItem attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:8.0];
        newLeading.active = YES;
        [self.leadingConstraints insertObject:newLeading atIndex:index];
        
        oldLeading = [NSLayoutConstraint constraintWithItem:item attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:segmentView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:8.0];
        oldLeading.active = YES;
        self.leadingConstraints[index + 1] = oldLeading;
        
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:segmentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0.0];
        widthConstraint.active = YES;
        
        [self layoutIfNeeded];
        
        [NSLayoutConstraint constraintWithItem:segmentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_containerView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0].active = YES;
        
        [NSLayoutConstraint constraintWithItem:segmentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_containerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0].active = YES;
        
        widthConstraint.active = NO;
        widthConstraint = [NSLayoutConstraint constraintWithItem:segmentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:toItem attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
        widthConstraint.active = YES;
        
        [UIView animateWithDuration:3 animations:^{
            [self layoutIfNeeded];
        }];
    }
}

- (void)updateConstraintsWithDeleteSegmentViewAtIndex:(NSUInteger)index {
    
}

@end
