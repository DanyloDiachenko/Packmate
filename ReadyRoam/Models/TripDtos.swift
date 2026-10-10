import Foundation

public struct TripDestinationDto: Codable, Hashable {
    public let country: String
    public let countryFlag: String
    public let city: String
    public let bannerImage: String?
    public let weatherToday: String?
    public let currentSeason: String?

    public init(
        country: String,
        countryFlag: String,
        city: String,
        bannerImage: String? = nil,
        weatherToday: String? = nil,
        currentSeason: String? = nil
    ) {
        self.country = country
        self.countryFlag = countryFlag
        self.city = city
        self.bannerImage = bannerImage
        self.weatherToday = weatherToday
        self.currentSeason = currentSeason
    }

    enum CodingKeys: String, CodingKey {
        case country
        case countryFlag
        case city
        case bannerImage
        case weatherToday
        case currentSeason

        case countryPascal = "Country"
        case countryFlagPascal = "CountryFlag"
        case cityPascal = "City"
        case bannerImagePascal = "BannerImage"
        case weatherTodayPascal = "WeatherToday"
        case currentSeasonPascal = "CurrentSeason"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.country = try container.decodeIfPresent(String.self, forKey: .country)
            ?? container.decode(String.self, forKey: .countryPascal)
        self.countryFlag = try container.decodeIfPresent(String.self, forKey: .countryFlag)
            ?? container.decode(String.self, forKey: .countryFlagPascal)
        self.city = try container.decodeIfPresent(String.self, forKey: .city)
            ?? container.decode(String.self, forKey: .cityPascal)
        self.bannerImage = try container.decodeIfPresent(String.self, forKey: .bannerImage)
            ?? container.decodeIfPresent(String.self, forKey: .bannerImagePascal)
        self.weatherToday = try container.decodeIfPresent(String.self, forKey: .weatherToday)
            ?? container.decodeIfPresent(String.self, forKey: .weatherTodayPascal)
        self.currentSeason = try container.decodeIfPresent(String.self, forKey: .currentSeason)
            ?? container.decodeIfPresent(String.self, forKey: .currentSeasonPascal)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(country, forKey: .country)
        try container.encode(countryFlag, forKey: .countryFlag)
        try container.encode(city, forKey: .city)
        try container.encodeIfPresent(bannerImage, forKey: .bannerImage)
        try container.encodeIfPresent(weatherToday, forKey: .weatherToday)
        try container.encodeIfPresent(currentSeason, forKey: .currentSeason)
    }
}

public struct TripResponseDto: Codable, Identifiable, Hashable {
    public let id: UUID
    public let userId: UUID
    public let destination: TripDestinationDto
    public let departDate: String
    public let returnDate: String
    public let tags: [String]
    public let isArchived: Bool
    public let createdAt: String

    public init(
        id: UUID,
        userId: UUID,
        destination: TripDestinationDto,
        departDate: String,
        returnDate: String,
        tags: [String],
        isArchived: Bool = false,
        createdAt: String = ""
    ) {
        self.id = id
        self.userId = userId
        self.destination = destination
        self.departDate = departDate
        self.returnDate = returnDate
        self.tags = tags
        self.isArchived = isArchived
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, userId, destination, departDate, returnDate, tags, isArchived, createdAt
        case idPascal = "Id"
        case userIdPascal = "UserId"
        case destinationPascal = "Destination"
        case departDatePascal = "DepartDate"
        case returnDatePascal = "ReturnDate"
        case tagsPascal = "Tags"
        case isArchivedPascal = "IsArchived"
        case createdAtPascal = "CreatedAt"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id)
            ?? container.decode(UUID.self, forKey: .idPascal)
        self.userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
            ?? container.decode(UUID.self, forKey: .userIdPascal)
        self.destination = try container.decodeIfPresent(TripDestinationDto.self, forKey: .destination)
            ?? container.decode(TripDestinationDto.self, forKey: .destinationPascal)
        self.departDate = try container.decodeIfPresent(String.self, forKey: .departDate)
            ?? container.decode(String.self, forKey: .departDatePascal)
        self.returnDate = try container.decodeIfPresent(String.self, forKey: .returnDate)
            ?? container.decode(String.self, forKey: .returnDatePascal)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
            ?? container.decodeIfPresent([String].self, forKey: .tagsPascal)
            ?? []
        self.isArchived = (try? container.decodeIfPresent(Bool.self, forKey: .isArchived))
            ?? (try? container.decodeIfPresent(Bool.self, forKey: .isArchivedPascal))
            ?? false
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
            ?? container.decodeIfPresent(String.self, forKey: .createdAtPascal)
            ?? ""
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(destination, forKey: .destination)
        try container.encode(departDate, forKey: .departDate)
        try container.encode(returnDate, forKey: .returnDate)
        try container.encode(tags, forKey: .tags)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

public struct PaginatedTripsResponseDto: Codable {
    public let totalItems: Int
    public let trips: [TripResponseDto]

    enum CodingKeys: String, CodingKey {
        case totalItems, trips
        case totalItemsPascal = "TotalItems"
        case tripsPascal = "Trips"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.totalItems = try container.decodeIfPresent(Int.self, forKey: .totalItems)
            ?? container.decodeIfPresent(Int.self, forKey: .totalItemsPascal)
            ?? 0
        self.trips = try container.decodeIfPresent([TripResponseDto].self, forKey: .trips)
            ?? container.decodeIfPresent([TripResponseDto].self, forKey: .tripsPascal)
            ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalItems, forKey: .totalItems)
        try container.encode(trips, forKey: .trips)
    }

    public init(totalItems: Int, trips: [TripResponseDto]) {
        self.totalItems = totalItems
        self.trips = trips
    }
}

public struct CreateTripRequestDto: Codable {
    public let destination: TripDestinationDto
    public let departDate: String
    public let returnDate: String
    public let tags: [String]

    public init(destination: TripDestinationDto, departDate: String, returnDate: String, tags: [String]) {
        self.destination = destination
        self.departDate = departDate
        self.returnDate = returnDate
        self.tags = tags
    }

    public init(country: String, countryFlag: String, city: String, departDate: String, returnDate: String, tags: [String]) {
        self.destination = TripDestinationDto(country: country, countryFlag: countryFlag, city: city)
        self.departDate = departDate
        self.returnDate = returnDate
        self.tags = tags
    }
}

public struct UpdateTripRequestDto: Codable {
    public let destination: TripDestinationDto?
    public let departDate: String?
    public let returnDate: String?
    public let tags: [String]?
    public let isArchived: Bool?

    public init(destination: TripDestinationDto? = nil, departDate: String? = nil, returnDate: String? = nil, tags: [String]? = nil, isArchived: Bool? = nil) {
        self.destination = destination
        self.departDate = departDate
        self.returnDate = returnDate
        self.tags = tags
        self.isArchived = isArchived
    }
}
