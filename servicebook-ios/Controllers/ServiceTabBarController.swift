//
//  ServiceTabBarController.swift
//  servicebook-ios
//
//  Created by Christopher Williamson on 9/20/16.
//  Copyright © 2016 Christopher Williamson. All rights reserved.
//

import UIKit
import FontAwesome_swift


class ServiceTabBarController: UITabBarController {
    
    var fonts = [FontAwesome.Calendar, FontAwesome.User]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if var tabItems = self.tabBar.items {
            for index in 0...fonts.count - 1{
                tabItems[index].image = UIImage.fontAwesomeIconWithName(fonts[index], textColor: UIColor.whiteColor(), size: CGSizeMake(30, 30))
            }
        }
    }
}