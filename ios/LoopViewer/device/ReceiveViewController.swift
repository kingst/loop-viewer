import UIKit

class ReceiveViewController: UIViewController {

    @IBOutlet weak var addressNameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var copyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let name = "foo"
        self.addressNameLabel.text = "\(name) address"
        self.addressLabel.text = "123-456-789-123-444"
        
        DispatchQueue.global(qos: .userInteractive).async {
            let data = "asdf".data(using: String.Encoding.ascii)
            let qrFilter = CIFilter(name: "CIQRCodeGenerator")!
            qrFilter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let ciImage = qrFilter.outputImage!.transformed(by: transform)
            DispatchQueue.main.async {
                self.imageView.image = UIImage(ciImage: ciImage)
            }
        }
    }
    
    @IBAction func copyPress() {
        UIPasteboard.general.string = "uhhh"
        self.copyButton.setTitle("✓", for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
