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
    private let binanceWebSocket = BinanceWebSocket()
    
    static var shared: StatusBarController {
        return sharedController
    }

    private var statusItem: NSStatusItem?
    var cryptoPrice: String = "Loading..."
    var selectedCrypto: String = "BTC"
    var priceChange: Float = 0
    
    // Array to hold cryptocurrency options
    private let cryptoOptions = ["BTC", "ETH", "BNB", "SOL", "XRP", "ADA", "DOGE", "SHIB", "AVAX", "DOT", "LINK", "MATIC", "UNI", "NEAR", "PEPE", "FLOKI"]
    // Menu to display cryptocurrency options
    private var cryptoMenu = NSMenu()

    private let binanceAPIURLBase = "https://api.binance.com/api/v3/ticker/24hr?symbol="
    private var timer: Timer?
    
    func updatePrice(newPrice: String) {
        self.cryptoPrice = newPrice
        self.renderPriceOnStatusBar()
    }
    
    private init() {
        binanceWebSocket.setCallback(callback: updatePrice)
        
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
        
        // Add separator
        let separator1MenuItem = NSMenuItem.separator()
        cryptoMenu.addItem(separator1MenuItem)
        
        // Add "Visit CoinTrack" option
        let visitCoinTrackMenuItem = NSMenuItem(title: "Open CoinTrack", action: #selector(visitCoinTrack(_:)), keyEquivalent: "")
        visitCoinTrackMenuItem.target = self
        cryptoMenu.addItem(visitCoinTrackMenuItem)
        
        // Add "About" option
        let aboutMenuItem = NSMenuItem(title: "About", action: #selector(showAboutPopup(_:)), keyEquivalent: "")
        aboutMenuItem.target = self
        cryptoMenu.addItem(aboutMenuItem)
        
        // Add another separator
        let separator2MenuItem = NSMenuItem.separator()
        cryptoMenu.addItem(separator2MenuItem)
        
        // Add Quit option
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitApplication(_:)), keyEquivalent: "q")
        quitMenuItem.target = self
        cryptoMenu.addItem(quitMenuItem)
        
        // Set menu for status item
        statusItem?.menu = cryptoMenu
    }

    @objc private func visitCoinTrack(_ sender: Any?) {
        guard let url = URL(string: "https://cointrack.keva.dev") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func showAboutPopup(_ sender: Any?) {
        let version = "Version 0.0.3"
        let copyright = "© 2024 by Tu Huynh"
        let alert = NSAlert()
        alert.messageText = "\(version)\n\(copyright)"
        alert.runModal()
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
        
        fetchDataViaHttpRequest()
        binanceWebSocket.cancelWebSocket()
        binanceWebSocket.startWebSocket(for: self.selectedCrypto)
        // Schedule a new timer
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            self.fetchDataViaHttpRequest()
            self.binanceWebSocket.cancelWebSocket()
            self.binanceWebSocket.startWebSocket(for: self.selectedCrypto)
        }
    }
    
    private func renderPriceOnStatusBar() {
        if let priceDouble = Double(self.cryptoPrice) {
            var formattedPrice: String
            if abs(priceDouble) >= 100 {
                formattedPrice = String(format: "%.2f", priceDouble)
            } else if abs(priceDouble) >= 0.01 {
                formattedPrice = String(format: "%.4f", priceDouble)
            } else {
                formattedPrice = String(format: "%.8f", priceDouble)
            }
            
            let changeSymbol = priceChange < 0 ? "↓" : "↑"
            let changePrice = String(format: "%.2f", abs(priceChange))
            
            // Update UI on the main thread
            DispatchQueue.main.async {
                // Use a monospaced font
                let buttonFont = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
                self.statusItem?.button?.font = buttonFont
                self.statusItem?.button?.title = "\(self.selectedCrypto) \(formattedPrice)\(changeSymbol) \(self.priceChange < 0 ? "-" : "+")\(changePrice)%"
            }
        }
    }

    private func fetchDataViaHttpRequest() {
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
                self.cryptoPrice = cryptoData.lastPrice
                self.priceChange = (cryptoData.priceChangePercent as NSString).floatValue
                self.renderPriceOnStatusBar()
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
