import UIKit

class IdentityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    enum Section: Int {
        case identity = 0, paymentMethods, promo, logout,  unknown
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) ?? .unknown {
        case .identity:
            return 3
        case .paymentMethods:
            return 0
        case .promo:
            return 1
        case .logout:
            return 1
        default:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settings") ?? UITableViewCell(style: .default, reuseIdentifier: "settings")
        
        cell.imageView?.image = nil
        cell.accessoryType = .none
        
        switch (Section(rawValue: indexPath.section) ?? .unknown, indexPath.row) {
        case (.identity, 0):
            cell.textLabel?.text = User.currentUser?.name ?? "Anonymous"
        case (.identity, 1):
            cell.textLabel?.text = User.currentUser?.email ?? ""
        case (.identity, 2):
            cell.textLabel?.text = User.currentUser?.formattedPhoneNumber()
        case (.paymentMethods, 0):
            cell.textLabel?.text = "Add card"
            //let cardImage = STPImageLibrary.unknownCardCardImage()
            //cell.imageView?.image = cardImage
        case (.paymentMethods, _):
            cell.textLabel?.text = "Some Card"
            /*
            let paymentMethod = User.currentUser?.paymentMethods[indexPath.row]
            cell.textLabel?.text = paymentMethod!.brand + " " + paymentMethod!.last4
            let brand = STPCard.brand(from: paymentMethod!.brand)
            let cardImage = STPImageLibrary.brandImage(for: brand)
            cell.imageView?.image = cardImage
             */
        case (.promo, 0):
            cell.textLabel?.text = "Promo"
            cell.accessoryType = .disclosureIndicator
        case (.logout, 0):
            cell.textLabel?.text = "Logout"
            cell.accessoryType = .disclosureIndicator
        default:
            preconditionFailure()
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) ?? .unknown {
        case .identity:
            return "Personal info"
        case .paymentMethods:
            //return "Credit and debit cards"
            return nil
        default:
            return nil
        }
    }
    
    func logoutPrompt(cellRect: CGRect, cellView: UIView) {
        let destroyAction = UIAlertAction(title: "Logout", style: .destructive) { (action) in
            User.logout()
            let storyboard = UIStoryboard(name: "PhoneVerification", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "enterPhoneNumber")
            let navController = storyboard.instantiateViewController(withIdentifier: "onboardNavigationController") as! UINavigationController
            navController.viewControllers = [vc]
            navController.navigationBar.shadowImage = UIImage()
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            appDelegate?.window?.rootViewController = navController
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel) { (action) in
                                            // don't do anything
        }
        
        let alert = UIAlertController( title: "",
                                       message: "Logout of Loop Viewer?",
                                       preferredStyle: .actionSheet)
        alert.addAction(destroyAction)
        alert.addAction(cancelAction)
        
        // On iPad, action sheets must be presented from a popover.
        alert.popoverPresentationController?.sourceRect = cellRect
        alert.popoverPresentationController?.sourceView = cellView
        
        self.present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch (Section(rawValue: indexPath.section) ?? .unknown, indexPath.row) {
        case (.logout, 0):
            guard let cell = tableView.cellForRow(at: indexPath) else {
                print("could not fetch tableview cell for logout, ignore press")
                return
            }
            self.logoutPrompt(cellRect: cell.bounds, cellView: cell)
        case (.promo, 0):
            print("promo")
        case (.identity, 0):
            print("identity")
        case (.identity, 1):
            print("email")
        case (.identity, 2):
            print("phone")
        default:
            print("not implemented")
        }
    }
}
