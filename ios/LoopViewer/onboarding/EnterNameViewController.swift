import UIKit

class EnterNameViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nameField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.nameField.becomeFirstResponder()
    }
    
    @IBAction func nextPress() {
        self.errorLabel.isHidden = true
        
        guard let name = self.nameField.text else {
            self.errorLabel.text = "Enter your name"
            self.errorLabel.isHidden = false
            return
        }
        
        self.activityIndicator.isHidden = false
        self.nextButton.setTitle("", for: .normal)
        self.nextButton.isEnabled = false
        Api.setName(name) { response, error in
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
            
            guard let name = userResponse["name"] as? String else {
                print("CRASH no name in user object")
                return
            }
            
            User.currentUser?.name = name
            
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
