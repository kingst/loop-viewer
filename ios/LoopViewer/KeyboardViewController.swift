import UIKit

class KeyboardViewController: UIViewController {

    var keyboardHeightConstraint: NSLayoutConstraint?
    static var isKeyboardVisible: Bool = false
    static var visibleKeyboardHeight: CGFloat = 0.0
    
    override func viewDidLoad() {
        assert(false, "you need to pass in constraints to the viewDidLoad method")
    }
    
    func viewDidLoad(heightConstraint: NSLayoutConstraint) {
        super.viewDidLoad()

        self.keyboardHeightConstraint = heightConstraint
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardDidShow(notification:)),
                                               name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardDidHide(notification:)),
                                               name: UIResponder.keyboardDidHideNotification, object: nil)
        if KeyboardViewController.isKeyboardVisible {
            self.resize(to: KeyboardViewController.visibleKeyboardHeight)
        }
    }
    
    func setErrorLabel(label: UILabel, message: String, button: UIButton?) {
        label.textColor = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
        label.text = message
        label.isHidden = false
        button?.isEnabled = false
    }
    
    func clearErrorLabel(label: UILabel, button: UIButton?) {
        label.isHidden = true
        button?.isEnabled = true
    }
    
    @objc func keyboardDidShow(notification: NSNotification) {
        KeyboardViewController.isKeyboardVisible = true
        let info = notification.userInfo!
        let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        KeyboardViewController.visibleKeyboardHeight = keyboardSize
        self.resize(to: keyboardSize)
    }

    @objc func keyboardDidHide(notification: NSNotification) {
        KeyboardViewController.isKeyboardVisible = false
    }

    func resize(to newHeight: CGFloat) {
        guard let heightConstraint = self.keyboardHeightConstraint else {
            return
        }
        
        if newHeight > heightConstraint.constant {
            heightConstraint.constant = newHeight
        }
    }
}
