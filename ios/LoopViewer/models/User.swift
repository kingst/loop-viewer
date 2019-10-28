import Foundation
import libPhoneNumber_iOS

struct User {
    let userId: String
    let e164PhoneNumber: String
    let apiSecret: String
    var name: String?
    var email: String?
    var loopDevice: LoopDevice?
    
    static var currentUser: User? = nil
    
    init(_ params: [String: Any]) {
        self.userId = params["user_id"] as! String
        self.e164PhoneNumber = params["e164_phone_number"] as! String
        self.apiSecret = params["loop_api_secret"] as! String
        self.name = params["name"] as? String
        self.email = params["email"] as? String
        let loopDeviceParams = params["loop_device"] as? [String: Any]
        self.loopDevice = loopDeviceParams.map { LoopDevice($0) }
    }
    
    func refresh(complete: @escaping ((User?, Api.ApiError?) -> Void)) {
        Api.user { response, error in
             guard let response = response, error == nil else {
                complete(nil, error)
                return
            }
            
            guard let userParams = response["user"] as? [String: Any] else {
                print("user object not set")
                complete(nil, Api.defaultError)
                return
            }
            
            User.currentUser = User(userParams)
            complete(User.currentUser, nil)
        }
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
        User.currentUser = nil
    }
}
