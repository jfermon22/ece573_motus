//
//  GestureDetector.swift
//  Motus
//
//  Created by Jeff Fermon on 2/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import UIKit

protocol GestureDetectorDelegate {
    //func gotGesture(gesture:UIGestureRecognizer)
    func gotNewGestureRequest(request:String)
}

enum GestureType: UInt32 {
    case Pinch
    case Swipe
    case Tap
    
    private static let _count: GestureType.RawValue = {
        // find the maximum enum value
        var maxValue: UInt32 = 0
        while let _ = GestureType(rawValue: ++maxValue) { }
        return maxValue
    }()
    
    static func random() -> GestureType {
        // pick and return a new value
        let rand = arc4random_uniform(_count)
        return GestureType(rawValue: rand)!
    }
}

class GestureDetector :NSObject, UIGestureRecognizerDelegate {
    //MARK: public members
    var view:UIView?{
        set {
            _view = newValue
            updateRecognizer()
        }
        get { return _view }
    }
    var gestureRecognizer:UIGestureRecognizer?
    var delegate:GestureDetectorDelegate?
    
    
    private(set) var request:String?
    private var waitSem = dispatch_semaphore_create(0)
    
    private var gesturesReceived:UInt32 = 0
    private var gesturesToSatisfySet:UInt32 = 0
    private var setsToSatisfyTask = 5
    private var setsComplete = 0
    private var currentGesture:GestureType {
        set {
            _currentGesture = newValue
            updateRecognizer()
        }
        get { return _currentGesture }
    }
    private var _view:UIView?
    private var isWaiting = false
    private var lastPinchReceived = NSDate(timeIntervalSince1970: 1415637900)
    private var _currentGesture:GestureType = .Pinch
    
    
    //MARK: Constructors
    private override init() {
        super.init()
    }
    
    convenience init( uiview:UIView) {
        self.init()
        view = uiview
    }
    
    deinit {
        removeRecognizer()
        gestureRecognizer = nil
        request = nil
        view = nil
    }
    
    
    //MARK: Gesture Recognizer Handler Functions
    //removes any current gesture recognizers and adds new gesture recognizer
    private func updateRecognizer() {
        
        removeRecognizer()
        
        switch currentGesture {
        case .Pinch:
                gestureRecognizer = UIPinchGestureRecognizer (target: self, action: #selector(GestureDetector.handleGesture(_:)))
            break
        case .Tap:
                gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(GestureDetector.handleGesture(_:)))
            break
        case .Swipe:
                gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(GestureDetector.handleGesture(_:)))
            break
        }
        
        gestureRecognizer?.delegate = self
        view!.addGestureRecognizer(gestureRecognizer!)
    }
    
    //Removes gesture recognizer from current view
    func removeRecognizer() {
        if view != nil {
            if let _ = view!.gestureRecognizers {
                    view?.removeGestureRecognizer(gestureRecognizer!)
                }
        }
    }
    
     //function to handle gesture received through gesture recognizers
    func handleGesture(sender: UIGestureRecognizer? = nil) {
        if let _ = sender as? UIPinchGestureRecognizer {
            if abs(lastPinchReceived.timeIntervalSinceNow) > 0.5  {
                print("RECEIVED PINCH")
                lastPinchReceived = NSDate()
                receivedGesture()
            }
        } else if let _ = sender as? UISwipeGestureRecognizer {
            print("RECEIVED SWIPE")
            receivedGesture()
            
        } else if let _ = sender as? UITapGestureRecognizer {
            print("RECEIVED TAP")
            receivedGesture()
        }
    }
    
    //MARK: Update Methods
    func waitTilUserSatisfyRequests( timeout: UInt64) -> Bool{
        
        isWaiting = true
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            self.startRequests()
        }
        waitSem = dispatch_semaphore_create(0)
        
        //timeout in nanoseconds
        let timeoutNs = Int64(timeout) * Int64(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, timeoutNs )
        let requestsSatified = dispatch_semaphore_wait(waitSem, time ) == 0
        
        isWaiting = false
        
        return requestsSatified
    }
    
    func startRequests() {
        //enable touch for view
        self.view?.userInteractionEnabled = true
        
        //reset setsComplete variable since user has not completed anything yet
        setsComplete = 0
        
        repeat {
            //repeat while the number of set of gestures completed are less than the
            //number we need to satisfy and we are waiting
            
            //reset gesturesReceived variable since user has not completed anything yet
            gesturesReceived = 0
            
            
            var newGesture:GestureType?
            repeat {
                //get random gestures until the current gesture is not the same as the current gesture
                newGesture = GestureType.random()
            } while newGesture == currentGesture
            currentGesture = newGesture!
            
            //get a random number between 1 and 5 to determine how many of a singe gesture 
            // a user must complete until they can move on to the next gesture
            gesturesToSatisfySet = arc4random_uniform(4) + 1
            
            //Send new gesture string to the delegate
            sendRequest()
            
            repeat {
                //repeat while the number of gestures received are less than the
                //number we need to satisfy and we waiting
                usleep(1000)
            } while ( gesturesReceived < gesturesToSatisfySet && isWaiting )
            
            if isWaiting {
                //if we are waiting then increase the number of sets completed
                setsComplete += 1
                //print("Set Complete")
            }
            
        } while ( setsComplete < setsToSatisfyTask && isWaiting )
        
        dispatch_semaphore_signal(waitSem)
    }
    
    //Send a new gesture request to the delegate
    func sendRequest() {
        switch currentGesture {
        case .Pinch:
            request = "Pinch"
            break
        case .Tap:
            request = "Tap"
            break
        case .Swipe:
            request = "Swipe"
            break
        }
        
        request?.appendContentsOf(" \(gesturesToSatisfySet) times")
        delegate?.gotNewGestureRequest(request!)
    }
    
    //Helper function to send a gesture request tot the delegate every time a gesture is received
    func receivedGesture() {
        gesturesReceived += 1
        switch currentGesture {
        case .Pinch:
            request = "Pinch"
            break
        case .Tap:
            request = "Tap"
            break
        case .Swipe:
            request = "Swipe"
            break
        }
        
        let gesturesLeft = gesturesToSatisfySet - gesturesReceived
        
        if gesturesLeft == 0 {
            request = "Complete!"
        }
        else if gesturesLeft == 1 {
            request?.appendContentsOf(" \(gesturesLeft) more time")
        } else {
            request?.appendContentsOf(" \(gesturesLeft) more times")
        }
        
        delegate?.gotNewGestureRequest(request!)
    }
    
    
}