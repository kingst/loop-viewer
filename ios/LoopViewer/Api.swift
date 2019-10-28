import Foundation
import CardScan

struct Api {
    
    struct ApiError: Error {
        var message: String
        var code: String
        var payload: String?
        
        init(response: [String: Any]) {
            self.message = (response["error_message"] as? String) ?? "Network error"
            self.code = (response["error_code"] as? String) ?? "network_error"
            self.payload = response["error_payload"] as? String
        }
    }
    
    // XXX FIXME we should move to a more traditional error handling method
    typealias ApiCompletion = ((_ response: [String: Any]?, _ error: ApiError?) -> Void)
    //static var baseUrl = "https://loop-viewer.appspot.com"
    static var baseUrl = "http://10.0.0.114:8080"
    static let defaultError = ApiError(response: [:])
    
    static func configuration() -> URLSessionConfiguration {
        var headers: [String: String] = [:]
        if let authToken = Storage.authToken {
            headers["x-authtoken"] = authToken
        }
        
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 60
        config.httpAdditionalHeaders = headers
        return config
    }
    
    static func ApiCall(endpoint: String, parameters: [String: Any], completion: @escaping ApiCompletion) {
        
        guard let url = URL(string: baseUrl + endpoint) else {
            DispatchQueue.main.async { completion(nil, defaultError) }
            return
        }

        guard let requestData = try? JSONSerialization.data(withJSONObject: parameters) else {
            DispatchQueue.main.async { completion(nil, defaultError) }
            return
        }

        let session = URLSession(configuration: configuration())
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        session.uploadTask(with: request, from: requestData) { data, response, error in
            guard let rawData = data else {
                DispatchQueue.main.async { completion(nil, defaultError) }
                return
            }
            
            let jsonData = try? JSONSerialization.jsonObject(with: rawData)
            guard let responseData = jsonData as? [String: Any] else {
                DispatchQueue.main.async { completion(nil, defaultError) }
                return
            }
            
            DispatchQueue.main.async {
                if "ok" == responseData["status"] as? String {
                    completion(responseData, nil)
                } else {
                    completion(nil, ApiError(response: responseData))
                }
            }
        }.resume()
    }
        
    static func sendVerificationCode(phoneNumber: String, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/api/v1/send_verification_code",
                parameters: ["phone_number": phoneNumber],
                completion: completion)
    }
    
    static func verifyCode(e164PhoneNumber: String, code: String, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/api/v1/verify_code",
                parameters: ["e164_phone_number": e164PhoneNumber, "code": code],
                completion: completion)
    }
    
    static func setName(_ name: String, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/api/v1/user",
                parameters: ["name": name],
                completion: completion)
    }

    static func setEmail(_ email: String, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/api/v1/user",
                parameters: ["email": email],
                completion: completion)
    }
    
    static func setApiSecret(_ apiSecret: String, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/api/v1/user",
                parameters: ["api_secret": apiSecret],
                completion: completion)
    }
    
    static func user(completion: @escaping ApiCompletion) {
        // XXX FIXME it's kind of a hack that we're using the POST handler without any arguments
        ApiCall(endpoint: "/api/v1/user",
                parameters: [:],
                completion: completion)
    }
}
