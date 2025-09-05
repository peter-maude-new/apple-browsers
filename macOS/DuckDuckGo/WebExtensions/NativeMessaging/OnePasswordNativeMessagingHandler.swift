import Foundation
import WebKit

@available(macOS 15.4, *)
final class OnePasswordNativeMessagingHandler: NativeMessagingHandling {

    private var connections = [NativeMessagingConnection]()

    // Path to the native-messaging host you found
    private let onePasswordNMPath =
        "/Applications/1Password.app/Contents/Library/LoginItems/1Password Browser Helper.app/Contents/MacOS/1Password-BrowserSupport"

    final class TheDelegate: NativeMessagingCommunicatorDelegate {
        func nativeMessagingCommunicator(_ nativeMessagingCommunicator: NativeMessagingCommunication, didReceiveMessageData messageData: Data) {
            guard let messageString = String(data: messageData, encoding: .utf8) else {
                print("🤌 Got message data but couldn't decode as UTF-8")
                return
            }

            print("🤌 Got message data: \(messageString)")
        }
        func nativeMessagingCommunicatorProcessDidTerminate(_ nativeMessagingCommunicator: NativeMessagingCommunication) {
            print("🤌 Process terminated :(")
        }
    }

    let receiver = TheDelegate()

    // MARK: - NativeMessagingHandling

    func handleMessage(_ message: Any,
                       to applicationIdentifier: String?,
                       for extensionContext: WKWebExtensionContext) async throws -> Any? {

        guard let connection = connections.first(where: { connection in connection.applicationIdentifier == applicationIdentifier }) else {
            return nil
        }

        guard let dict = message as? [String: Any] else {
            return nil
        }

        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
        } catch {
            assertionFailure("Encoding error")
            jsonData = Data()
        }

        connection.communicator.send(messageData: jsonData)

/*
        guard let dict = message as? [String: Any] else {
            return nil
        }

        // Create the communicator (either immediately if app was running, or this is for other apps)
        let communicator = NativeMessagingCommunicator(appPath: onePasswordNMPath, arguments: [onePasswordNMPath, WebExtensionIdentifier.onePassword.identifier])
        communicator.delegate = receiver
        let connection = NativeMessagingConnection(communicator: communicator)

        print("🤌 Running proxy process")
        try connection.communicator.runProxyProcess()

        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
        } catch {
            assertionFailure("Encoding error")
            jsonData = Data()
        }

        print("🤌 Sending message")
        communicator.send(messageData: jsonData)

        print("🤌 Sleeping")
        try await Task.sleep(interval: .seconds(5))

        print("🤌 Ciao!")*/
        return nil
    }

    func handleConnection(using port: WKWebExtension.MessagePort, for extensionContext: WKWebExtensionContext) throws {
        try makeConnection(for: port)
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
    func makeConnection(for port: WKWebExtension.MessagePort) throws -> NativeMessagingConnection {
        // Create the communicator (either immediately if app was running, or this is for other apps)
        let communicator = NativeMessagingCommunicator(appPath: onePasswordNMPath, arguments: ["chrome-extension://hjlinigoblmkhjejkmbegnoaljkphmgo/"])
        communicator.delegate = receiver
        let connection = NativeMessagingConnection(port: port, communicator: communicator)
        connections.append(connection)

        port.messageHandler = { (message, error) in
            if let error = error {
                print("🤌 Port error: \(error)")
                return
            }

            guard let message = message else {
                print("🤌 Port message was nil")
                return
            }

            print("🤌 Got port message: \(message)")
        }

        port.disconnectHandler = { [weak self] error in
            print("🤌 Port disconnected: \(String(describing: error))")

            guard let self else {
                return
            }

            connections.removeAll { connection in
                connection.port.isDisconnected
            }
        }

        print("🤌 Running process")
        try communicator.runProxyProcess()
        print("🤌 Running process DONE")
        return connection
    }

    func connection(for port: WKWebExtension.MessagePort) -> NativeMessagingConnection? {
        connections.first { $0.port == port }
    }

    func cancelConnection(with port: WKWebExtension.MessagePort) {
        connections.removeAll { $0.port == port }
    }
}
