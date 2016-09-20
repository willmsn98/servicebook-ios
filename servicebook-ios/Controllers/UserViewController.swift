//
//  UserViewController.swift
//  servicebook-ios
//
//  Created by Christopher Williamson on 9/7/16.
//  Copyright © 2016 Christopher Williamson. All rights reserved.
//

import Foundation

import UIKit
import FacebookLogin
import FacebookCore

class UserViewController: UIViewController, LoginButtonDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    var loginButton:LoginButton!
    
    override func viewDidLoad() {
        
        loginButton = LoginButton(readPermissions: [ .PublicProfile, .Email, .Custom("user_location") ])
        loginButton.center = view.center
        loginButton.delegate = self
        
        view.addSubview(loginButton)
        
        UserProfile.updatesOnAccessTokenChange = true
        if AccessToken.current != nil {
            showUser()
        } else {
            showLogin()
        }
    }
    
    func showLogin() {
        locationLabel.hidden = true
        imageView.hidden = true
        nameLabel.text = "Please Login"
    }

    func showUser() {
        
        if let facebookId = AccessToken.current?.userId {
            let pm = PersistenceManager.sharedInstance
            pm.setUser(facebookId).onSuccess(callback: { (user) in

                self.nameLabel.text = "\(user.firstName ?? "")  \(user.lastName ?? "")"
                self.locationLabel.text = "\(user.city ?? "Location Unknown")"
                self.locationLabel.hidden = false
                
                if let facebookId = user.facebookId {
                    pm.getFacebookImage(facebookId, height: 100).onSuccess(callback: { (image) in
                        let circularImage = image.af_imageRoundedIntoCircle()
                        self.imageView.image = circularImage
                        self.imageView.hidden = false
                    }).onFailure(callback: { (error) in
                        print(error)
                    })
                }
            })
                

        }
    }

    func loginButtonDidCompleteLogin(loginButton: LoginButton, result: LoginResult) {
        
        switch result {
        case .Success(_, _, _):
            showUser()
        case .Failed(let errorType):
            print(errorType)
        case .Cancelled:
            print("login cancelled")
        }
    }
    
    func loginButtonDidLogOut(loginButton: LoginButton) {
        showLogin()
    }

}

