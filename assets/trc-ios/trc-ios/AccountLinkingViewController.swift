//
//  AccountLinkingViewController.swift
//  trc-ios
//
//  Created by N Lennox on 2019/12/3.
//  Copyright © 2019 Level-Up Consulting Ltd. All rights reserved.
//

import UIKit
import WebKit

class AccountLinkingViewController: UIViewController, WKNavigationDelegate  {
    
    var oid:String?=nil
    
    @IBOutlet var wv: WKWebView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get Account Linking Request Url
        let url = getAccountLinkingURLForOid(oid: oid!)
        
        // Navigate to Account Linking Request Url
        runAccountLinkingFlow(accountLinkingURL: url)

    }
    

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("webView: didFinish navigation")
        //print(webView.url ?? "no url")
        
        let lastPathComponent = webView.url?.pathComponents.last
        let host = webView.url?.host
        
        switch (host, lastPathComponent) {
        case ("obgwspike.azurewebsites.net","callback"):
            print ("Returned from account authorisation callback")
            performSegue(withIdentifier: "toMain2", sender: nil)
        case ("trc-ob-gw-test.azurewebsites.net","callback"):
            print ("Returned from account authorisation callback, going back to Dashboard VC")
            performSegue(withIdentifier: "unwindToDashboard", sender: nil)
        default:
            print("Finished navigation to \(host ?? "nil host")\(lastPathComponent ?? "nil lastPathComponent")")
        }
    }
    
    
    // Handle redirect to our server callback
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("webView: didReceiveServerRedirectForProvisionalNavigation: Redirected to \(webView.url?.host ?? "nil host")")
        
        /*
        if (webView.url?.host=="https://trc-ob-gw-test.azurewebsites.net" && webView.url?.path=="/api/callback") {
            print("received a callback with code:")
            print(webView.url?.query as Any)
            performSegue(withIdentifier: "UnwindToMain", sender: nil)
        }
        */
        
    }
    
    
     // Return an Account Linking URL for the provided B2C oid
     fileprivate func getAccountLinkingURLForOid(oid:String) -> URL {
            let urlString = "https://cl-ob-gw-dev.azurewebsites.net/api/login/\(oid)?code=R4QrnKtPbDl0yabDQ4NLUzsPyLG9N2bjA9pRU0pYqr0oxFCf3a8a6Q=="
            let encodedURL=urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            return URL(string: encodedURL)!
        }
        
    
    // Navigate WKWebView to the provided URL
    fileprivate func runAccountLinkingFlow(accountLinkingURL:URL) {
       
        DispatchQueue.main.async {
            
            // Set WKNavigationDelegate
            self.wv.navigationDelegate=self
            
            // Configure URLSession
            let config=URLSessionConfiguration.default
            config.waitsForConnectivity=true
            
            // Create URL request and load the login page
            let accountAuthRequest = URLRequest(url: accountLinkingURL)
            self.wv.load(accountAuthRequest)
        }
        
    }
    
    
}
