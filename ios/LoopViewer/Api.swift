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
    static var baseUrl = "https://cloud9.appspot.com"
    //static var baseUrl = "http://169.237.4.77:8080"
    static let defaultError = ApiError(response: [:])
    
    static func configuration(deviceSecurity: String) -> URLSessionConfiguration {
        let build = Bundle.main.infoDictionary?["CFBundleVersion"].flatMap { $0 as? String } ?? "0000"
        var headers = ["x-device": deviceSecurity, "x-build": build, "x-platform": "ios"]
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

        DeviceSecurity.generatePayload() { deviceSecurity in
            let session = URLSession(configuration: configuration(deviceSecurity: deviceSecurity))
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
    }
    
    //promo api added by jaime
    static func redeemPromo(promoCode: String, accountId: String, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/api/redeem_promo",
                parameters: ["code": promoCode, "account_id": accountId],
                completion: completion)
    }
    
    static func sendVerificationCode(phoneNumber: String, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/api/send_verification_code",
                parameters: ["phone_number": phoneNumber],
                completion: completion)
    }
    
    static func verifyCode(e164PhoneNumber: String, code: String, challengeResponse: String?, completion: @escaping ApiCompletion) {
        if let challengeResponse = challengeResponse {
            ApiCall(endpoint: "/api/verify_code",
                    parameters: ["e164_phone_number": e164PhoneNumber,
                                 "code": code,
                                 "challenge_response": challengeResponse],
                    completion: completion)
        } else {
            ApiCall(endpoint: "/api/verify_code",
                    parameters: ["e164_phone_number": e164PhoneNumber, "code": code],
                    completion: completion)
        }
    }
    
    static func setName(_ name: String, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/api/user",
                parameters: ["name": name],
                completion: completion)
    }

    static func setEmail(_ email: String, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/api/user",
                parameters: ["email": email],
                completion: completion)
    }
    
    static func user(completion: @escaping ApiCompletion) {
        // XXX FIXME it's kind of a hack that we're using the POST handler without any arguments
        ApiCall(endpoint: "/api/user",
                parameters: [:],
                completion: completion)
    }
    
    static func checkChallenge(response: String, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/api/check_challenge",
                parameters: ["challenge_response": response],
                completion: completion)
    }
    
    static func account(currency: String, accountId: String, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/api/account/\(currency)/\(accountId)",
                parameters: [:],
                completion: completion)
    }
    
    static func postTx(currency: String, rawTx: String, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/api/tx/\(currency)",
            parameters: ["raw_tx": rawTx],
            completion: completion)
    }
}
