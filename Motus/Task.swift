//
//  Task.swift
//  Motus
//
//  Created by Jeff Fermon on 3/3/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation

enum TaskErrors:ErrorType {
    case RandomWhenUnexpected
}

enum Task: UInt32 {
    case LOCATION
    //case MOTION
    case GESTURE
    case RANDOM
    
    private static let _count: Task.RawValue = {
        // find the maximum enum value
        var maxValue: UInt32 = 0
        while let _ = Task(rawValue: ++maxValue) { }
        return maxValue
    }()
    
    static func random() -> Task {
        // pick and return a new value
        let rand = arc4random_uniform(_count)
        return Task(rawValue: rand)!
    }
    
    static func GetText(task:Task) -> String {
        switch task {
        case .LOCATION:
            return "Move 20 ft."
        case .GESTURE:
            return "Screen Gestures"
        case .RANDOM:
            return "Random"
        }
    }

};