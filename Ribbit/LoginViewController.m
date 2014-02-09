//
//  LoginViewController.m
//  Ribbit
//
//  Created by Tord Åsnes on 04/11/13.
//  Copyright (c) 2013 Tord Åsnes. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
    if ([SnapchatClient storedUsername] && [SnapchatClient storedPassword]) {
        self.usernameField.text = [SnapchatClient storedUsername];
        self.passwordField.text = [SnapchatClient storedPassword];
        [self logIn:nil];
    }
}

- (IBAction)logIn:(id)sender {
    
    NSString *username = [self.usernameField.text
                          stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString *password = [self.passwordField.text
                          stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([username length] == 0 || [password length] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                            message:@"Make sure you enter a username and password!"
                                                           delegate:Nil cancelButtonTitle:@"Okey"
                                                  otherButtonTitles:nil];
        [alertView show];
    } else {
        __block LoginViewController *me = self;
        // TODO remove coupling with PFUser (prefer SCUser)
        void (^block)(PFUser*, NSError*) = ^(PFUser *user, NSError *error) {
            if (error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry!"
                                                                    message:[error.userInfo objectForKey:@"error"]
                                                                   delegate:Nil cancelButtonTitle:@"Ok"
                                                          otherButtonTitles:nil];
                [alertView show];
            } else {
                [Delegate initiateDownload];
                [me.navigationController popToRootViewControllerAnimated:YES];
            }
        };
        
        [SnapchatClient logInWithUsername:username password:password block:block];
    }
}



@end
