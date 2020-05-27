//
//  utils.swift
//  ob-gw-ios-spike
//
//  Created by N Lennox on 2019/02/21.
//  Copyright © 2019 Level-Up Consulting Ltd. All rights reserved.
//

import UIKit
import KeychainSwift

public class Utils: NSObject {
    
    let defaults = UserDefaults()
    
    
    // Ref: https://stackoverflow.com/questions/40915607/how-can-i-decode-jwt-json-web-token-token-in-swift
    public func decodeJWT(jwtToken jwt: String) -> [String: Any] {
        let segments = jwt.components(separatedBy: ".")
        return decodeJWTPart(segments[1]) ?? [:]
    }
    
    func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 = base64 + padding
        }
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }
    
    func decodeJWTPart(_ value: String) -> [String: Any]? {
        guard let bodyData = base64UrlDecode(value),
            let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
                return nil
        }
        
        return payload
    }
    
    // Get tokens from persistent storage
    public func storedTokens() -> Tokens? {
        let keychain = KeychainSwift()
        // Get tokens from user defaults, return nil if any do not exist
        guard let token:String = keychain.get("B2CIdToken") else {
            print("utils: storedTokens: No tokens available in user defaults")
            return nil
        }
        guard let refresh:String = keychain.get("B2CRefreshToken") else {
            print("utils: storedTokens: No tokens available in user defaults")
            return nil
        }
        guard let expiry:Int = Int(keychain.get("B2CExpiry")!) else {
            print("utils: storedTokens: No tokens available in user defaults")
            return nil
        }
        
        // Put back in object
        let restoredTokens=Tokens()
        restoredTokens.idToken = token
        restoredTokens.refreshToken = refresh
        restoredTokens.expiryTime = expiry
        
        print("utils: storedTokens: Returning stored tokens")
        return restoredTokens
    }
    
    // Store tokens to persistent storage, overwriting any existing values
    public func storeTokens(tokens:Tokens) {
        print ("utils:storeTokens: Storing tokens")
        let keychain = KeychainSwift()
        keychain.set(tokens.idToken, forKey:"B2CIdToken")
        keychain.set(tokens.refreshToken, forKey:"B2CRefreshToken")
        keychain.set(String(tokens.expiryTime), forKey:"B2CExpiry")
        return
    }
    
    // Delete stored tokens from defaults
    public func deleteStoredTokens() {
        print("utils:deleteStoredTokens: Deleting all stored tokens for user")
        let keychain = KeychainSwift()
        keychain.delete("B2CIdToken")
        keychain.delete("B2CRefreshToken")
        keychain.delete("B2CExpiry")
        return
    }
    
    public func getApiBaseUrl() -> String {
        let debugFlag = defaults.bool(forKey: "inLocalDebugMode")
        print("inLocalDebugMode: \(debugFlag.description)")
        return (debugFlag ? "http://10.0.1.196:7071/api": "https://cloudlevel-io.azure-api.net/trc-ob-gw-test")
    }

}
