//
//  JCCaptureView.m
//  JourneyCapture
//
//  Created by Chris Sloey on 07/03/2014.
//  Copyright (c) 2014 FCD. All rights reserved.
//

@import QuartzCore;
#import "JCCaptureView.h"
#import "JCCaptureViewModel.h"
#import "JCCaptureStatsView.h"
#import "RoutePoint.h"

#define MAX_GRAPH_POINTS 20

@implementation JCCaptureView

- (id)initWithViewModel:(JCCaptureViewModel *)captureViewModel
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _viewModel = captureViewModel;
    
    // Map view
    _mapView = [MKMapView new];
    _mapView.translatesAutoresizingMaskIntoConstraints = NO;
    _mapView.delegate = self;
    _mapView.showsUserLocation = YES;
    [_mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    _mapView.zoomEnabled = NO;
    _mapView.scrollEnabled = NO;
    _mapView.userInteractionEnabled = NO;
    _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_mapView];
    
    // Stats
    _graphView = [JBLineChartView new];
    _graphView.delegate = self;
    _graphView.dataSource = self;
    _graphView.translatesAutoresizingMaskIntoConstraints = NO;
    _graphView.showsLineSelection = NO;
    _graphView.showsVerticalSelection = NO;
    _graphView.frame = CGRectMake(0, 240, self.frame.size.width, 40);
    [self addSubview:_graphView];
    [_graphView reloadData];
    
    _statsView = [[JCCaptureStatsView alloc] initWithViewModel:_viewModel];
    _statsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_statsView];

    // Capture button
    UIColor *buttonColor = [UIColor jc_redColor];
    _captureButton = [UIButton new];
    _captureButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_captureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_captureButton setTitle:@"Finish Route" forState:UIControlStateNormal];
    [_captureButton setBackgroundColor:buttonColor];
    _captureButton.layer.masksToBounds = YES;
    _captureButton.layer.cornerRadius = 4.0f;
    [self addSubview:_captureButton];

    return self;
}

- (void)updateRouteLine
{
    NSUInteger numPoints = [_viewModel.points count];

    if (numPoints < 2) {
        return;
    }

    RoutePoint *point = _viewModel.points[numPoints-1];
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([point.lat doubleValue],
                                                              [point.lng doubleValue]);

    RoutePoint *previousPoint = _viewModel.points[numPoints-2];
    CLLocationCoordinate2D previousCoord = CLLocationCoordinate2DMake([previousPoint.lat doubleValue],
                                                                      [previousPoint.lng doubleValue]);

    MKMapPoint *pointsArray = malloc(sizeof(CLLocationCoordinate2D)*2);
    pointsArray[0]= MKMapPointForCoordinate(previousCoord);
    pointsArray[1]= MKMapPointForCoordinate(coord);

    _routeLine = [MKPolyline polylineWithPoints:pointsArray count:2];
    free(pointsArray);

    [_mapView addOverlay:_routeLine];
    [_graphView reloadData];
}

#pragma mark - UIView

- (void)layoutSubviews
{
    [_captureButton autoRemoveConstraintsAffectingView];
    [_captureButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(15, 15, 15, 15) excludingEdge:ALEdgeTop];
    [_captureButton autoSetDimension:ALDimensionHeight toSize:42.5f];
    
    [_graphView autoRemoveConstraintsAffectingView];
    [_graphView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:_statsView withOffset:-10];
    [_graphView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self];
    [_graphView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self];
    [_graphView autoSetDimension:ALDimensionHeight toSize:40];
    
    [_statsView autoRemoveConstraintsAffectingView];
    [_statsView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_graphView withOffset:10];
    [_statsView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:_captureButton];
    [_statsView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self];
    [_statsView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self];
    [_statsView autoSetDimension:ALDimensionHeight toSize:120];
    
    [_mapView autoRemoveConstraintsAffectingView];
    [_mapView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [_mapView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:_graphView withOffset:-10];
    
    [super layoutSubviews];
}

#pragma mark - MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    renderer.strokeColor = self.tintColor;
    renderer.lineWidth = 2.5;
    return  renderer;
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    // Ensure mapview is zoomed in to a reasonable amount when user location is found
    // (seems to be an issue with mapView userTrackingEnabled where this sometimes doesn't happen)
    MKCoordinateSpan zoomSpan = _mapView.region.span;
    BOOL notZoomed = zoomSpan.latitudeDelta > 1 || zoomSpan.longitudeDelta > 1;
    
    CLLocation *mapLoc = [[CLLocation alloc] initWithLatitude:_mapView.region.center.latitude longitude:_mapView.region.center.longitude];
    BOOL farAway = [mapLoc distanceFromLocation:userLocation.location] > 500;
    if (notZoomed || farAway) {
        // 1 might be a bit large, but delta is typically initially ~50-55
        CLLocationCoordinate2D loc = [userLocation coordinate];
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(loc, 1000, 1000);
        [_mapView setRegion:region animated:YES];
    }
}

#pragma mark - JBLineChartViewDataSource

- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView
{
    return 1;
}

- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex
{
    return MAX_GRAPH_POINTS;
}

#pragma mark - JBLineChartViewDelegate

-(CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex
            atLineIndex:(NSUInteger)lineIndex
{
    NSInteger index = horizontalIndex;
    if (_viewModel.points.count < MAX_GRAPH_POINTS) {
        NSUInteger offset = MAX_GRAPH_POINTS - _viewModel.points.count;
        index -= offset;
        
        if (index < 0) {
            return 0.0f;
        }
    }
    
    if (_viewModel.points.count > MAX_GRAPH_POINTS) {
        index = _viewModel.points.count - MAX_GRAPH_POINTS + horizontalIndex;
    }
    
    RoutePoint *point = _viewModel.points[index];
    CGFloat speed = [point.kph floatValue];
    if (!speed  || speed < 0) {
        speed = 0.0f;
    }
    return speed;
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSUInteger)lineIndex
{
    return [UIColor jc_blueColor];
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView widthForLineAtLineIndex:(NSUInteger)lineIndex
{
    return 4.0f;
}

@end