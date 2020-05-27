//
//  MiniStatementResponse.swift
//  trc-ios
//
//  Created by N Lennox on 2020/01/3.
//  Copyright © 2020 Level-Up Consulting Ltd. All rights reserved.
//

import Foundation

struct MiniStatementResponse: Decodable {
    var accountName: String
    var balance: Double?
    var transactions: [Transaction]
}
