import UIKit
import CardScan

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var smsToAccountId: String?
    
    func setHomeViewController() {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let navController = storyboard.instantiateViewController(withIdentifier: "homeNav") as! UINavigationController
        let vc = storyboard.instantiateViewController(withIdentifier: "wallet")
        navController.viewControllers = [vc]
        self.window?.rootViewController = navController
        self.window?.makeKeyAndVisible()
    }
    
    func setProductionKeys() {
        guard let credsPath = Bundle.main.path(forResource: "creds", ofType: "json") else {
            print("could not find creds file")
            return
        }
        
        guard let credsData = FileManager.default.contents(atPath: credsPath) else {
            print("could not read the creds data")
            return
        }
        
        guard let jsonData = try? JSONSerialization.jsonObject(with: credsData) else {
            print("could not parse the json data")
            return
        }
        guard let _ = jsonData as? [String: Any] else {
            return
        }
    }

    @objc func storeDidChange() {
        print("storeDidChange")
    }
    
    func startICloud() {
        NotificationCenter.default.addObserver(self, selector: #selector(storeDidChange), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.startICloud()
        ScanViewController.configure()
        
        if Storage.authToken != nil {
            let storyboard = UIStoryboard(name: "PhoneVerification", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "loadingController")
            self.window?.rootViewController = vc
        }
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            guard let url = userActivity.webpageURL else {
                return true
            }
        
            var pathComponents = url.pathComponents
            self.smsToAccountId = pathComponents.removeLast()
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

