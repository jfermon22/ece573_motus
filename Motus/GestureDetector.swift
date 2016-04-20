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
    func gotNewRequest(request:String)
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
    private var currentGesture:GestureType = GestureType.Pinch
    private var _view:UIView?
    private var isWaiting = false
    private var lastPinchReceived = NSDate(timeIntervalSince1970: 1415637900)
    
    
    //MARK: Constructors
    private override init() {
        super.init()
    }
    
    convenience init( uiview:UIView) {
        self.init()
        view = uiview
    }
    
    deinit {
        if view != nil {
            if let gestureRecognizerArray = view!.gestureRecognizers {
                for gestureRecognizer in gestureRecognizerArray {
                    view?.removeGestureRecognizer(gestureRecognizer)
                }
            }
        }
        tapRecognizer = nil
        swipeRecognizer = nil
        pinchRecognizer = nil
        view = nil

    }
    
    
    //MARK: Gesture Handlers
    private func updateRecognizers() {
        if view != nil {
            if let gestureRecognizerArray = view!.gestureRecognizers {
                for gestureRecognizer in gestureRecognizerArray {
                     view?.removeGestureRecognizer(gestureRecognizer)
                }
            }
        }
        
        if tapRecognizer == nil {
            tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(GestureDetector.handleTap(_:)))
        }
        if swipeRecognizer == nil {
            swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(GestureDetector.handleSwipe(_:)))
        }
        if pinchRecognizer == nil {
            pinchRecognizer = UIPinchGestureRecognizer (target: self, action: #selector(GestureDetector.handlePinch(_:)))
        }
        
        tapRecognizer?.delegate = self
        swipeRecognizer?.delegate = self
        pinchRecognizer?.delegate = self
        
        // add tap as a gestureRecognizer to tapView
        view!.addGestureRecognizer(tapRecognizer!)
        view!.addGestureRecognizer(swipeRecognizer!)
        view!.addGestureRecognizer(pinchRecognizer!)
    }
    
    func handleTap(sender: UITapGestureRecognizer? = nil) {
        if(currentGesture == GestureType.Tap){
            print("RECEIVED TAP")
            receivedGesture()
        }
    }
    
    func handleSwipe(sender: UITapGestureRecognizer? = nil) {
        if(currentGesture == GestureType.Swipe){
            print("RECEIVED SWIPE")
            receivedGesture()
        }
    }
    func handlePinch(sender: UITapGestureRecognizer? = nil) {
        if( currentGesture == GestureType.Pinch &&
             abs(lastPinchReceived.timeIntervalSinceNow) > 0.5 )
        {
            print("RECEIVED PINCH")
            lastPinchReceived = NSDate()
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
            currentGesture = GestureType.random()
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
        delegate?.gotNewRequest(request!)
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
        delegate?.gotNewRequest(request!)
    }
    
    
}