import UIKit
import FlagKit

protocol UpdateCountry {
    func update(newCountryCode: String?)
}

class PickCountryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let allCountryCodes = ["AU", "CA", "CL", "CN", "ES", "FR", "GB", "GT", "IL", "IN", "JP", "MX", "US"]
    
    var currentCountryCode: String?
    var delegate: UpdateCountry?
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.allCountryCodes.count
    }
    @IBAction func cancel() {
        self.delegate?.update(newCountryCode: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableIdentifier = "ImageAndTextItem"
        let cell = tableView.dequeueReusableCell(withIdentifier: tableIdentifier) ??
            UITableViewCell(style: .default, reuseIdentifier: tableIdentifier)
        let code = self.allCountryCodes[indexPath.row]
        let countryName = (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.countryCode, value: code) ??
            (Locale(identifier: "en_US") as NSLocale).displayName(forKey: NSLocale.Key.countryCode, value: code) ?? "Unknown"
        cell.textLabel?.text = countryName
        cell.imageView?.image = Flag(countryCode: code)?.originalImage
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let countryCode = self.allCountryCodes[indexPath.row]
        self.delegate?.update(newCountryCode: countryCode)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}
