import Foundation
import Security

//final class KeychainService {
//    static let shared = KeychainService()
//    private init() {}
//
//    private let tokenKey = "kf4OhwXeqCUTcKFK3BIue5wIEf2D13gK"
//
//    func saveToken(_ token: String) {
//        guard let data = token.data(using: .utf8) else { return }
//
//        let query: [CFString: Any] = [
//            kSecClass: kSecClassGenericPassword,
//            kSecAttrAccount: tokenKey,
//            kSecValueData: data,
//            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
//        ]
//
//        SecItemDelete(query as CFDictionary)
//        SecItemAdd(query as CFDictionary, nil)
//    }
//
//    func getToken() -> String? {
//        let query: [CFString: Any] = [
//            kSecClass: kSecClassGenericPassword,
//            kSecAttrAccount: tokenKey,
//            kSecReturnData: true,
//            kSecMatchLimit: kSecMatchLimitOne
//        ]
//
//        var result: AnyObject?
//        let status = SecItemCopyMatching(query as CFDictionary, &result)
//
//        guard status == errSecSuccess,
//              let data = result as? Data,
//              let token = String(data: data, encoding: .utf8) else {
//            return nil
//        }
//        return token
//    }
//
//    func deleteToken() {
//        let query: [CFString: Any] = [
//            kSecClass: kSecClassGenericPassword,
//            kSecAttrAccount: tokenKey
//        ]
//        SecItemDelete(query as CFDictionary)
//    }
//}
//import Foundation
//import Security

final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    private enum Keys {
        static let accessToken = "mozart.access.token"
    }

    // MARK: - Save

    func saveToken(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: Keys.accessToken,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    // MARK: - Get

    func getToken() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: Keys.accessToken,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }

    // MARK: - Delete

    func deleteToken() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: Keys.accessToken
        ]
        SecItemDelete(query as CFDictionary)
    }
}
