struct StockListResponseDTO: Decodable, Sendable, Equatable {
    let stocks: [StockResponseDTO]
}
