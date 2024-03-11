import Cocoa
import SwiftUI

struct ContentView: View {
    @StateObject var statusBarController = StatusBarController.shared

    var body: some View {
        EmptyView()
            .onAppear {
                statusBarController.startUpdatingPrice()
            }
            .accessibility(identifier: "btcPrice")
    }
}

class StatusBarController: ObservableObject {
    private static var sharedController: StatusBarController = StatusBarController()
    
    static var shared: StatusBarController {
        return sharedController
    }

    private var statusItem: NSStatusItem?
    @Published var btcPrice: String = "Loading..."
    private let binanceAPIURL = URL(string: "https://api.binance.com/api/v3/ticker/24hr?symbol=BTCUSDT")!
    private var timer: Timer?

    private init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "BTC \(btcPrice)"
    }

    func startUpdatingPrice() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.fetchData()
        }
        timer?.fire() // Fetch data immediately upon starting the timer
    }

    private func fetchData() {
        URLSession.shared.dataTask(with: binanceAPIURL) { data, response, error in
            guard let data = data else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            if let btcData = try? JSONDecoder().decode(BTCData.self, from: data) {
                DispatchQueue.main.async {
                    if let priceDouble = Double(btcData.lastPrice) {
                        self.btcPrice = String(format: "%.2f", priceDouble)
                    }
                    let priceChange = (btcData.priceChangePercent as NSString).floatValue
                    let changeSymbol = priceChange < 0 ? "↓" : "↑"
                    let changePrice = String(format: "%.2f", abs(priceChange))
                    self.statusItem?.button?.title = "₿TC \(self.btcPrice)\(changeSymbol) \(changePrice)%"
                }
            }
        }.resume()
    }
}


struct BTCStatusBarView: NSViewRepresentable {
    typealias NSViewType = NSView

    func makeNSView(context: Context) -> NSView {
        return NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Nothing to update
    }
}

struct BTCData: Codable {
    let lastPrice: String
    let priceChangePercent: String

    enum CodingKeys: String, CodingKey {
        case lastPrice = "lastPrice"
        case priceChangePercent = "priceChangePercent"
    }
}
