//
//  Array+Extensions.swift
//  SwiftGoal
//
//  Created by Daniel Morgz on 13/02/2016.
//  Copyright © 2016 Martin Richter. All rights reserved.
//

import Foundation

extension Array where Element : Equatable {
    // Remove first collection element that is equal to the given `object`:
    mutating func removeObject(object : Generator.Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
}