import UIKit

class AccountsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
        
    @IBOutlet weak var ethBalance: UILabel!
    @IBOutlet weak var totalBalance: UILabel!
    @IBOutlet weak var tableView: UITableView!
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "account") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "account")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func identityPress(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "identity") as! IdentityViewController

        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func updateUi() {
        
        let total = 0.00
        self.totalBalance.text = String(format: "$%0.02f", total)
        self.ethBalance.text = String(format: "%0.0f", total)
        self.tableView.reloadData()
    }
            
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.updateUi()
    }
}
