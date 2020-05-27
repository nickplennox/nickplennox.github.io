//
//  LoginViewController.swift
//  trc-ios
//  v3.0.0
//
//  Created by N Lennox on 2019/02/12.
//  Copyright © 2019 Level-Up Consulting Ltd. All rights reserved.
//
//  Primary reference: https://docs.microsoft.com/en-gb/azure/active-directory-b2c/active-directory-b2c-reference-oauth-code

import UIKit
import WebKit
import LocalAuthentication

class LoginViewController: UIViewController, WKNavigationDelegate {

    @IBOutlet weak var wv: WKWebView!
    
    let tenantId = "obgw"
    let signinPolicy = "B2C_1A_signup_signin"
    let clientId = "98423c0b-6684-4c13-a740-b1a9a346614d"
    let mobileUrn = "urn:ietf:wg:oauth:2.0:oob"
    let state = "here_is_some_state"    // TODO: remove static text, should we be generating a value and validating later?
    let nextVC = "Main"
    
    var tokens = Tokens()
    var utils = Utils()
    

    
 
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Get stored token, run B2C login if no stored token
        guard let tokens = utils.storedTokens() else {
            print("LoginViewController: viewDidAppear: No stored tokens, running login flow")
            runLoginFlow()
            return
        }
        
        // Show biometric prompt if enabled
        let biometricsEnabled = UserDefaults.standard.bool(forKey: "use_biometrics")
        if (biometricsEnabled) {
            print("Using biometric unlock")
            
            // Show biometric prompt
            let context = LAContext()
            context.localizedCancelTitle = "Enter Username/Password"
            let reason = "Unlock the app"
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ) { success, error in

                if success {
                    let timestamp = Int(NSDate().timeIntervalSince1970)
                    print("LoginViewController: viewDidAppear: Current epoch time = \(timestamp)")
                    
                    // Refresh tokens if expired
                    let delta = tokens.expiryTime - timestamp
                    print("LoginViewController: viewDidAppear: Remaining token lifetime = \(delta) seconds")
                    if delta < 300 {
                        // Token has expired, refresh required
                        print("LoginViewController: viewDidAppear: Current token has expired, trying to refresh")

                        self.refreshB2CTokenWith(refreshToken: tokens.refreshToken) { (newTokens) in
                            // Refresh was successful
                            print("LoginViewController: viewDidAppear: Refresh successful, storing new tokens")
                            self.utils.storeTokens(tokens: newTokens)
                            DispatchQueue.main.async {
                             self.performSegue(withIdentifier: self.nextVC, sender: self)
                            }
                        }
                    }
                    else {
                        // Segue to Dashboard
                        print("LoginViewController: viewDidAppear: Segue to Main View Controller")
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: self.nextVC, sender: self)
                        }
                    }
                    
                } else {
                    print(error?.localizedDescription ?? "LoginViewController: viewDidAppear: Failed to authenticate")
                    // Fall back to B2C login
                    self.runLoginFlow()
                    return
                }
                
            }
            
        }
        else {
            // If biometrics not enabled, use B2C login
            print("LoginViewController: viewDidAppear: Biometric unlock is disabled, using B2C login")
            runLoginFlow()
            return
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("LoginViewController: webView:didFinish:")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("LoginViewController: webView:didFail:")
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("LoginViewController: webView:didReceiveServerRedirectForProvisionalNavigation:")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("LoginViewController: webView:didFailProvisionalNavigation:withError") // Expected! This is where the access code is returned in the query string
        
        // Convert big messy string from error into a dictionary of properties and values
        let queryItems=getQueryItemsDictionary(err: error)
        
        // There must be a state returned
        guard queryItems["state"] != nil else {
            fatalError("LoginViewController: webView:didFailProvisionalNavigation:withError: No state returned")
        }
        
        // There must be a code returned
        guard let code=queryItems["code"] else {
            fatalError("LoginViewController: webView:didFailProvisionalNavigation:withError: No code returned")
        }
    
        // Exchange code for tokens
        print ("LoginViewController: webView:didFailProvisionalNavigation:withError: Exchanging code for tokens")
        exchangeCodeForTokens(code: code) { (idToken, refreshToken, expiryTime) in

            // Store tokens for passing on in segue
            self.tokens.idToken = idToken
            self.tokens.refreshToken = refreshToken
            self.tokens.expiryTime = expiryTime
            
            // Persist tokens for next run
            self.utils.storeTokens(tokens: self.tokens)
            
            // Segue to Main View Controller
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: self.nextVC, sender: self)
            }
        }
        
    }
    
    
    func exchangeCodeForTokens(code:String, completion:@escaping(String,String,Int)->Void){
        print("LoginViewController: exchangeCodeForTokens:")
        
        // Set up request
        let exchangeCodeUrl = URL(string: String.init(format: "https://\(tenantId).b2clogin.com/\(tenantId).onmicrosoft.com/oauth2/v2.0/token?p=\(signinPolicy)"))
        var exchangeCodeRequest = URLRequest(url: exchangeCodeUrl!)
        exchangeCodeRequest.httpMethod="POST"
        exchangeCodeRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        
        // Set up request body
        let requestBody:String=String.init(format:"grant_type=authorization_code&client_id=\(clientId)&scope=\(clientId) offline_access&code=\(code)&redirect_uri=\(mobileUrn)")
        exchangeCodeRequest.httpBody=Data(requestBody.utf8)
        
        // Set up session
        let session=URLSession(configuration: .default)
        session.configuration.waitsForConnectivity = true
        let task=session.dataTask(with: exchangeCodeRequest) { (data: Data?, response:URLResponse?, err:Error?) in
            do {
                guard let json:Dictionary<String, Any> = try (JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]) else {
                    fatalError("LoginViewController: exchangeCodeForTokens: Could not parse JSON")
                }
                
                // Get required properties from JSON
                let idToken:String = json["id_token"] as! String
                let refreshToken:String = json["refresh_token"] as! String
                let expiry:Int = json["expires_on"] as! Int
                
                // Persist tokens for streamlined login next time
                let newTokens = Tokens()
                newTokens.idToken = idToken
                newTokens.refreshToken = refreshToken
                newTokens.expiryTime = expiry
                print("LoginViewController: exchangeCodeForTokens: Code exchange successful, storing tokens")
                self.utils.storeTokens(tokens: newTokens)
                self.tokens = newTokens

                // Return
                completion(idToken, refreshToken, expiry)
                
            } catch let jsonError {
                print(jsonError)
                fatalError("LoginViewController: exchangeCodeForTokens: Could not decode JSON")
            }
        }
        
        // Start the session
        task.resume()
    }


    // Get new set of tokens, using refresh token
    func refreshB2CTokenWith(refreshToken:String, completion:@escaping(Tokens)->Void){
        
        // Set up request
        let refreshTokenUrl = URL(string: String.init(format: "https://\(tenantId).b2clogin.com/\(tenantId).onmicrosoft.com/oauth2/v2.0/token?p=\(signinPolicy)"))
        var refreshTokenRequest = URLRequest(url: refreshTokenUrl!)
        refreshTokenRequest.httpMethod="POST"
        refreshTokenRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        
        // Set up request body
        let requestBody:String=String.init(format:"grant_type=refresh_token&client_id=\(clientId)&scope=\(clientId) offline_access&refresh_token=\(refreshToken)&redirect_uri=\(mobileUrn)")
        refreshTokenRequest.httpBody=Data(requestBody.utf8)
        
        // Set up session
        let session=URLSession(configuration: .default)
        session.configuration.waitsForConnectivity = true
        let task=session.dataTask(with: refreshTokenRequest) { (data: Data?, response:URLResponse?, err:Error?) in
            do {
                guard let json:Dictionary<String, Any> = try (JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]) else {
                    fatalError("LoginViewController: refreshB2CTokenWith: Could not parse JSON")
                }
                
                // Get required properties from JSON
                let idToken:String = json["access_token"] as! String
                let refreshToken:String = json["refresh_token"] as! String
                let expires_in:Int = json["expires_in"] as! Int
                
                let newTokens=Tokens()
                newTokens.idToken = idToken
                newTokens.refreshToken = refreshToken
                newTokens.expiryTime = Int(NSDate().timeIntervalSince1970) + expires_in - 10     // Reduce lifetime by 10sec to allow safe margin
                
                completion(newTokens)
                
            } catch let jsonError {
                print(jsonError)
                fatalError("LoginViewController: refreshB2CTokenWith: Could not decode JSON")
            }
        }
        
        // Start the session
        task.resume()
        
    }
    
    // Load B2C login page in web view
    fileprivate func runLoginFlow() {
        
        DispatchQueue.main.async {

            self.view.layoutSubviews()

            // Set WKNavigationDelegate
            self.wv.navigationDelegate=self
            
            // Configure URLSession
            let config=URLSessionConfiguration.default
            config.waitsForConnectivity=true
            
            // Create login page URL
            let accountAuthUrlString = String.init(format: "https://\(self.tenantId).b2clogin.com/\(self.tenantId).onmicrosoft.com/oauth2/v2.0/authorize?client_id=\(self.clientId)&response_type=code&redirect_uri=\(self.mobileUrn)&response_mode=query&scope=\(self.clientId) offline_access&state=\(self.state)&p=\(self.signinPolicy)")
            let encodedURL=accountAuthUrlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let accountAuthUrl = URL(string: encodedURL!)
            
            // Create URL request and load the login page
            let accountAuthRequest = URLRequest(url: accountAuthUrl!)
            self.wv.load(accountAuthRequest)
        }
    }
    
    fileprivate func getQueryItemsDictionary(err: Error) -> Dictionary<String, String> {
        // Grab big messy string from error
        guard let URLStringKey:ErrorUserInfoKey=err._userInfo!["NSErrorFailingURLStringKey"] as? ErrorUserInfoKey else {
            fatalError("LoginViewController: webView:didFailProvisionalNavigation:withError: No _userInfo key returned")
        }
        
        // Separate urn from query string fragments
        let pathComponents:[String]=URLStringKey.rawValue.components(separatedBy: "?")
        
        // Should be 2 components
        if pathComponents.count != 2 {
            fatalError("LoginViewController: webView:didFailProvisionalNavigation:withError: Could not parse path components")
        }
        
        // Assign components for later use
        let queryString=pathComponents[1]
        
        // Separate out query string components
        let resultComponents:[String]=queryString.components(separatedBy: "&")
        
        // Should be non-zero count of components
        if resultComponents.count == 0 {
            fatalError("LoginViewController: webView:didFailProvisionalNavigation:withError: Could not parse query components")
        }
        
        // Convert array of query components to dictionary for ease of use
        return dictionaryFromQueryItems(queryString: resultComponents)
    }
    
    fileprivate func dictionaryFromQueryItems(queryString:[String]) -> [String: String]{
        var result: [String: String] = [:]
        
        for element in queryString {
            let elements=element.components(separatedBy: "=")
            result.updateValue(elements[1], forKey: elements[0])
        }
        return result
    }
    
}
