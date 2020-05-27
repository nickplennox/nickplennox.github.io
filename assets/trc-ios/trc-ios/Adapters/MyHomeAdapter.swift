//
//  MyHomeAdapter.swift
//  trc-ios
//
//  Created by N Lennox on 2020/01/2.
//  Copyright © 2020 Level-Up Consulting Ltd. All rights reserved.
//

import Foundation


//
// Protocol for a My Home Adapter class, defines the required methods for a swappable adapter for this API
protocol MyHomeAdapter {
    // Get a My Home unique identifier for a given email address
    func getUid(email:String, completion:@escaping(String?) -> Void)
}
