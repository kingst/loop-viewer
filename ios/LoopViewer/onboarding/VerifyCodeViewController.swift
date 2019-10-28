import UIKit

class VerifyCodeViewController: UIViewController, UITextFieldDelegate {
    var e164PhoneNumber: String?
    let kNumDigitsInVerificationCode = 6
    
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var codeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let phoneNumber = self.e164PhoneNumber else {
            preconditionFailure()
        }
        
        self.phoneNumberLabel.text = User.formatted(e164PhoneNumber: phoneNumber)
        self.codeTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.codeTextField.becomeFirstResponder()
    }
    
    @IBAction func nextPress(_ sender: Any) {
        guard let code = self.codeTextField.text else {
            self.errorLabel.text = "Please enter the code we sent you via SMS"
            self.errorLabel.isHidden = false
            return
        }
        
        guard let phoneNumber = self.e164PhoneNumber else {
            preconditionFailure()
        }
        
        self.activityIndicator.isHidden = false
        self.nextButton.setTitle("", for: .normal)
        self.nextButton.isEnabled = false
        Api.verifyCode(e164PhoneNumber: phoneNumber, code: code) { response, error in
            self.nextButton.isEnabled = true
            self.activityIndicator.isHidden = true
            self.nextButton.setTitle("Next", for: .normal)
            
            guard let response = response, error == nil else {
                
                self.errorLabel.text = error?.message
                self.errorLabel.isHidden = false
                return
            }
            
            self.nextViewController(response: response)
            
            //if error -> make call
        }
    }
    
    func nextViewController(response: [String: Any]) {
        User.currentUser = User(response["user"] as! [String: Any])
        Storage.authToken = response["auth_token"] as? String
                    
        guard let viewController = Onboarding.next() else {
            // we've already onboarded this user, just bail
            return
        }
            
        self.navigationController?.pushViewController(viewController, animated: true)
        self.navigationController?.viewControllers = [viewController]
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.errorLabel.isHidden = true
        let nsString = textField.text as NSString?
        guard let newString = nsString?.replacingCharacters(in: range, with: string) else {
            return true
        }
        
        if newString.count == kNumDigitsInVerificationCode {
            DispatchQueue.main.async {
                textField.text = String(newString)
                self.nextPress("")
            }
            return false
        }
        
        return true
    }
}
