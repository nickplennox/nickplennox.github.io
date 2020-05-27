//
//  ViewController.swift
//  trc-ios
//
//  Created by N Lennox on 2019/11/14.
//  Copyright © 2019 Level-Up Consulting Ltd. All rights reserved.
//

import UIKit
import WebKit
import Firebase

class DashboardViewController: UIViewController, WKNavigationDelegate{
    
    //
    // Outlets
    
    @IBOutlet var GreetingName: UILabel!
    @IBOutlet var Oid: UILabel!
    @IBOutlet var Email: UILabel!
    @IBOutlet var Uid: UILabel!
    @IBOutlet var BankAccount: UILabel!
    @IBOutlet var ButtonRevoke: UIButton!
    @IBOutlet var ButtonConnect: UIButton!
    @IBOutlet weak var WebView: WKWebView!
    @IBOutlet var Biometrics: UILabel!
    

    //
    // Variables
    
    var oid:String?=nil
    
    // Update of balance forces UI update of Revoke and Connect buttons
    var balance:Double? {
        willSet(newValue){
            if ((newValue) == nil) {
                // A balance was not returned, so account is not linked
                DispatchQueue.main.async {
                    self.ButtonRevoke.isEnabled = false
                    self.ButtonConnect.isEnabled = true
                    self.BankAccount.text = "No bank account is connected"
                }
            }
            else {
                // A balance was returned, so account is linked
                DispatchQueue.main.async {
                    self.ButtonRevoke.isEnabled = true
                    self.ButtonConnect.isEnabled = false
                }
            }
        }
    }
    
    
    //
    // Config: Inject handlers for OBGW access and My Home Access
    var OBGW = CLOBGWAdapter()      // Use CLOBGW Adapter for OB Access
    var MH = ELHAMyHomeAdapter()    // Use ELHA Adapter for My Home Access
    var utils = Utils()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Store FCM instance ID token in DB for later use by notification service
        InstanceID.instanceID().instanceID { (result, error) in
          if let error = error {
            print("Error fetching remote instance ID: \(error)")
          } else if let result = result {
            print("Remote instance ID token: \(result.token)")
            //TODO: set a property in the model here
          }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If we are going to account linking, provide the oid
        if (segue.identifier == "toAccountLinking") {
            let dest = segue.destination as! AccountLinkingViewController
            dest.oid = self.oid
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        let j = utils.decodeJWT(jwtToken: utils.storedTokens()!.idToken)
        
        // Asynchronous UI update methods
        initialiseUI(j)
        updateUid(email: j["email"] as? String ?? "")
        updateAccountData()
    }
    
    
    // Set static ui properties
    fileprivate func initialiseUI(_ j: [String : Any]) {
        print("initialiseUI:")
        let fName:String=j["given_name"] as! String
        let sName:String=j["family_name"] as! String
        GreetingName.text="Hello, \(fName) \(sName)"
        Oid.text="Your oid: \(j["oid"] as? String ?? "")"
        Email.text="Your email: \(j["email"] as? String ?? "")"
        BankAccount.text="Getting bank account data"
        oid = j["oid"] as? String   //TODO: This ivar should represent the token as a struct instead of just the oid
        let biometricsEnabled = UserDefaults.standard.bool(forKey: "use_biometrics")
        Biometrics.text = "Biometric unlock is " + (biometricsEnabled ? "enabled" : "disabled")
    }
    
    
    // Call My Home Adapter uid endpoint and update ui
    fileprivate func updateUid(email: String) {
        print("updateUid:")
        MH.getUid(email: email, completion:{ (uid) in
            // Update UI
            DispatchQueue.main.async {
                self.Uid.text="MyHome uid: \(uid ?? "")"
                }
        })
    }
    
    
    // Call OBGW ministatement endpoint and update ui
    fileprivate func updateAccountData() {
        print("updateAccountData:")
        OBGW.getMiniStatement { (ms) in
            // Update UI
            if ms?.balance != nil {
                self.balance = ms?.balance!
                 DispatchQueue.main.async {
                    self.BankAccount.text="'\(ms!.accountName)' balance is £\(ms?.balance! ?? 0.0)"
                }
            }
            else {
                self.balance = nil  // Trigger Connect Bank Account logic in willSet balance
            }
        }
    }
    

    //
    // Actions
    
    // Revoke account action
    @IBAction func revokeAccountAccess(_ sender: Any) {
        print("revokeAccountAccess:")
        OBGW.revokeAccount(oid: oid!) { (success) in
            if (!success) {
                print("revokeAccountAccess: Account revocation failed")
                return
            }
            print("revokeAccountAccess: Account access was revoked")
            DispatchQueue.main.async {
                self.balance=nil    // trigger prop observer to update ui
                return
            }
        }
    }
    
    
    // Unwind target
    @IBAction func unwindToDashboard(_ unwindSegue: UIStoryboardSegue) {
        // Load bank account data
        updateAccountData()
    }
    
    
    // Connect Bank Account
    @IBAction func connectBankAccount(_ sender: Any) {} // No code, just triggers segue from button click
     
    
    // Logout action - delete stored tokens and reset ui
    @IBAction func logout(_ sender: Any) {
        utils.deleteStoredTokens()
        DispatchQueue.main.async {
            self.GreetingName.text="Hello, world"
            self.Oid.text="No oid available"
            self.Email.text="No email available"
            self.Uid.text="No uid available"
        }
    }
    
    
}

