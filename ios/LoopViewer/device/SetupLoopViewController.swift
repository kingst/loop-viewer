import UIKit

class SetupLoopViewController: UIViewController, LinkExistingProtocol, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var apiSecretLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var linkButton: UIButton!
    
    var isViewVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.isViewVisible = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.isViewVisible = false
    }
    
    @IBAction func linkPress() {
        let currentTitle = self.linkButton.title(for: .normal) ?? "Link"
        self.linkButton.setTitle("", for: .normal)
        self.linkButton.isEnabled = false
        self.activityIndicator.isHidden = false
        self.errorLabel.isHidden = true
        User.currentUser?.refresh { newUser, error in
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
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func existingDevicePress() {
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "linkExisting") as! LinkExistingViewController
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func userSavedNewApiSecret() {
        self.navigationController?.popViewController(animated: true)
        self.navigationController?.popViewController(animated: false)
    }
    
    // MARK: TableView data source protocol
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settings") ?? UITableViewCell(style: .default, reuseIdentifier: "settings")
        
        cell.imageView?.image = nil
        cell.accessoryType = .none
        
        if indexPath.section == 0 {
            cell.textLabel?.text = "https://loop-viewer.appspot.com"
        } else {
            cell.textLabel?.text = User.currentUser?.apiSecret ?? "ERROR"
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Site URL"
        } else {
            return "API Secret"
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            UIPasteboard.general.string = "https://loop-viewer.appspot.com"
            self.errorLabel.text = "Site URL copied to clipboard"
        } else {
            UIPasteboard.general.string = User.currentUser?.apiSecret
            self.errorLabel.text = "API Secret copied to clipboard"
        }
        
        let textColor = self.errorLabel.textColor
        self.errorLabel.textColor = UIColor.black
        self.errorLabel.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.isViewVisible {
                self.errorLabel.textColor = textColor
                self.errorLabel.isHidden = true
            }
        }
    }
}
