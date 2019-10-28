import Foundation

struct Storage {
    static var authToken: String? {
        get {
            return UserDefaults.standard.string(forKey: "authToken")
        }
        
        set(authToken) {
            UserDefaults.standard.set(authToken ?? nil, forKey: "authToken")
            UserDefaults.standard.synchronize()
        }
    }
}
