import Foundation

struct LoopDevice {
    let startDate: Date
    let predictedValues: [Int]
    let carbsOnBoard: Double
    let insulinOnBoard: Double
    
    /**
     By the time we get here we should have a valid loop_device object, crash the app if we don't
     */
    init(_ params: [String: Any]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.startDate = dateFormatter.date(from:params["created_at"] as! String)!
        
        let loop = params["loop"] as! [String: Any]
        self.predictedValues = (loop["predicted"] as! [String: Any])["values"] as! [Int]
        let cobObject = (loop["cob"] as? [String: Any]) ?? ["cob": 0.0]
        self.carbsOnBoard = (cobObject["cob"] as? Double) ?? 0.0
        let iobObject = (loop["iob"] as? [String: Any]) ?? ["iob": 0.0]
        self.insulinOnBoard = (iobObject["iob"] as? Double) ?? 0.0
    }
    
    // MARK: Convenience methods for display
    func currentBG() -> String {
        return self.predictedValues.first.map { "\($0)" } ?? "???"
    }
    
    func predictedBG() -> String {
        return self.predictedValues.last.map { "\($0)" } ?? "0"
    }
    
    func cob() -> String {
        return String(format: "%0.01f", self.carbsOnBoard)
    }
    
    func iob() -> String {
        return String(format: "%0.01f", self.insulinOnBoard)
    }
    
    func lastUpdate() -> String {
        let interval = Int(-self.startDate.timeIntervalSinceNow / 60.0)
        return interval > 0 ? "Last update: \(interval)m" : "Last update: <1m"
    }
}

