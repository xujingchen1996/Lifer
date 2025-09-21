//
//  Item.swift
//  Lifer
//
//  Created by Tron Xu on 24/3/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
