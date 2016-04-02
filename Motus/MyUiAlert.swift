//
//  MyUiAlert.swift
//  Motus
//
//  Created by Jeff Fermon on 4/1/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import UIKit


/*class MyUiAlert {
    private var alertController:UIAlertController
    private let waitSem = dispatch_semaphore_create(0)
    private var alertAction:UIAlertAction?
    init(){
        
        
    }
    
    convenience init(title:String, message:String, style:UIAlertControllerStyle, action:UIAlertAction, view:UIViewController) {
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.alertController = UIAlertController(title: title, message: message, preferredStyle: style)
            self.alertAction = UIAlertAction(title: "OK", style: .Default) {
                (action) in
                dispatch_semaphore_signal(self.waitSem)
            }
            
            self.alertController.addAction(self.alertAction!)
            
            view.presentViewController(self.alertController, animated: true, completion: nil)
        }
        
        dispatch_semaphore_wait(waitSem, DISPATCH_TIME_FOREVER)
    }
 
    func present() {
        
    }
    
}*/