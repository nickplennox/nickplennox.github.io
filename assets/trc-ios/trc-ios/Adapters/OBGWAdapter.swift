//
//  OBGWAdapter.swift
//  trc-ios
//
//  Created by N Lennox on 2020/01/2.
//  Copyright © 2020 Level-Up Consulting Ltd. All rights reserved.
//

import Foundation

protocol OBGWAdapter {
    func getMiniStatement(completion:@escaping(MiniStatementResponse?) -> Void)
    func revokeAccount(oid: String, completion:@escaping(Bool) -> Void)
    
}
