//
//  NSObjectExtension.swift

//  SukshiTaskFramework

//  Created by Nitu Warjurkar on 15/06/20.
//  Copyright © 2020 Nitu Warjurkar. All rights reserved.
//

import Foundation
import UIKit
//Mark: NSObject
 

//Mark: UIViewcontroller
public extension UIViewController
{
     
     
    func isConnectedToInternet(errorMessage:String)->Bool
    {
        let status = Reach().connectionStatus()
        
        switch status
        {
        case .unknown, .offline:
            displayActivityAlert(title: errorMessage)
            return false
        case .online(.wwan):
            return true
        case .online(.wiFi):
            return true
        }
        
    }
    
    func displayActivityAlert(title: String)
    {
        DispatchQueue.main.async
        {
            let pending = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            
            self.present(pending, animated: true, completion: nil)
            let deadlineTime = DispatchTime.now() + .seconds(2)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime)
            {
                pending.dismiss(animated: true, completion: nil)
                
            }
        }
        
    }
     
    func showHUD(message:String)
    {
        DispatchQueue.main.async {
            ALLoadingView.manager.resetToDefaults()
            ALLoadingView.manager.showLoadingView(ofType: .messageWithIndicator, windowMode: .fullscreen)
            ALLoadingView.manager.messageText = message
        }
        
    }
    func hideHUD()
    {
        DispatchQueue.main.async {
            ALLoadingView.manager.hideLoadingView(withDelay: 0.0)
        }
    }
}
 
extension UIView {
    func makeRound(cornerRadius : CGFloat = 10 ) {
        layer.cornerRadius = cornerRadius
        clipsToBounds = true
    }
}
 
 extension NSMutableData {
     
     func appendString(_ string: String) {
         let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
         append(data!)
     }
 }

