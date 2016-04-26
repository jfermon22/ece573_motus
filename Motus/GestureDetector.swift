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
            updateRecognizers()
        }
        get { return _view }
    }
    var tapRecognizer:UITapGestureRecognizer?
    var swipeRecognizer:UISwipeGestureRecognizer?
    var pinchRecognizer:UIPinchGestureRecognizer?
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
            updateRecognizers()
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
        removeRecognizers()
        tapRecognizer = nil
        swipeRecognizer = nil
        pinchRecognizer = nil
        view = nil
        
    }
    
    
    //MARK: Gesture Handlers
    private func updateRecognizers() {
        removeRecognizers()
        
        switch currentGesture {
        case .Pinch:
            if pinchRecognizer == nil {
                pinchRecognizer = UIPinchGestureRecognizer (target: self, action: #selector(GestureDetector.handleGesture(_:)))
            }
            pinchRecognizer?.delegate = self
            view!.addGestureRecognizer(pinchRecognizer!)
            break
        case .Tap:
            if tapRecognizer == nil {
                tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(GestureDetector.handleGesture(_:)))
            }
            tapRecognizer?.delegate = self
            view!.addGestureRecognizer(tapRecognizer!)
            break
        case .Swipe:
            if swipeRecognizer == nil {
                swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(GestureDetector.handleGesture(_:)))
            }
            swipeRecognizer?.delegate = self
            view!.addGestureRecognizer(swipeRecognizer!)
            break
        }
    }
    
    func removeRecognizers() {
        if view != nil {
            if let gestureRecognizerArray = view!.gestureRecognizers {
                for gestureRecognizer in gestureRecognizerArray {
                    view?.removeGestureRecognizer(gestureRecognizer)
                }
            }
        }
    }
    
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
        
        setsComplete = 0
        
        repeat {
            gesturesReceived = 0
            
            var newGesture:GestureType?
            repeat {
                newGesture = GestureType.random()
            } while newGesture == currentGesture
            
            currentGesture = newGesture!
            gesturesToSatisfySet = arc4random_uniform(4) + 1
            sendRequest()
            repeat {
                usleep(1000)
            } while ( gesturesReceived < gesturesToSatisfySet && isWaiting )
            
            if isWaiting {
                setsComplete += 1
                print("Set Complete")
            }
            
        } while ( setsComplete < setsToSatisfyTask && isWaiting )
        
        dispatch_semaphore_signal(waitSem)
        
    }
    
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
        
        request?.appendContentsOf(" \(gesturesToSatisfySet - gesturesReceived) more times")
        delegate?.gotNewGestureRequest(request!)
    }
    
    
}