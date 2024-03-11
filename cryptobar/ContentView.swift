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
    @Published var cryptoPrice: String = "Loading..."
    @Published var selectedCrypto: String = "BTC"
    
    // Default cryptocurrency
    private var defaultCrypto = "BTC"
    // Array to hold cryptocurrency options
    private let cryptoOptions = ["BTC", "ETH", "BNB", "SOL", "XRP", "ADA", "DOGE", "SHIB", "AVAX", "DOT", "LINK", "MATIC", "UNI", "NEAR", "PEPE", "FLOKI"]
    // Menu to display cryptocurrency options
    private var cryptoMenu = NSMenu()

    private let binanceAPIURLBase = "https://api.binance.com/api/v3/ticker/24hr?symbol="
    private var timer: Timer?
    
    private init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "\(selectedCrypto) \(cryptoPrice)"
        
        // Create an NSMenuItem for the text you want to display
        let textMenuItem = NSMenuItem(title: "Select a coin pair", action: nil, keyEquivalent: "")
        textMenuItem.isEnabled = false // Ensures the text item is not selectable
        cryptoMenu.addItem(textMenuItem)
        
        // Populate menu with cryptocurrency options
        for option in cryptoOptions {
            let menuItem = NSMenuItem(title: "\(option)/USDT", action: #selector(selectCrypto(_:)), keyEquivalent: option)
            menuItem.target = self
            cryptoMenu.addItem(menuItem)
        }
        
        // Add Quit option
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitApplication(_:)), keyEquivalent: "q")
        quitMenuItem.target = self
        cryptoMenu.addItem(quitMenuItem)
        
        // Set menu for status item
        statusItem?.menu = cryptoMenu
    }
    
    @objc private func quitApplication(_ sender: Any?) {
        NSApplication.shared.terminate(self)
    }
    
    // Function to handle selection of cryptocurrency from the menu
    @objc private func selectCrypto(_ sender: NSMenuItem) {
        selectedCrypto = sender.keyEquivalent
        startUpdatingPrice()
    }

    func startUpdatingPrice() {
        // Invalidate the existing timer
        timer?.invalidate()
        
        fetchData()
        // Schedule a new timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.fetchData()
        }
    }

    private func fetchData() {
        guard let cryptoSymbol = selectedCrypto.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            return
        }
        guard let binanceAPIURL = URL(string: "\(binanceAPIURLBase)\(cryptoSymbol)USDT") else {
            return
        }
        
        URLSession.shared.dataTask(with: binanceAPIURL) { data, response, error in
            guard let data = data else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            if let cryptoData = try? JSONDecoder().decode(CryptoData.self, from: data) {
                DispatchQueue.main.async {
                    if let priceDouble = Double(cryptoData.lastPrice) {
                        var formattedPrice: String
                        if abs(priceDouble) >= 100 {
                            formattedPrice = String(format: "%.2f", priceDouble)
                        } else if abs(priceDouble) >= 0.01 {
                            formattedPrice = String(format: "%.4f", priceDouble)
                        } else {
                            formattedPrice = String(format: "%.8f", priceDouble)
                        }
                        self.cryptoPrice = formattedPrice
                    }
                    let priceChange = (cryptoData.priceChangePercent as NSString).floatValue
                    let changeSymbol = priceChange < 0 ? "↓" : "↑"
                    let changePrice = String(format: "%.2f", abs(priceChange))
                    self.statusItem?.button?.title = "\(self.selectedCrypto) \(self.cryptoPrice)\(changeSymbol) \(changePrice)%"
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

struct CryptoData: Codable {
    let lastPrice: String
    let priceChangePercent: String

    enum CodingKeys: String, CodingKey {
        case lastPrice = "lastPrice"
        case priceChangePercent = "priceChangePercent"
    }
}
