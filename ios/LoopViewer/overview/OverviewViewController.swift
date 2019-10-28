import UIKit

class OverviewViewController: UIViewController {
    @IBOutlet weak var lastReadingLabel: UILabel!
    @IBOutlet weak var currentGlucoseLabel: UILabel!
    @IBOutlet weak var predictedLabel: UILabel!
    @IBOutlet weak var carbsOnBoardLabel: UILabel!
    @IBOutlet weak var insulinOnBoardLabel: UILabel!
    
    @IBAction func identityPress(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "identity") as! IdentityViewController

        self.navigationController?.pushViewController(vc, animated: true)
    }
            
    @IBAction func devicePress(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "setupLoop")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func setupUi() {
        guard let user = User.currentUser else {
            print("Not logged in")
            return
        }
        
        guard let loopDevice = user.loopDevice else {
            self.lastReadingLabel.text = "No device linked"
            self.currentGlucoseLabel.text = "N/A"
            self.predictedLabel.text = "0"
            self.carbsOnBoardLabel.text = "0"
            self.insulinOnBoardLabel.text = "0"
            
            let storyboard = UIStoryboard(name: "Device", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "setupLoop")
            self.navigationController?.pushViewController(vc, animated: false)
            
            return
        }
        
        if loopDevice.hasDeviceStatus {
            self.lastReadingLabel.text = loopDevice.lastUpdate()
        } else {
            self.lastReadingLabel.text = "Connected, waiting for first reading"
        }
        self.currentGlucoseLabel.text = loopDevice.currentBG()
        self.predictedLabel.text = loopDevice.predictedBG()
        self.carbsOnBoardLabel.text = loopDevice.cob()
        self.insulinOnBoardLabel.text = loopDevice.iob()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.shadowImage = UIImage()
        setupUi()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupUi()
    }
}
