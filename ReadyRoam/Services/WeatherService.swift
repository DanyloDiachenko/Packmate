import Foundation

public struct WeatherResponseDto: Codable {
    public let city: String
    public let country: String
    public let weatherToday: String
    public let currentSeason: String
    public let averageTemperatureC: Double?
    public let hasRainRisk: Bool?
    public let conditionDescription: String?

    enum CodingKeys: String, CodingKey {
        case city, country, weatherToday, currentSeason, averageTemperatureC, hasRainRisk, conditionDescription
        case cityPascal = "City"
        case countryPascal = "Country"
        case weatherTodayPascal = "WeatherToday"
        case currentSeasonPascal = "CurrentSeason"
        case averageTemperatureCPascal = "AverageTemperatureC"
        case hasRainRiskPascal = "HasRainRisk"
        case conditionDescriptionPascal = "ConditionDescription"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.city = (try? container.decode(String.self, forKey: .city))
            ?? (try? container.decode(String.self, forKey: .cityPascal)) ?? ""
        self.country = (try? container.decode(String.self, forKey: .country))
            ?? (try? container.decode(String.self, forKey: .countryPascal)) ?? ""
        self.weatherToday = (try? container.decode(String.self, forKey: .weatherToday))
            ?? (try? container.decode(String.self, forKey: .weatherTodayPascal)) ?? ""
        self.currentSeason = (try? container.decode(String.self, forKey: .currentSeason))
            ?? (try? container.decode(String.self, forKey: .currentSeasonPascal)) ?? ""
        self.averageTemperatureC = (try? container.decodeIfPresent(Double.self, forKey: .averageTemperatureC))
            ?? (try? container.decodeIfPresent(Double.self, forKey: .averageTemperatureCPascal))
        self.hasRainRisk = (try? container.decodeIfPresent(Bool.self, forKey: .hasRainRisk))
            ?? (try? container.decodeIfPresent(Bool.self, forKey: .hasRainRiskPascal))
        self.conditionDescription = (try? container.decodeIfPresent(String.self, forKey: .conditionDescription))
            ?? (try? container.decodeIfPresent(String.self, forKey: .conditionDescriptionPascal))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(city, forKey: .city)
        try container.encode(country, forKey: .country)
        try container.encode(weatherToday, forKey: .weatherToday)
        try container.encode(currentSeason, forKey: .currentSeason)
        try container.encodeIfPresent(averageTemperatureC, forKey: .averageTemperatureC)
        try container.encodeIfPresent(hasRainRisk, forKey: .hasRainRisk)
        try container.encodeIfPresent(conditionDescription, forKey: .conditionDescription)
    }
}

public typealias WeatherResponse = WeatherResponseDto

@MainActor
final class WeatherService: WeatherServiceProtocol, ObservableObject {
    static let shared = WeatherService()

    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol? = nil) {
        self.networkClient = networkClient ?? URLSessionNetworkClient(tokenProvider: AuthService.shared)
    }

    func fetchLiveWeather(city: String, country: String) async throws -> WeatherResponse {
        let formatter = ISO8601DateFormatter()
        let departDate = formatter.string(from: Date())
        let returnDate = formatter.string(from: Date().addingTimeInterval(7 * 24 * 3600))
        return try await fetchWeather(city: city, country: country, departDate: departDate, returnDate: returnDate)
    }

    func fetchWeather(
        city: String,
        country: String,
        departDate: String,
        returnDate: String
    ) async throws -> WeatherResponseDto {
        let queryItems = [
            URLQueryItem(name: "city", value: city),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "departDate", value: departDate),
            URLQueryItem(name: "returnDate", value: returnDate)
        ]

        let endpoint = Endpoint(
            path: "weather",
            method: .get,
            queryItems: queryItems,
            requiresAuth: true
        )
        return try await networkClient.request(endpoint)
    }
}
