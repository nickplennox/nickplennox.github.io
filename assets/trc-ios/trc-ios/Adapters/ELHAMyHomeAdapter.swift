//
//  ELHAMyHomeAdapter.swift
//  trc-ios
//
//  Created by N Lennox on 2020/01/2.
//  Copyright © 2020 Level-Up Consulting Ltd. All rights reserved.
//

import Foundation

class ELHAMyHomeAdapter: MyHomeAdapter {
    
    
    let baseUri = "https://api.test.trc.housing-online.com/"
    let xApiKey = "hoi8LFFMt27SOsAxzJTwm20iXuy0Nzs66HgjOdjj"
    
    let network = Network()
    let utils = Utils()


    
    
    func getUid(email: String, completion:@escaping(String?) -> Void) {
        
        print("getUid:")

        // Create URL for api call
        let urlString = String.init(format: "\(baseUri)uid")
        guard let url = URL(string: urlString)  else {
            fatalError("MyHomeAdapter: URL could not be created")
        }
        
        // Create body data for api
        let uidRequestString:String=String.init(format:"{\"email\":\"\(email)\"}")
        let body = Data(uidRequestString.utf8)
        
        // Call API
        network.callAPI(url: url, method: "POST", body: body, useStoredToken: false, xApiKey: xApiKey) { (data, response, err) in

            // Handle errors
            if (err != nil) {
                fatalError("Error: \(err.debugDescription)")
            }
            guard let httpResponse:HTTPURLResponse = response else {
                 fatalError("response was nil")
                }

            // Handle non-200 response
            if (!(httpResponse.statusCode==200)) {
                print("Error, status code was: \(httpResponse.statusCode)")
                return
            }
                        
            // Decode body
            let decoder = JSONDecoder()
            guard let parsedJSON: UidResponse = try? decoder.decode(UidResponse.self, from: data!) else {
                fatalError("getUid: Could not parse response")
            }

            print("getUid: returning uid ending in \(parsedJSON.uid.suffix(5))")
            // Pass back response
            completion(parsedJSON.uid)
            
        }
                
    }
}
