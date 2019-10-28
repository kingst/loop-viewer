import UIKit

class SendAmountViewController: UIViewController, UITextFieldDelegate {

    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var balanceAvailableLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.amountField.becomeFirstResponder()
    }
    
    @IBAction func nextPress() {
        guard let amountText = self.amountField.text, amountText.count != 0 else {
            self.errorLabel.text = "Please enter the amount"
            self.errorLabel.isHidden = false
            return
        }
        
        guard let amount = Double(amountText) else {
            self.errorLabel.text = "Could not understand the amount you entered"
            self.errorLabel.isHidden = false
            return
        }
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.errorLabel.isHidden = true
        return true
    }
}
