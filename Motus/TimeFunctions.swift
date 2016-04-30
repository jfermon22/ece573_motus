//
//  TimeFunctions.swift
//  Motus
//
//  Created by Jeff Fermon on 2/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation

class TimeFunctions {
    // helper function to format and NSDate into a string
    static func formatTimeForDisplay(date:NSDate) -> String {
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
        return formatter.stringFromDate(date)
    }
    
}