import Foundation
import libPhoneNumber_iOS

struct User {
    var userId: String
    var e164PhoneNumber: String
    var name: String?
    var email: String?
    
    static var currentUser: User? = nil
    
    init(_ params: [String: Any]) {
        self.userId = params["user_id"] as! String
        self.e164PhoneNumber = params["e164_phone_number"] as! String
        self.name = params["name"] as? String
        self.email = params["email"] as? String
    }
    
    func formattedPhoneNumber() -> String {
        return User.formatted(e164PhoneNumber: self.e164PhoneNumber)
    }
    
    static func formatted(e164PhoneNumber: String) -> String {
        let phoneUtil = NBPhoneNumberUtil.sharedInstance() ?? NBPhoneNumberUtil()
        let parsedNumber = try? phoneUtil.parse(e164PhoneNumber, defaultRegion: "US")
        print("testing")
        let formattedNumber = try? phoneUtil.format(parsedNumber, numberFormat: .NATIONAL)
        return formattedNumber ?? e164PhoneNumber
    }
    
    static func logout() {
        // XXX FIXME we should fire and forget a logout api call
        Storage.authToken = nil
        //Storage.e164PhoneNumber = nil
        //Storage.clearNameDictionary()
        User.currentUser = nil
    }
}
