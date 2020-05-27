//
//  Transaction.swift
//  trc-ios
//
//  Created by N Lennox on 2020/01/3.
//  Copyright © 2020 Level-Up Consulting Ltd. All rights reserved.
//

import Foundation

struct Transaction: Decodable {
    var timestamp:String
    var desc: String
    var amount: Double
}
