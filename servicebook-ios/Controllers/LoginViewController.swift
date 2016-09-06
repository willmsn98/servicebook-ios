//
//  LoginViewController.swift
//  servicebook-ios
//
//  Created by Christopher Williamson on 9/4/16.
//  Copyright © 2016 Christopher Williamson. All rights reserved.
//

import Foundation
import UIKit
import FacebookLogin
import FacebookCore

class LoginViewController: UIViewController, LoginButtonDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        UserProfile.updatesOnAccessTokenChange = true
        if AccessToken.current != nil {
            if let facebookId = AccessToken.current?.userId {
                let pm = PersistenceManager.sharedInstance
                pm.setUser(facebookId)
            }
            dispatch_async(dispatch_get_main_queue()){
                self.performSegueWithIdentifier("MainSegue", sender: self)
            }
        }
        
        let loginButton = LoginButton(readPermissions: [ .PublicProfile, .Email, .Custom("user_location") ])
        loginButton.center = view.center
        loginButton.delegate = self
        
        view.addSubview(loginButton)
    }
    
    func loginButtonDidCompleteLogin(loginButton: LoginButton, result: LoginResult) {

        switch result {
            case .Success(_, _, let token):
                if let facebookId = token.userId {
                    let pm = PersistenceManager.sharedInstance
                    pm.setUser(facebookId)
                }
                dispatch_async(dispatch_get_main_queue()){
                    self.performSegueWithIdentifier("MainSegue", sender: self)
                }
            case .Failed(let errorType):
                print(errorType)
            default:
                print("fail")
        }
    }
    
    func loginButtonDidLogOut(loginButton: LoginButton) {
        
    }
}