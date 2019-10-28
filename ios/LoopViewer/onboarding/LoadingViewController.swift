import UIKit

class LoadingViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Api.user() { response, error in
            guard let response = response, error == nil else {
                User.logout()
                let storyboard = UIStoryboard(name: "PhoneVerification", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "enterPhoneNumber")
                let navController = storyboard.instantiateViewController(withIdentifier: "onboardNavigationController") as! UINavigationController
                navController.viewControllers = [vc]
                navController.navigationBar.shadowImage = UIImage()
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                appDelegate?.window?.rootViewController = navController
                return
            }
            
            User.currentUser = User(response["user"] as! [String: Any])
        }
    }
}
