//
//  JCCaptureView.m
//  JourneyCapture
//
//  Created by Chris Sloey on 07/03/2014.
//  Copyright (c) 2014 FCD. All rights reserved.
//

#import "JCCaptureView.h"
#import <QuartzCore/QuartzCore.h>
#import "JCRouteCaptureViewModel.h"
#import "JCRoutePointViewModel.h"

@implementation JCCaptureView
@synthesize mapview, routeLine, routeLineView, captureButton, statsTable, viewModel,
            reviewScrollView, safetyRating, safetyReviewLabel, environmentRating, environmentReviewLabel,
            difficultyRating, difficultyReviewLabel, animator;

- (id)initWithFrame:(CGRect)frame viewModel:(JCRouteCaptureViewModel *)captureViewModel
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    self.viewModel = captureViewModel;
    self.animator = [IFTTTAnimator new];

    // Capture button
    UIColor *buttonColor = [UIColor colorWithRed:0 green:224.0/255.0 blue:184.0/255.0 alpha:1.0];
    CGRect buttonFrame = CGRectMake(22, self.frame.size.height - 75, self.frame.size.width - 44, 50);
    self.captureButton = [[UIButton alloc] initWithFrame:buttonFrame];
    [self.captureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.captureButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.captureButton setBackgroundColor:buttonColor];
    self.captureButton.layer.masksToBounds = YES;
    self.captureButton.layer.cornerRadius = 8.0f;
    [self addSubview:self.captureButton];

    // Map view
    self.mapview = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - 100)];
    self.mapview.layer.masksToBounds = NO;
    self.mapview.layer.shadowOffset = CGSizeMake(0, 1);
    self.mapview.layer.shadowRadius = 2;
    self.mapview.layer.shadowOpacity = 0.5;
    [self addSubview:self.mapview];

    self.mapview.showsUserLocation = YES;
    [self.mapview setDelegate:self];
    [self.mapview setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    [self.mapview setUserInteractionEnabled:NO];

    // Stats
    self.statsTable = [[UITableView alloc] init];
    [self insertSubview:self.statsTable belowSubview:self.mapview];
    [self.statsTable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.captureButton.mas_top).with.offset(-25);
        make.left.equalTo(self);
        make.right.equalTo(self);
        make.height.equalTo(@(self.frame.size.height - 400));
    }];

    // Review elements
    self.reviewScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.frame.size.height,
                                                                              self.frame.size.width, 100)];
    self.reviewScrollView.contentSize = CGSizeMake(self.frame.size.width * 4, self.reviewScrollView.frame.size.height);
    self.reviewScrollView.pagingEnabled = YES;
    self.reviewScrollView.showsHorizontalScrollIndicator = NO;
    self.reviewScrollView.contentSize = CGSizeMake(self.reviewScrollView.contentSize.width, self.reviewScrollView.frame.size.height);

    [self addSubview:self.reviewScrollView];

    double labelY = 20;
    double labelHeight = 21;
    double ratingY = self.safetyReviewLabel.frame.origin.y + labelHeight + 20;
    double ratingWidth = 100;
    double ratingX = (self.frame.size.width/2) - (ratingWidth/2);
    double ratingHeight = 30;

    // Guidance
    self.reviewGuidanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, ratingY + ratingHeight + 10, self.frame.size.width, labelHeight)];
    [self.reviewGuidanceLabel setText:@"Tap to review"];
    [self.reviewGuidanceLabel setTextAlignment:NSTextAlignmentCenter];
    [self.reviewScrollView addSubview:self.reviewGuidanceLabel];

    // Animate review guidance label with scroll
    IFTTTFrameAnimation *frameAnimation = [IFTTTFrameAnimation new];
    frameAnimation.view = self.reviewGuidanceLabel;
    [frameAnimation addKeyFrame:[[IFTTTAnimationKeyFrame alloc] initWithTime:0
                                                                    andFrame:CGRectMake(0,
                                                                                        ratingY + ratingHeight + 10,
                                                                                        self.frame.size.width, labelHeight)]];
    [frameAnimation addKeyFrame:[[IFTTTAnimationKeyFrame alloc] initWithTime:self.frame.size.width
                                                                    andFrame:CGRectMake(self.frame.size.width,
                                                                                        ratingY + ratingHeight + 10,
                                                                                        self.frame.size.width, labelHeight)]];
    [frameAnimation addKeyFrame:[[IFTTTAnimationKeyFrame alloc] initWithTime:self.frame.size.width*2
                                                                    andFrame:CGRectMake(self.frame.size.width*2,
                                                                                        ratingY + ratingHeight + 10,
                                                                                        self.frame.size.width, labelHeight)]];
    [self.animator addAnimation:frameAnimation];

    [RACObserve(self.reviewScrollView, contentOffset) subscribeNext:^(NSValue *value) {
        NSInteger x = floor(self.reviewScrollView.contentOffset.x);
        [self.animator animate:x];
    }];

    // Safety rating
    self.safetyReviewLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, labelY, self.frame.size.width, labelHeight)];
    [self.safetyReviewLabel setText:@"Safety Rating"];
    [self.safetyReviewLabel setTextAlignment:NSTextAlignmentCenter];
    [self.reviewScrollView addSubview:self.safetyReviewLabel];

    self.safetyRating = [[EDStarRating alloc] initWithFrame:CGRectMake(ratingX, ratingY, ratingWidth, ratingHeight)];
    [self.safetyRating setEditable:YES];
    [self.safetyRating setDisplayMode:EDStarRatingDisplayFull];
    self.safetyRating.starImage = [UIImage imageNamed:@"star-template"];
    self.safetyRating.starHighlightedImage = [UIImage imageNamed:@"star-highlighted-template"];
    [self.safetyRating setBackgroundColor:[UIColor clearColor]];
    self.safetyRating.horizontalMargin = 5;
    [self.safetyRating setDelegate:self];
    [self.reviewScrollView addSubview:self.safetyRating];

    // Environment rating
    self.environmentReviewLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width, labelY, self.frame.size.width, labelHeight)];
    [self.environmentReviewLabel setText:@"Environment Rating"];
    [self.environmentReviewLabel setTextAlignment:NSTextAlignmentCenter];
    [self.reviewScrollView addSubview:self.environmentReviewLabel];

    self.environmentRating = [[EDStarRating alloc] initWithFrame:CGRectMake(ratingX + self.frame.size.width, ratingY, ratingWidth, ratingHeight)];
    [self.environmentRating setEditable:YES];
    [self.environmentRating setDisplayMode:EDStarRatingDisplayFull];
    self.environmentRating.starImage = [UIImage imageNamed:@"star-template"];
    self.environmentRating.starHighlightedImage = [UIImage imageNamed:@"star-highlighted-template"];
    [self.environmentRating setBackgroundColor:[UIColor clearColor]];
    self.environmentRating.horizontalMargin = 5;
    [self.environmentRating setDelegate:self];
    [self.reviewScrollView addSubview:self.environmentRating];

    // Difficulty rating
    self.difficultyReviewLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width*2, labelY, self.frame.size.width, labelHeight)];
    [self.difficultyReviewLabel setText:@"Difficulty Rating"];
    [self.difficultyReviewLabel setTextAlignment:NSTextAlignmentCenter];
    [self.reviewScrollView addSubview:self.difficultyReviewLabel];

    self.difficultyRating = [[EDStarRating alloc] initWithFrame:CGRectMake(ratingX + (self.frame.size.width * 2), ratingY, ratingWidth, ratingHeight)];
    [self.difficultyRating setEditable:YES];
    [self.difficultyRating setDisplayMode:EDStarRatingDisplayFull];
    self.difficultyRating.starImage = [UIImage imageNamed:@"star-template"];
    self.difficultyRating.starHighlightedImage = [UIImage imageNamed:@"star-highlighted-template"];
    [self.difficultyRating setBackgroundColor:[UIColor clearColor]];
    self.difficultyRating.horizontalMargin = 5;
    [self.difficultyRating setDelegate:self];
    [self.reviewScrollView addSubview:self.difficultyRating];

    // Review complete
    self.reviewCompleteLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width*3, (self.reviewScrollView.frame.size.height/2) - labelHeight,
                                                                         self.frame.size.width, labelHeight)];
    [self.reviewCompleteLabel setText:@"Review completed! Thank you."];
    [self.reviewCompleteLabel setTextAlignment:NSTextAlignmentCenter];
    [self.reviewScrollView addSubview:self.reviewCompleteLabel];

    return self;
}

- (void)transitionToActive
{
    // Move map and button
    UIColor *stopColor = [UIColor colorWithRed:243.0/255.0 green:60.0/255.0 blue:60.0/255.0 alpha:1.0];
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options: UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.mapview.frame = CGRectMake(0, 0, self.frame.size.width, 300);
                         [self.captureButton setTitle:@"Stop" forState:UIControlStateNormal];
                         [self.captureButton setBackgroundColor:stopColor];
                     }
                     completion:^(BOOL finished){
                         NSLog(@"Animated to active!");
                     }];
}

- (void)transitionToComplete
{
    // Hide user location
    [self.mapview setShowsUserLocation:NO];

    // Slide stats and review view up
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options: UIViewAnimationOptionCurveLinear
                     animations:^{
                         // Shrink map, hide current speed
                         self.mapview.frame = CGRectMake(0, 0, self.frame.size.width, 200);

                         double statsHeight = self.statsTable.frame.size.height;
                         double tableOffset = statsHeight - (2 * [self.statsTable rowHeight]);
                         self.statsTable.frame = CGRectMake(0, 200 - tableOffset,
                                                            self.frame.size.width, self.statsTable.frame.size.height);

                         // Show review scrollview
                         double statsBottom = 200 - tableOffset + self.statsTable.frame.size.height;
                         self.reviewScrollView.frame = CGRectMake(0, statsBottom + 25,
                                                                  self.frame.size.width, self.reviewScrollView.frame.size.height);

                         // Submit button
                         [self.captureButton setTitle:@"Submit" forState:UIControlStateNormal];
                         [self.captureButton setBackgroundColor:self.tintColor];
                     }
                     completion:^(BOOL finished){
                         // Show entire route
                         MKMapRect zoomRect = MKMapRectNull;
                         for (JCRoutePointViewModel *point in self.viewModel.points)
                         {
                             MKMapPoint annotationPoint = MKMapPointForCoordinate(point.location.coordinate);
                             MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 2.0, 2.0);
                             zoomRect = MKMapRectUnion(zoomRect, pointRect);
                         }
                         [self.mapview setVisibleMapRect:zoomRect animated:YES];
                     }];
}

- (void)updateRouteLine
{
    NSUInteger numPoints = [self.viewModel.points count];

    if (numPoints < 2) {
        return;
    }

    JCRoutePointViewModel *point = self.viewModel.points[numPoints-1];
    CLLocationCoordinate2D coord = point.location.coordinate;

    JCRoutePointViewModel *previousPoint = self.viewModel.points[numPoints-2];
    CLLocationCoordinate2D previousCoord = previousPoint.location.coordinate;

    MKMapPoint *pointsArray = malloc(sizeof(CLLocationCoordinate2D)*2);
    pointsArray[0]= MKMapPointForCoordinate(previousCoord);
    pointsArray[1]= MKMapPointForCoordinate(coord);

    routeLine = [MKPolyline polylineWithPoints:pointsArray count:2];
    free(pointsArray);

    [[self mapview] addOverlay:routeLine];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    renderer.strokeColor = self.tintColor;
    renderer.lineWidth = 2.5;
    return  renderer;
}

- (void)starsSelectionChanged:(EDStarRating *)control rating:(float)rating
{
    // Show next review
    CGRect nextReviewRect = CGRectMake(self.reviewScrollView.contentOffset.x,
                                       self.reviewScrollView.contentOffset.y,
                                       self.reviewScrollView.bounds.size.width,
                                       self.reviewScrollView.contentOffset.y + self.reviewScrollView.bounds.size.height);
    nextReviewRect.origin.x += self.reviewScrollView.frame.size.width;
    [self.reviewScrollView scrollRectToVisible:nextReviewRect animated:YES];
}

@end
