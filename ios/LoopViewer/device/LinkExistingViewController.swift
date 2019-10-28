import UIKit

protocol LinkExistingProtocol {
    func userSavedNewApiSecret()
}

class LinkExistingViewController: UIViewController {
    var delegate: LinkExistingProtocol?
    @IBOutlet weak var apiSecretField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var linkButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.apiSecretField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.apiSecretField.resignFirstResponder()
    }
    
    @IBAction func linkPress() {
        guard let apiSecret = self.apiSecretField.text else {
            print("api secret not set")
            return
        }
        
        let currentTitle = self.linkButton.title(for: .normal) ?? "Link"
        self.linkButton.setTitle("", for: .normal)
        self.linkButton.isEnabled = false
        self.activityIndicator.isHidden = false
        self.errorLabel.isHidden = true
        User.currentUser?.updateApiSecret(apiSecret: apiSecret) { newUser, error in
            self.linkButton.isEnabled = true
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
                self.delegate?.userSavedNewApiSecret()
            }
        }
    }
    
}
