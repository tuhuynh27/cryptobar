import Foundation

typealias PriceUpdateCallback = (String) -> Void

class BinanceWebSocket {
    private var task: URLSessionWebSocketTask?
    private var coin: String = ""
    private var updatePriceCallback: PriceUpdateCallback?
    private var isConnected: Bool = false // Flag to track if WebSocket is connected

    func setCallback(callback: @escaping PriceUpdateCallback) {
        self.updatePriceCallback = callback
    }
    
    func startWebSocket(for coin: String) {
        self.coin = coin.lowercased()
        if !isConnected {
            connect()
        } else {
            print("WebSocket is already connected.")
        }
    }

    private func connect() {
        let urlString = "wss://stream.binance.com:9443/stream?streams=\(self.coin)usdt@aggTrade"
        let url = URL(string: urlString)!

        // Create URLSession with custom configuration to ignore SSL validation
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.waitsForConnectivity = true
        sessionConfiguration.urlCredentialStorage = nil
        sessionConfiguration.tlsMinimumSupportedProtocol = .tlsProtocol12
        sessionConfiguration.tlsMaximumSupportedProtocol = .tlsProtocol12
        sessionConfiguration.timeoutIntervalForRequest = 60
        sessionConfiguration.timeoutIntervalForResource = 60

        let session = URLSession(configuration: sessionConfiguration)

        task = session.webSocketTask(with: url)
        task?.resume()
        isConnected = true // Set connected flag to true
        handleIncomingMessage()
    }

    func cancelWebSocket() {
        guard let task = task else {
            print("WebSocket task is nil, cannot cancel.")
            return
        }
        
        switch task.state {
        case .suspended, .running:
            task.cancel(with: .goingAway, reason: nil)
            self.task = nil
            isConnected = false // Reset connected flag to false
            print("WebSocket task cancelled.")
        case .canceling, .completed:
            print("WebSocket task is already cancelling or completed.")
        @unknown default:
            print("Unknown task state.")
        }
    }

    private func handleIncomingMessage() {
        task?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error receiving message: \(error)")
                self?.reconnectIfNeeded()
            case .success(let message):
                switch message {
                case .data(let data):
                    print("Received data message: \(data)")
                case .string(let str):
                    self?.handleData(str)
                @unknown default:
                    print("Unknown message type")
                }
                // Call the function again to keep listening for messages
                self?.handleIncomingMessage()
            }
        }
    }

    private func handleData(_ jsonString: String) {
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("Error converting string to data")
            return
        }
        
        do {
            let aggTradeResponse = try JSONDecoder().decode(AggTradeResponse.self, from: jsonData)
            if let callback = updatePriceCallback {
                callback(aggTradeResponse.data.p)
            }
        } catch {
            print("Error decoding data: \(error)")
        }
    }
    
    struct AggTradeData: Codable {
        let e: String
        let E: Int
        let s: String
        let a: Int
        let p: String
        let q: String
        let f: Int
        let l: Int
        let T: Int
        let m: Bool
        let M: Bool
    }
    
    struct AggTradeResponse: Codable {
        let stream: String
        let data: AggTradeData
    }

    private func reconnectIfNeeded() {
        // Attempt to reconnect after a delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            print("Attempting to reconnect...")
            self.connect()
        }
    }
}
