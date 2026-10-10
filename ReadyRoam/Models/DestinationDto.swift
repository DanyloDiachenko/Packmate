import Foundation

public struct DestinationDto: Codable, Identifiable, Hashable {
    public var id: String { "\(city.lowercased())_\(country.lowercased())" }
    public let country: String
    public let city: String
    public let countryFlag: String
    public let bannerImage: String?

    public init(country: String, city: String, countryFlag: String, bannerImage: String? = nil) {
        self.country = country
        self.city = city
        self.countryFlag = countryFlag
        self.bannerImage = bannerImage
    }

    enum CodingKeys: String, CodingKey {
        case country
        case city
        case countryFlag
        case bannerImage

        case countryPascal = "Country"
        case cityPascal = "City"
        case countryFlagPascal = "CountryFlag"
        case bannerImagePascal = "BannerImage"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.country = try container.decodeIfPresent(String.self, forKey: .country)
            ?? container.decode(String.self, forKey: .countryPascal)
        self.city = try container.decodeIfPresent(String.self, forKey: .city)
            ?? container.decode(String.self, forKey: .cityPascal)
        self.countryFlag = try container.decodeIfPresent(String.self, forKey: .countryFlag)
            ?? container.decode(String.self, forKey: .countryFlagPascal)
        self.bannerImage = try container.decodeIfPresent(String.self, forKey: .bannerImage)
            ?? container.decodeIfPresent(String.self, forKey: .bannerImagePascal)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(country, forKey: .country)
        try container.encode(city, forKey: .city)
        try container.encode(countryFlag, forKey: .countryFlag)
        try container.encode(bannerImage, forKey: .bannerImage)
    }
}
