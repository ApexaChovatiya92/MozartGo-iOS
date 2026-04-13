import Foundation
import Network
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    private init() { startMonitoring() }

    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType = .wifi

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.mozartgo.network")

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}
