//
//  Network.swift
//  trc-ios
//
//  Created by N Lennox on 2020/01/2.
//  Copyright © 2020 Level-Up Consulting Ltd. All rights reserved.
//

import Foundation

class Network {
    
    var utils = Utils()
    
    func callAPI(url:URL, method:String, body: Data?, useStoredToken: Bool, xApiKey:String?, completion:@escaping(Data?, HTTPURLResponse?, Error?) -> Void) {
        

            // Set up request
            var request = URLRequest(url: url)
            request.httpMethod=method
            request.setValue("application/json", forHTTPHeaderField:"Content-Type")
            request.timeoutInterval = 60
            
            // Set request body, if specified
            request.httpBody = body ?? nil
            
            //TODO: storedTokens call below is async and execution continues to xAPIKey, then returns here?
            // Definitely a race condition as request continues without auth header if you put a breakpoint on the debug print line below
        
            // Use stored token as auth header, if specified
            if (useStoredToken) {
                let idToken = utils.storedTokens()!.idToken
                print("Bearer \(idToken)")
                request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            }
            
            // If x-api-key is passed, add header
            if ((xApiKey) != nil) {
                request.setValue(xApiKey, forHTTPHeaderField: "x-api-key")
            }
            

            // Set up session
            let session=URLSession(configuration: .default)
            session.configuration.waitsForConnectivity = true
                
            // Set up dataTask
            let task=session.dataTask(with: request) { (data: Data?, response:URLResponse?, err:Error?) in

                guard let httpResponse:HTTPURLResponse = response as? HTTPURLResponse else {
                    print ("response was nil")
                    completion(data, nil, err)
                    
                    return  //TODO: return is to keep the compiler happy...
                }

                completion(data, httpResponse, err)

            }
            
            // Start dataTask
            task.resume()

        
    }
}
