//
//  ViewController.swift
//  WasteProductiOS
//
//  Created by dongkyoo on 31/07/2019.
//  Copyright © 2019 dongkyoo. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import GoogleSignIn

class ViewController: UIViewController {

    @IBOutlet weak var googleSignInButton: GIDSignInButton!
    @IBOutlet var signInWithEmailButton: UIButton!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var signOutButton: UIButton!
    var link: String!
    
    override func viewDidLoad() {
        GIDSignIn.sharedInstance()?.uiDelegate = self
        GIDSignIn.sharedInstance()?.signInSilently()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomActive), name: Notification.Name(rawValue: "applicationDidBecomeActive"), object: nil)
    }
    
    @objc
    func didBecomActive() {
        if let link = UserDefaults.standard.value(forKey: "Link") as? String {
            self.link = link
            signInWithEmailButton.isEnabled = true
            
            if let email = UserDefaults.standard.value(forKey: "Email") as? String {
                if !Auth.auth().isSignIn(withEmailLink: link) {
                    let credential = EmailAuthProvider.credential(withEmail: email, link: link)
                    Auth.auth().currentUser?.reauthenticate(with: credential, completion: { (user, error) in
                        if let error = error {
                            print("에러 = \(error.localizedDescription)")
                            return
                        }
                    })
                }
            }
        } else {
            signInWithEmailButton.isEnabled = false
        }
        
        if (Auth.auth().currentUser == nil) {
            signOutButton.isEnabled = false
        }
    }
    
    @IBAction func tabSignInWithEmail(_ sender: Any) {
        if let email = emailTextField.text {
            Auth.auth().signIn(withEmail: email, link: self.link) { (userInfo, error) in
                if let error = error {
                    print("에러 sigInWithEmail = \(error.localizedDescription)")
                    return
                }
                
                UserDefaults.standard.set("Email", forKey: "LoginType")
                self.signOutButton.isEnabled = true
            }
        }
    }
    
    @IBAction func tabButton(_ sender: Any) {
        if let email = emailTextField.text {
            let baseLink = "https://dongkyoo.page.link"
            let dynamicLink = "dongkyoo.page.link"
            let androidPackageName = "com.dongkyoo.wasteproduct"
            
            let actionCodeSettings = ActionCodeSettings()
            actionCodeSettings.url = URL(string: baseLink)
//            actionCodeSettings.dynamicLinkDomain = dynamicLink
            actionCodeSettings.handleCodeInApp = true
            actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
            actionCodeSettings.setAndroidPackageName(androidPackageName, installIfNotAvailable: false, minimumVersion: "12")
            
            Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings) {
                error in
                if let error = error {
                    print("에러 SignInLink : \(error.localizedDescription)")
                    return
                }

                UserDefaults.standard.set(email, forKey: "Email")
                print("이메일 확인해봐라")
            }
            
            print(Auth.auth().currentUser)
        }
    }
    
    @IBAction func tapSignOut(_ sender: Any) {
        if let loginType = UserDefaults.standard.value(forKey: "LoginType") as? String {
            switch loginType {
            case "Google":
                GIDSignIn.sharedInstance()?.signOut()
            case "Email":
                do {
                    try Auth.auth().signOut()
                    UserDefaults.standard.set(nil, forKey: "Email")
                    UserDefaults.standard.set(nil, forKey: "Link")
                    
                    signInWithEmailButton.isEnabled = false
                    signOutButton.isEnabled = false
                } catch let signOutError as NSError {
                    print("에러 signing out : \(signOutError.localizedDescription)")
                }
            default:
                return
            }
        }
    }
}

extension ViewController: GIDSignInUIDelegate {
    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
        UserDefaults.standard.set("Google", forKey: "LoginType")
    }
    
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        self.present(viewController, animated: true, completion: nil)
    }
}
