import UIKit
import libPhoneNumber_iOS
import FlagKit

class EnterPhoneNumberViewController: UIViewController, UITextFieldDelegate, UpdateCountry {
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var numberField: UITextField!
    @IBOutlet weak var prefixWidth: NSLayoutConstraint!
    @IBOutlet weak var flagButton: UIButton!
    @IBOutlet weak var numberPrefixLabel: UILabel!
    
    var phoneNumberPrefix = "+1"
    var currentCountryCode: String?
    var asYouTypeFormatter: NBAsYouTypeFormatter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // should delete it for all of the view controllers in this flow
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        let countryCode = Locale.current.regionCode ?? "US"
        self.updateCountryCode(countryCode: countryCode)
        self.errorLabel.isHidden = true
        
        self.numberField.delegate = self
        self.numberField.becomeFirstResponder()
    }
    @IBAction func nextPress() {
        self.errorLabel.isHidden = true
        let phoneNumber = self.phoneNumberPrefix + (self.numberField.text?.filter { $0 >= "0" && $0 <= "9" } ?? "")
        
        if phoneNumber == self.phoneNumberPrefix {
            self.errorLabel.text = "Enter your number"
            self.errorLabel.isHidden = false
            return
        }
        
        self.activityIndicator.isHidden = false
        self.nextButton.setTitle("", for: .normal)
        self.nextButton.isEnabled = false
        //added by jaime
//        Api.OHGOD(){ response, error in
//            
//        }
//        
        Api.sendVerificationCode(phoneNumber: phoneNumber) { response, error in
            self.activityIndicator.isHidden = true
            self.nextButton.setTitle("Next", for: .normal)
            self.nextButton.isEnabled = true
            
            guard let response = response, error == nil else {
                self.errorLabel.isHidden = false
                self.errorLabel.text = error?.message
                return
            }
            
            guard let e164PhoneNumber = response["e164_phone_number"] as! String? else {
                return
            }
            
            let storyboard = UIStoryboard(name: "PhoneVerification", bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: "verifyCode") as! VerifyCodeViewController
            viewController.e164PhoneNumber = e164PhoneNumber
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    @IBAction func flagPress() {
        let storyboard = UIStoryboard(name: "PhoneVerification", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "pickCountry") as! PickCountryViewController
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func update(newCountryCode: String?) {
        self.dismiss(animated: true)
        guard let countryCode = newCountryCode else {
            // user cancelled
            return
        }
        self.updateCountryCode(countryCode: countryCode)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.activityIndicator.isHidden = true
        if !self.numberField.isFirstResponder {
            self.numberField.becomeFirstResponder()
        }
    }
    
    func updateCountryCode(countryCode: String) {
        let flagOpt = Flag(countryCode: countryCode)
        let countryPrefixOpt = NBPhoneNumberUtil.sharedInstance().getCountryCode(forRegion: countryCode)
        
        guard let flag = flagOpt, let countryPrefix = countryPrefixOpt else {
            // XXX FIXME log something so we know there was an error
            return
        }
        self.currentCountryCode = countryCode
        
        self.flagButton.setImage(flag.originalImage, for: .normal)
        self.phoneNumberPrefix = "+\(countryPrefix)"
        self.numberPrefixLabel.text = self.phoneNumberPrefix
        
        let size: CGSize = self.phoneNumberPrefix.size(withAttributes: [NSAttributedString.Key.font: self.numberPrefixLabel.font])
        
        self.prefixWidth.constant = size.width + 8.0
        self.numberPrefixLabel.layoutIfNeeded()
        
        let numberText = self.numberField.text?.filter { $0 >= "0" && $0 <= "9" } ?? ""
        let phoneUtil = NBPhoneNumberUtil.sharedInstance() ?? NBPhoneNumberUtil()
        let parsedNumber = try? phoneUtil.parse(numberText, defaultRegion: self.currentCountryCode ?? "US")
        guard let number = parsedNumber else {
            return
        }
        guard let formattedNumber = try? phoneUtil.format(number, numberFormat: .NATIONAL) else {
            return
        }
        self.numberField.text = formattedNumber
        self.asYouTypeFormatter = nil
    }
    
    func useAsYouType(range: NSRange, string: String) -> Bool {
        let count = self.numberField.text?.count ?? 0
        
        // check if we're appending a single digit
        if string.count == 1 && range.location == count && range.length == 0 {
            // the system an put in some strange chars when using the
            // autocorrect suggestions or copy and paste, just let those
            // through and only handle single digits
            if string < "0" || string > "9" {
                return false
            }
            // this is an append
            if count == 0 {
                self.asYouTypeFormatter = NBAsYouTypeFormatter(regionCode: self.currentCountryCode ?? "US")
            }
          
            guard let asYouType = self.asYouTypeFormatter else {
                return false
            }
            
            self.numberField.text = asYouType.inputDigit(string)
            return true
        }
        
        // check if we're deleting a single digit from the end
        if range.location == (count - 1) && range.length == 1 && string.count == 0 {
            guard let asYouType = self.asYouTypeFormatter else {
                return false
            }
            
            self.numberField.text = asYouType.removeLastDigit()
            return true
        }
        
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.errorLabel.isHidden = true
        
        if self.useAsYouType(range: range, string: string) {
            return false
        }
        
        // it's important to clear the asYouTypeFormatter here because if we get
        // here we know that the text field is going to become inconsistent with
        // the asYouTypeFormatter
        self.asYouTypeFormatter = nil
        
        let nsString = textField.text as NSString?
        guard let newString = nsString?.replacingCharacters(in: range, with: string) else {
            return true
        }
        let phoneUtil = NBPhoneNumberUtil.sharedInstance() ?? NBPhoneNumberUtil()
        let parsedNumber = try? phoneUtil.parse(newString, defaultRegion: self.currentCountryCode ?? "US")
        
        guard let number = parsedNumber else {
            return true
        }
        
        if let regionCode = phoneUtil.getRegionCode(for: number) {
            if regionCode != self.currentCountryCode {
                self.updateCountryCode(countryCode: regionCode)
            }
        }
        
        guard let formattedNumber = try? phoneUtil.format(number, numberFormat: .NATIONAL) else {
            return true
        }
        textField.text = formattedNumber
        
        if phoneUtil.isValidNumber(number) && string.count > 1 {
            DispatchQueue.main.async {
                self.nextPress()
            }
        }
        
        return false
    }
}
