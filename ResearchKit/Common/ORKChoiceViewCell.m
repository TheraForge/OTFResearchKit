/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ORKChoiceViewCell.h"

#import "ORKSelectionTitleLabel.h"
#import "ORKSelectionSubTitleLabel.h"

#import "ORKAccessibility.h"
#import "ORKHelpers_Internal.h"
#import "ORKSkin.h"


static const CGFloat LabelRightMargin = 44.0;
static const CGFloat CardTopBottomMargin = 2.0;
static const CGFloat LabelTopBottomMargin = 20.0;

@interface ORKChoiceViewCell()

@property (nonatomic) UIView *containerView;
@property (nonatomic, strong, readonly) ORKSelectionTitleLabel *primaryLabel;
@property (nonatomic, strong, readonly) ORKSelectionSubTitleLabel *detailLabel;

@end

@implementation ORKChoiceViewCell {
    
    CGFloat _leftRightMargin;
    CGFloat _topBottomMargin;
    CAShapeLayer *_contentMaskLayer;
    
    UIImageView *_checkView;
    ORKSelectionTitleLabel *_shortLabel;
    ORKSelectionSubTitleLabel *_longLabel;
    NSMutableArray<NSLayoutConstraint *> *_containerConstraints;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.clipsToBounds = YES;
        _leftRightMargin = 0.0;
        _topBottomMargin = 0.0;
        _checkView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"checkmark" inBundle:ORKBundle() compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.accessoryView = _checkView;
        [self setupContainerView];
    }
    return self;
}

- (void) drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self setMaskLayers];
}

- (void)setMaskLayers {
    if (_useCardView) {
        if (_contentMaskLayer) {
            for (CALayer *sublayer in [_contentMaskLayer.sublayers mutableCopy]) {
                [sublayer removeFromSuperlayer];
            }
            [_contentMaskLayer removeFromSuperlayer];
            _contentMaskLayer = nil;
        }
        _contentMaskLayer = [[CAShapeLayer alloc] init];
        UIColor *fillColor = [UIColor ork_borderGrayColor];
        [_contentMaskLayer setFillColor:[fillColor CGColor]];
        
        CAShapeLayer *foreLayer = [CAShapeLayer layer];
        [foreLayer setFillColor:[[UIColor whiteColor] CGColor]];
        foreLayer.zPosition = 0.0f;
        
        CAShapeLayer *lineLayer = [CAShapeLayer layer];

        if (_isLastItem || _isFirstItemInSectionWithoutTitle) {
            NSUInteger rectCorners;
            if (_isLastItem && !_isFirstItemInSectionWithoutTitle) {
                rectCorners = UIRectCornerBottomLeft | UIRectCornerBottomRight;
            }
            else if (!_isLastItem && _isFirstItemInSectionWithoutTitle) {
                rectCorners = UIRectCornerTopLeft | UIRectCornerTopRight;
            }
            else {
                rectCorners = UIRectCornerTopLeft | UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight;
            }
            
            CGRect foreLayerBounds = CGRectMake(ORKCardDefaultBorderWidth, 0, self.containerView.bounds.size.width - 2 * ORKCardDefaultBorderWidth, self.containerView.bounds.size.height - ORKCardDefaultBorderWidth);
            
            _contentMaskLayer.path = [UIBezierPath bezierPathWithRoundedRect: self.containerView.bounds
                                                           byRoundingCorners: rectCorners
                                                                 cornerRadii: (CGSize){ORKCardDefaultCornerRadii, ORKCardDefaultCornerRadii}].CGPath;
            
            CGFloat foreLayerCornerRadii = ORKCardDefaultCornerRadii >= ORKCardDefaultBorderWidth ? ORKCardDefaultCornerRadii - ORKCardDefaultBorderWidth : ORKCardDefaultCornerRadii;
            
            foreLayer.path = [UIBezierPath bezierPathWithRoundedRect: foreLayerBounds
                                                   byRoundingCorners: rectCorners
                                                         cornerRadii: (CGSize){foreLayerCornerRadii, foreLayerCornerRadii}].CGPath;
        }
        else {
            CGRect foreLayerBounds = CGRectMake(ORKCardDefaultBorderWidth, 0, self.containerView.bounds.size.width - 2 * ORKCardDefaultBorderWidth, self.containerView.bounds.size.height);
            foreLayer.path = [UIBezierPath bezierPathWithRect:foreLayerBounds].CGPath;
            _contentMaskLayer.path = [UIBezierPath bezierPathWithRect:self.containerView.bounds].CGPath;
            
            CGRect lineBounds = CGRectMake(_leftRightMargin, self.containerView.bounds.size.height - 1.0, self.containerView.bounds.size.width - 2 * _leftRightMargin, 0.5);
            lineLayer.path = [UIBezierPath bezierPathWithRect:lineBounds].CGPath;
            lineLayer.zPosition = 0.0f;
            [lineLayer setFillColor:[[UIColor ork_midGrayTintColor] CGColor]];

        }
        [_contentMaskLayer addSublayer:foreLayer];
        [_contentMaskLayer addSublayer:lineLayer];
        [_containerView.layer insertSublayer:_contentMaskLayer atIndex:0];
    }
}


- (void)setupContainerView {
    if (!_containerView) {
        _containerView = [UIView new];
    }
    
    [self addSubview:_containerView];
}

- (void)setupConstraints {
    
    if (_containerConstraints) {
        [NSLayoutConstraint deactivateConstraints:_containerConstraints];
    }
    CGFloat cellLeftMargin = self.separatorInset.left;
    
    _containerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _containerConstraints = [NSMutableArray arrayWithArray:@[
                                                             [NSLayoutConstraint constraintWithItem:_containerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0],
                                                             [NSLayoutConstraint constraintWithItem:_containerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:_leftRightMargin],
                                                             [NSLayoutConstraint constraintWithItem:_containerView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:-_leftRightMargin],
                                                             ]];
    
    
    if (_primaryLabel) {
        
        [_containerConstraints addObjectsFromArray:@[
                                                     [NSLayoutConstraint constraintWithItem:_primaryLabel
                                                                                  attribute:NSLayoutAttributeTop
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:_containerView
                                                                                  attribute:NSLayoutAttributeTop
                                                                                 multiplier:1.0
                                                                                   constant:LabelTopBottomMargin],
                                                     [NSLayoutConstraint constraintWithItem:_primaryLabel
                                                                                  attribute:NSLayoutAttributeLeft
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:_containerView
                                                                                  attribute:NSLayoutAttributeLeft
                                                                                 multiplier:1.0
                                                                                   constant:cellLeftMargin],
                                                     [NSLayoutConstraint constraintWithItem:_primaryLabel
                                                                                  attribute:NSLayoutAttributeRight
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:_containerView
                                                                                  attribute:NSLayoutAttributeRight
                                                                                 multiplier:1.0
                                                                                   constant:-LabelRightMargin]
                                                     ]];
    }
    
    if (_detailLabel) {
        [_containerConstraints addObjectsFromArray:@[
                                                     [NSLayoutConstraint constraintWithItem:_detailLabel
                                                                                  attribute:NSLayoutAttributeTop
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:_primaryLabel ? : _containerView
                                                                                  attribute:_primaryLabel ? NSLayoutAttributeBottom : NSLayoutAttributeTop
                                                                                 multiplier:1.0
                                                                                   constant:_primaryLabel ? 0.0 : LabelTopBottomMargin],
                                                     [NSLayoutConstraint constraintWithItem:_detailLabel
                                                                                  attribute:NSLayoutAttributeLeft
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:_containerView
                                                                                  attribute:NSLayoutAttributeLeft
                                                                                 multiplier:1.0
                                                                                   constant:cellLeftMargin],
                                                     [NSLayoutConstraint constraintWithItem:_detailLabel
                                                                                  attribute:NSLayoutAttributeRight
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:_containerView
                                                                                  attribute:NSLayoutAttributeRight
                                                                                 multiplier:1.0
                                                                                   constant:-LabelRightMargin]
                                                     ]];
    }
    
    [_containerConstraints addObjectsFromArray:@[
                                                 [NSLayoutConstraint constraintWithItem:_containerView
                                                                              attribute:NSLayoutAttributeBottom
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:_detailLabel ? : _primaryLabel
                                                                              attribute:NSLayoutAttributeBottom
                                                                             multiplier:1.0
                                                                               constant:LabelTopBottomMargin],
                                                 [NSLayoutConstraint constraintWithItem:self
                                                                              attribute:NSLayoutAttributeBottom
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:_containerView
                                                                              attribute:NSLayoutAttributeBottom
                                                                             multiplier:1.0
                                                                               constant:0.0]
                                                 ]];
    
    [NSLayoutConstraint activateConstraints:_containerConstraints];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateSelectedItem];
    [self setMaskLayers];
}

- (void)setUseCardView:(bool)useCardView {
    _useCardView = useCardView;
    _leftRightMargin = ORKCardLeftRightMargin;
    _topBottomMargin = CardTopBottomMargin;
    [self setBackgroundColor:[UIColor clearColor]];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setupConstraints];
}

- (ORKSelectionTitleLabel *)shortLabel {
    if (_shortLabel == nil ) {
        _shortLabel = [ORKSelectionTitleLabel new];
        _shortLabel.numberOfLines = 0;
        [self.containerView addSubview:_shortLabel];
    }
    return _shortLabel;
}

- (ORKSelectionSubTitleLabel *)longLabel {
    if (_longLabel == nil) {
        _longLabel = [ORKSelectionSubTitleLabel new];
        _longLabel.numberOfLines = 0;
        _longLabel.textColor = [UIColor ork_darkGrayColor];
        [self.containerView addSubview:_longLabel];
    }
    return _longLabel;
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self updateSelectedItem];
}

- (void)updateSelectedItem {
    if (_immediateNavigation == NO) {
        self.accessoryView.hidden = _isSelected ? NO : YES;
        if (_isSelected) {
            self.primaryLabel.textColor = [self tintColor];
            self.detailLabel.textColor = [[self tintColor] colorWithAlphaComponent:192.0 / 255.0];
        }
    }
}

- (void)setImmediateNavigation:(BOOL)immediateNavigation {
    _immediateNavigation = immediateNavigation;
    
    if (_immediateNavigation == YES) {
        self.accessoryView = nil;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    [self updateSelectedItem];
}

- (void)setupPrimaryLabel {
    if (!_primaryLabel) {
        _primaryLabel = [ORKSelectionTitleLabel new];
        _primaryLabel.numberOfLines = 0;
        [self.containerView addSubview:_primaryLabel];
        _primaryLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self setupConstraints];
    }
}

- (void)setupDetailLabel {
    if (!_detailLabel) {
        _detailLabel = [ORKSelectionSubTitleLabel new];
        _detailLabel.numberOfLines = 0;
        _detailLabel.textColor = [UIColor ork_darkGrayColor];
        [self.containerView addSubview:_detailLabel];
        _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self setupConstraints];
    }
}

- (void)setPrimaryText:(NSString *)primaryText {
    if (primaryText) {
        [self setupPrimaryLabel];
        _primaryLabel.text = primaryText;
    }
}

- (void)setPrimaryAttributedText:(NSAttributedString *)primaryAttributedText {
    if (primaryAttributedText) {
        [self setupPrimaryLabel];
        _primaryLabel.attributedText = primaryAttributedText;
    }
}

- (void)setDetailText:(NSString *)detailText {
    if (detailText) {
        [self setupDetailLabel];
        _detailLabel.text = detailText;
    }
}

- (void)setDetailAttributedText:(NSAttributedString *)detailAttributedText {
    if (detailAttributedText) {
        [self setupDetailLabel];
        _detailLabel.attributedText = detailAttributedText;
    }
}

#pragma mark - Accessibility

- (NSString *)accessibilityLabel {
    return ORKAccessibilityStringForVariables(self.primaryLabel.accessibilityLabel, self.detailLabel.accessibilityLabel);
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitButton | (self.isSelected ? UIAccessibilityTraitSelected : 0);
}

@end
