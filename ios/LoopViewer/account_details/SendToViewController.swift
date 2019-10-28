import UIKit
import CardScan

class SendToViewController: UIViewController, ScanDelegate, UITextFieldDelegate {
    func userDidScanCard(_ scanViewController: ScanViewController, creditCard: CreditCard) {
        
    }
    

    var amount: Double?
    
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var qrcodeButton: UIButton!
    @IBOutlet weak var toAddressField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let smsToAccountId = appDelegate.smsToAccountId {
            self.toAddressField.text = smsToAccountId
            appDelegate.smsToAccountId = nil
        }
        
        let currency = "self.account!.currency"
        let amount = self.amount!
        let amountString = "self.account!.format(double: amount)"
        self.amountLabel.text = "Send \(amountString) \(currency)"
        self.toAddressField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.toAddressField.becomeFirstResponder()
    }
    
    @IBAction func qrcodePress() {
        self.errorLabel.isHidden = true
        
        let scanViewController = ScanViewController.createViewController(withDelegate: self)!
        scanViewController.scanQrCode = true
        self.present(scanViewController, animated: true)
    }
    
    @IBAction func nextPress() {
        guard let to = self.toAddressField.text, to.count > 0 else {
            self.errorLabel.text = "Please enter or scan an address"
            self.errorLabel.isHidden = false
            return
        }
        
        let storyboard = UIStoryboard(name: "AccountDetails", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "confirmSend") as! ConfirmSendViewController
        vc.amount = self.amount
        vc.to = to
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func userDidCancel(_ scanViewController: ScanViewController) {
        self.dismiss(animated: true)
    }
    
    func userDidSkip(_ scanViewController: ScanViewController) {
        self.dismiss(animated: true)
    }
    
    func userDidScanQrCode(_ scanViewController: ScanViewController, payload: String) {
        let toAddress = payload.starts(with: "ethereum:") ? String(payload.dropFirst(9)) : payload
        self.toAddressField.text = toAddress
        self.dismiss(animated: true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.errorLabel.isHidden = true
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.nextPress()
        return false
    }
}
