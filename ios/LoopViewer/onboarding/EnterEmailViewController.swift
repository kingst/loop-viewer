import UIKit

class EnterEmailViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emailField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.emailField.becomeFirstResponder()
    }
    
    
    @IBAction func nextPress() {
        self.errorLabel.isHidden = true
        
        guard let email = self.emailField.text else {
            self.errorLabel.text = "Enter your email address"
            self.errorLabel.isHidden = false
            return
        }
        
        self.activityIndicator.isHidden = false
        self.nextButton.setTitle("", for: .normal)
        self.nextButton.isEnabled = false
        Api.setEmail(email) { response, error in
            self.activityIndicator.isHidden = true
            self.nextButton.setTitle("Next", for: .normal)
            self.nextButton.isEnabled = true
            
            guard let response = response, error == nil else {
                self.errorLabel.isHidden = false
                self.errorLabel.text = error?.message
                return
            }
            
            guard let userResponse = response["user"] as? [String: Any] else {
                print("CRASH no user in response")
                return
            }
            
            guard let email = userResponse["email"] as? String else {
                print("CRASH no email in user object")
                return
            }
            
            User.currentUser?.email = email
            
            Onboarding.next().map { self.navigationController?.pushViewController($0, animated: true) }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.errorLabel.isHidden = true
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.nextPress()
        return true
    }
}
