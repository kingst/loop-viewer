import UIKit

class SetupLoopViewController: UIViewController {

    @IBOutlet weak var apiSecretLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let user = User.currentUser else {
            preconditionFailure("No current user")
        }
        
        apiSecretLabel.text = user.apiSecret
    }
    @IBAction func linkPress() {
        User.currentUser?.refresh { newUser, error in
            guard let newUser = newUser else {
                self.errorLabel.isEnabled = true
                self.errorLabel.text = error?.message
                return
            }
            
            if newUser.loopDevice == nil {
                self.errorLabel.isEnabled = true
                self.errorLabel.text = "Loop device not connected yet"
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func existingDevicePress() {
        preconditionFailure()
    }
}
