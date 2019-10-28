import UIKit

class ConfirmSendViewController: UIViewController {

    var amount: Double?
    var to: String?
    
    @IBOutlet weak var sendAmountLabel: UILabel!
    @IBOutlet weak var minerFeeLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    @IBAction func sendPress(_ sender: Any) {
        

    }
}
