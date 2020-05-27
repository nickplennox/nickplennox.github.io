//
//  CLOBGWAdapter.swift
//  trc-ios
//
//  Created by N Lennox on 2020/01/2.
//  Copyright © 2020 Level-Up Consulting Ltd. All rights reserved.
//

import Foundation

class CLOBGWAdapter: OBGWAdapter {

    //TODO: Make this like getUid
    // Create a struct (or better model class) for the response type and pass this back instead of
    // returning (Data?, HTTPURLResponse?, Error?)
    // This makes the top level much cleaner and keeps network concerns at this level
    
    let utils = Utils()
    let network = Network()
       
    internal func getMiniStatement(completion:@escaping(MiniStatementResponse?) -> Void) {
        
        print("getMiniStatement")

        let urlString =  String.init(format:"https://cl-ob-gw-dev.azurewebsites.net/api/ministatement?code=0UgDzTVSaCXqa2yawg5ea/hbgW1BERfENX/88TnlhNaUOQnin2YgXQ==")

        guard let url = URL(string: urlString)  else {
            fatalError("getMiniStatement: URL could not be created")
        }

        network.callAPI(url: url, method: "GET", body: nil, useStoredToken: true, xApiKey: nil) { (data, response, err) in
            // Handle errors
            if (err != nil) {
                fatalError("getMiniStatement: Error: \(err.debugDescription)")
            }
            guard let httpResponse:HTTPURLResponse = response else {
                 fatalError("response was nil")
                }

            // Handle 401 response (no account is linked)
            if (httpResponse.statusCode==401) {
                print("getMinistatement: No account linked")
                // Return MiniStatementResponse with balance = nil to force ui
                // to enable account linking button
                completion (nil)
                return
            }
            
            // Handle non-200 response
            if (!(httpResponse.statusCode==200)) {
                print("getMinistatement: Error, status code was: \(httpResponse.statusCode)")
                return
            }
                        
            // Decode body
            let decoder = JSONDecoder()
            guard let ms: MiniStatementResponse = try? decoder.decode(MiniStatementResponse.self, from: data!) else {
                fatalError("getMiniStatement: Could not parse response")
            }

            print("getMiniStatement: Returning \(ms.transactions.count) transactions")
            // Pass back response
            completion(ms)
        }
    }

    
    internal func revokeAccount(oid:String, completion:@escaping(Bool) -> Void) {
        print("revokeAccount:")

        let urlString =  String.init(format:"https://cl-ob-gw-dev.azurewebsites.net/api/revoke/\(oid)?code=o24MGQ5kCz3xb1OcK/oPqyX81CwLQAYJt7xPub7mxaWskUd/2AyRvg==")

        guard let url = URL(string: urlString)  else {
            fatalError("revokeAccount: URL could not be created")
        }

        network.callAPI(url: url, method: "GET", body: nil, useStoredToken: true, xApiKey: nil) { (data, response, err) in
            // Handle errors
            if (err != nil) {
                fatalError("revokeAccount: Error: \(err.debugDescription)")
            }
            guard let httpResponse:HTTPURLResponse = response else {
                 fatalError("revokeAccount: Response was nil")
                }

            // Handle non-200 response
            if (!(httpResponse.statusCode==200)) {
                print("revokeAccount: Error, status code was: \(httpResponse.statusCode)")
                completion(false)
            }


            // Pass back response
            print("revokeAccount: succeeded")
            completion(true)
        }
    }

}
