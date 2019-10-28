import UIKit

struct Onboarding {
    static func next() -> UIViewController? {
        // we should crash if we call this without a user
        let user = User.currentUser!
        
        switch (user.name, user.email) {
        case (nil, _):
            let storyboard = UIStoryboard(name: "PhoneVerification", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "enterName")
            return vc
        case (_, nil):
            let storyboard = UIStoryboard(name: "PhoneVerification", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "enterEmail")
            return vc
        default:
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.setHomeViewController()
            return nil
        }
    }
}
