import UIKit

class SetupLoopViewController: UIViewController {

    @IBOutlet weak var apiSecretLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var linkButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let user = User.currentUser else {
            preconditionFailure("No current user")
        }
        
        apiSecretLabel.text = user.apiSecret
    }
    
    @IBAction func linkPress() {
        let currentTitle = self.linkButton.title(for: .normal) ?? "Link"
        self.linkButton.setTitle("", for: .normal)
        self.activityIndicator.isHidden = false
        self.errorLabel.isHidden = true
        User.currentUser?.refresh { newUser, error in
            self.linkButton.setTitle(currentTitle, for: .normal)
            self.activityIndicator.isHidden = true
            
            guard let newUser = newUser else {
                self.errorLabel.isHidden = false
                self.errorLabel.text = error?.message
                return
            }
            
            if newUser.loopDevice == nil {
                self.errorLabel.isHidden = false
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
