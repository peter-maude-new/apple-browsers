import Foundation
import WebKit

@available(macOS 15.4, *)
final class OnePasswordNativeMessagingHandler: NativeMessagingHandling {

    private var connections = [WKWebExtension.MessagePort: NativeMessagingConnection]()

    // Path to the native-messaging host you found
    private let onePasswordNMPath =
        "/Applications/1Password.app/Contents/Library/LoginItems/1Password Browser Helper.app/Contents/MacOS/1Password-BrowserSupport"

    // MARK: - NativeMessagingHandling

    func handleMessage(_ message: Any,
                       to applicationIdentifier: String?,
                       for extensionContext: WKWebExtensionContext) async throws -> Any? {

        guard let dict = message as? [String: Any] else {
            return nil
        }

        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: dict, options: [.withoutEscapingSlashes])
        } catch {
            assertionFailure("Encoding error")
            jsonData = Data()
        }

        print("🤌 Sending single request message")
        let request = NativeMessagingSingleRequest(
            appPath: onePasswordNMPath,
            arguments: ["chrome-extension://hjlinigoblmkhjejkmbegnoaljkphmgo/"]
        )

        do {
            let responseData = try await request.send(messageData: jsonData)

            // Try to parse the response as JSON
            if let responseObject = try? JSONSerialization.jsonObject(with: responseData, options: []) {
                print("🤌 Got response: \(String(data: responseData, encoding: .utf8)!)")
                return responseObject
            } else if let responseString = String(data: responseData, encoding: .utf8) {
                print("🤌 Got response string: \(responseString)")
                return responseString
            } else {
                print("🤌 Got response data but couldn't decode")
                throw NSError(domain: "OnePasswordNativeMessagingHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not decode response data from 1Password"])
            }
        } catch {
            print("🤌 Request failed: \(error)")
            throw error
        }
    }

    func handleConnection(using port: WKWebExtension.MessagePort, for extensionContext: WKWebExtensionContext) throws {
        try makeConnection(for: port, context: extensionContext)
    }

    /*
     "allowed_origins": [
       "chrome-extension://hjlinigoblmkhjejkmbegnoaljkphmgo/",
       "chrome-extension://bkpbhnjcbehoklfkljkkbbmipaphipgl/",
       "chrome-extension://gejiddohjgogedgjnonbofjigllpkmbf/",
       "chrome-extension://khgocmkkpikpnmmkgmdnfckapcdkgfaf/",
       "chrome-extension://aeblfdkhhhdcdjpifhhbdiojplfjncoa/",
       "chrome-extension://dppgmdbiimibapkepcbdbmkaabgiofem/"
     ]
     */

    @discardableResult
    func makeConnection(for port: WKWebExtension.MessagePort, context: WKWebExtensionContext) throws -> NativeMessagingConnection {
        let connection = NativeMessagingConnection(
            appPath: onePasswordNMPath,
            arguments: ["chrome-extension://hjlinigoblmkhjejkmbegnoaljkphmgo/"],
            messageHandler: { messageData in
                do {
                    // Try to parse the response and send it back through the port
                    if let responseObject = try? JSONSerialization.jsonObject(with: messageData, options: []) {
                        print("🤌 Sending response to port: \(String(data: messageData, encoding: .utf8)!)")
                        try await port.sendMessage(responseObject)
                    } else if let responseString = String(data: messageData, encoding: .utf8) {
                        print("🤌 Sending response string to port: \(responseString)")
                        try await port.sendMessage(responseString)
                    } else {
                        throw NSError(domain: "OnePasswordNativeMessagingHandler", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not decode response data from 1Password"])
                    }
                } catch {
                    print("🤌 Failed to send message to port: \(error)")
                }
            },
            disconnectHandler: { [weak self] error in
                print("🤌 Native process disconnected: \(String(describing: error))")

                guard let self else { return }
                connections.removeValue(forKey: port)

                // Optionally disconnect the port as well
                port.disconnect()
            }
        )

        connections[port] = connection

        port.messageHandler = { [weak self] (message, error) in
            guard let self else { return }

            if let error = error {
                print("🤌 Port error: \(error)")
                return
            }

            guard let message = message else {
                print("🤌 Port message was nil")
                return
            }

            print("🤌 Got port message: \(message)")

            // Extract the actual JSON data from the wrapper
            let actualMessage: Any
            if let messageDict = message as? [String: Any],
               let dataString = messageDict["data"] as? String,
               let data = dataString.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                actualMessage = jsonObject
                print("🤌 Extracted actual message: \(actualMessage)")
            } else {
                // Fallback to original message if extraction fails
                actualMessage = message
                print("🤌 Using original message format")
            }

            // swiftlint:disable:next force_try
            let messageData = try! JSONSerialization.data(withJSONObject: actualMessage, options: [.withoutEscapingSlashes])

            do {
                try connections[port]?.send(messageData: messageData)
            } catch {
                print("🤌 Failed to send message data: \(error)")
            }
        }

        port.disconnectHandler = { [weak self] error in
            print("🤌 Port disconnected: \(String(describing: error))")

            guard let self else {
                return
            }

            // Terminate the native process when port disconnects
            connections[port]?.terminateProxyProcess()
            connections.removeValue(forKey: port)
        }

        print("🤌 Running process")
        try connection.runProxyProcess()
        print("🤌 Running process DONE")
        return connection
    }

//    func connection(for port: WKWebExtension.MessagePort) -> NativeMessagingConnection? {
//        connections.first { $0.port == port }
//    }
//
//    func cancelConnection(with port: WKWebExtension.MessagePort) {
//        connections.removeAll { $0.port == port }
//    }
}
