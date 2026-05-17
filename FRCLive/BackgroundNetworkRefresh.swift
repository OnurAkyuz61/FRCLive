import Foundation
import Network

/// İnternet geri gelince arka plan yenilemesi planla (uygulama askıda / arka plandayken).
final class BackgroundNetworkRefresh {
    static let shared = BackgroundNetworkRefresh()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "onurakyuz.FRCLive.networkRefresh")
    private var wasUnreachable = false

    private init() {}

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let reachable = path.status == .satisfied
            if reachable, self.wasUnreachable {
                WidgetBackgroundRefreshManager.schedule(urgent: true)
            }
            self.wasUnreachable = !reachable
        }
        monitor.start(queue: queue)
    }
}
