import UIKit

class AccountDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var transfers: [[String: String]] = [["title": "Created new account", "subtitle": " "]]
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var accountNameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.shadowImage = UIImage()
                
        self.accountNameLabel.text = "asdf"
        self.balanceLabel.text = "0.0"
    }
    
    @IBAction func cancelPress(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func sendPress(_ sender: Any) {
        self.errorLabel.isHidden = true
        let storyboard = UIStoryboard(name: "AccountDetails", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "sendAmount") as! SendAmountViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func receivePress(_ sender: Any) {
        self.errorLabel.isHidden = true
        let storyboard = UIStoryboard(name: "AccountDetails", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "receive") as! ReceiveViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.transfers.count
    }
    
    func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        return "Activity"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "accountActivity") ?? UITableViewCell(style: .default, reuseIdentifier: "accountActivity")
        
        cell.textLabel?.text = self.transfers[indexPath.row]["title"]
        cell.detailTextLabel?.text = self.transfers[indexPath.row]["subtitle"]
        
        return cell
    }
}
