//
//  JCSignupView.h
//  JourneyCapture
//
//  Created by Chris Sloey on 26/02/2014.
//  Copyright (c) 2014 FCD. All rights reserved.
//

#import <UIKit/UIKit.h>
@class JCSignupViewModel;

@interface JCSignupView : UIView
@property (strong, nonatomic) JCSignupViewModel *viewModel;
@property (strong, nonatomic) UITextField *emailField;
@property (strong, nonatomic) UITextField *passwordField;
@property (strong, nonatomic) UITextField *firstNameField;
@property (strong, nonatomic) UITextField *lastNameField;

- (id)initWithFrame:(CGRect)frame viewModel:(JCSignupViewModel *)signupViewModel;
@end