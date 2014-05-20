//
//  JCLineGraphView.h
//  JourneyCapture
//
//  Created by Chris Sloey on 19/05/2014.
//  Copyright (c) 2014 FCD. All rights reserved.
//

@import UIKit;
#import "JCGraphView.h"
#import "JBLineChartView.h"

@interface JCLineGraphView : JCGraphView <JBLineChartViewDelegate, JBLineChartViewDataSource>

@end
