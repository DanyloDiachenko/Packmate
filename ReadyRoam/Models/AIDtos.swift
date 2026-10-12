import Foundation

public struct TripGeneratorRequest: Codable {
    public let message: String
    public let skeleton: TripSkeletonDto?

    public init(message: String, skeleton: TripSkeletonDto? = nil) {
        self.message = message
        self.skeleton = skeleton
    }

    enum CodingKeys: String, CodingKey {
        case message, skeleton
        case messagePascal = "Message"
        case skeletonPascal = "Skeleton"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
            ?? container.decodeIfPresent(String.self, forKey: .messagePascal)
            ?? ""
        self.skeleton = try container.decodeIfPresent(TripSkeletonDto.self, forKey: .skeleton)
            ?? container.decodeIfPresent(TripSkeletonDto.self, forKey: .skeletonPascal)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(skeleton, forKey: .skeleton)
    }
}

public struct AISkeletonItemDto: Codable, Identifiable, Hashable {
    public var id: UUID
    public let section: String
    public let title: String
    public let quantity: Int
    public let tag: String?
    public let iconEmoji: String?
    public let reason: String?

    public init(
        id: UUID = UUID(),
        section: String,
        title: String,
        quantity: Int = 1,
        tag: String? = nil,
        iconEmoji: String? = nil,
        reason: String? = nil
    ) {
        self.id = id
        self.section = section
        self.title = title
        self.quantity = quantity
        self.tag = tag
        self.iconEmoji = iconEmoji
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey {
        case section, title, quantity, tag, iconEmoji, reason
        case sectionPascal = "Section"
        case titlePascal = "Title"
        case quantityPascal = "Quantity"
        case tagPascal = "Tag"
        case iconEmojiPascal = "IconEmoji"
        case reasonPascal = "Reason"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.section = try container.decodeIfPresent(String.self, forKey: .section)
            ?? container.decodeIfPresent(String.self, forKey: .sectionPascal)
            ?? ""
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .titlePascal)
            ?? ""
        self.quantity = try container.decodeIfPresent(Int.self, forKey: .quantity)
            ?? container.decodeIfPresent(Int.self, forKey: .quantityPascal)
            ?? 1
        self.tag = try container.decodeIfPresent(String.self, forKey: .tag)
            ?? container.decodeIfPresent(String.self, forKey: .tagPascal)
        self.iconEmoji = try container.decodeIfPresent(String.self, forKey: .iconEmoji)
            ?? container.decodeIfPresent(String.self, forKey: .iconEmojiPascal)
        self.reason = try container.decodeIfPresent(String.self, forKey: .reason)
            ?? container.decodeIfPresent(String.self, forKey: .reasonPascal)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(section, forKey: .section)
        try container.encode(title, forKey: .title)
        try container.encode(quantity, forKey: .quantity)
        try container.encodeIfPresent(tag, forKey: .tag)
        try container.encodeIfPresent(iconEmoji, forKey: .iconEmoji)
        try container.encodeIfPresent(reason, forKey: .reason)
    }
}

public struct TripSkeletonDto: Codable, Hashable {
    public let city: String
    public let country: String
    public let countryFlag: String?
    public let bannerImage: String?
    public let departDate: String
    public let returnDate: String
    public let durationDays: Int
    public let tags: [String]
    public let weatherSummary: String?
    public let currentSeason: String?
    public let items: [AISkeletonItemDto]

    public init(
        city: String,
        country: String,
        countryFlag: String? = nil,
        bannerImage: String? = nil,
        departDate: String,
        returnDate: String,
        durationDays: Int,
        tags: [String] = [],
        weatherSummary: String? = nil,
        currentSeason: String? = nil,
        items: [AISkeletonItemDto] = []
    ) {
        self.city = city
        self.country = country
        self.countryFlag = countryFlag
        self.bannerImage = bannerImage
        self.departDate = departDate
        self.returnDate = returnDate
        self.durationDays = durationDays
        self.tags = tags
        self.weatherSummary = weatherSummary
        self.currentSeason = currentSeason
        self.items = items
    }

    enum CodingKeys: String, CodingKey {
        case city, country, countryFlag, bannerImage, departDate, returnDate, durationDays, tags, weatherSummary, currentSeason, items
        case cityPascal = "City"
        case countryPascal = "Country"
        case countryFlagPascal = "CountryFlag"
        case bannerImagePascal = "BannerImage"
        case departDatePascal = "DepartDate"
        case returnDatePascal = "ReturnDate"
        case durationDaysPascal = "DurationDays"
        case tagsPascal = "Tags"
        case weatherSummaryPascal = "WeatherSummary"
        case currentSeasonPascal = "CurrentSeason"
        case itemsPascal = "Items"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.city = try container.decodeIfPresent(String.self, forKey: .city)
            ?? container.decodeIfPresent(String.self, forKey: .cityPascal)
            ?? ""
        self.country = try container.decodeIfPresent(String.self, forKey: .country)
            ?? container.decodeIfPresent(String.self, forKey: .countryPascal)
            ?? ""
        self.countryFlag = try container.decodeIfPresent(String.self, forKey: .countryFlag)
            ?? container.decodeIfPresent(String.self, forKey: .countryFlagPascal)
            ?? ""
        self.bannerImage = try container.decodeIfPresent(String.self, forKey: .bannerImage)
            ?? container.decodeIfPresent(String.self, forKey: .bannerImagePascal)
        self.departDate = try container.decodeIfPresent(String.self, forKey: .departDate)
            ?? container.decodeIfPresent(String.self, forKey: .departDatePascal)
            ?? ""
        self.returnDate = try container.decodeIfPresent(String.self, forKey: .returnDate)
            ?? container.decodeIfPresent(String.self, forKey: .returnDatePascal)
            ?? ""
        self.durationDays = try container.decodeIfPresent(Int.self, forKey: .durationDays)
            ?? container.decodeIfPresent(Int.self, forKey: .durationDaysPascal)
            ?? 1
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
            ?? container.decodeIfPresent([String].self, forKey: .tagsPascal)
            ?? []
        self.weatherSummary = try container.decodeIfPresent(String.self, forKey: .weatherSummary)
            ?? container.decodeIfPresent(String.self, forKey: .weatherSummaryPascal)
        self.currentSeason = try container.decodeIfPresent(String.self, forKey: .currentSeason)
            ?? container.decodeIfPresent(String.self, forKey: .currentSeasonPascal)
        self.items = try container.decodeIfPresent([AISkeletonItemDto].self, forKey: .items)
            ?? container.decodeIfPresent([AISkeletonItemDto].self, forKey: .itemsPascal)
            ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(city, forKey: .city)
        try container.encode(country, forKey: .country)
        try container.encodeIfPresent(countryFlag, forKey: .countryFlag)
        try container.encodeIfPresent(bannerImage, forKey: .bannerImage)
        try container.encode(departDate, forKey: .departDate)
        try container.encode(returnDate, forKey: .returnDate)
        try container.encode(durationDays, forKey: .durationDays)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(weatherSummary, forKey: .weatherSummary)
        try container.encodeIfPresent(currentSeason, forKey: .currentSeason)
        try container.encode(items, forKey: .items)
    }
}

public struct TripGeneratorResponse: Codable {
    public let success: Bool
    public let successMessage: String?
    public let errorMessage: String?
    public let missingFields: [String]?
    public let skeleton: TripSkeletonDto?
    public let nextPossibleActions: [String]?

    public init(
        success: Bool,
        successMessage: String? = nil,
        errorMessage: String? = nil,
        missingFields: [String]? = nil,
        skeleton: TripSkeletonDto? = nil,
        nextPossibleActions: [String]? = nil
    ) {
        self.success = success
        self.successMessage = successMessage
        self.errorMessage = errorMessage
        self.missingFields = missingFields
        self.skeleton = skeleton
        self.nextPossibleActions = nextPossibleActions
    }

    enum CodingKeys: String, CodingKey {
        case success, successMessage, errorMessage, missingFields, skeleton, nextPossibleActions
        case successPascal = "Success"
        case successMessagePascal = "SuccessMessage"
        case errorMessagePascal = "ErrorMessage"
        case missingFieldsPascal = "MissingFields"
        case skeletonPascal = "Skeleton"
        case nextPossibleActionsPascal = "NextPossibleActions"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.success = try container.decodeIfPresent(Bool.self, forKey: .success)
            ?? container.decodeIfPresent(Bool.self, forKey: .successPascal)
            ?? false
        self.successMessage = try container.decodeIfPresent(String.self, forKey: .successMessage)
            ?? container.decodeIfPresent(String.self, forKey: .successMessagePascal)
        self.errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
            ?? container.decodeIfPresent(String.self, forKey: .errorMessagePascal)
        self.missingFields = try container.decodeIfPresent([String].self, forKey: .missingFields)
            ?? container.decodeIfPresent([String].self, forKey: .missingFieldsPascal)
        self.skeleton = try container.decodeIfPresent(TripSkeletonDto.self, forKey: .skeleton)
            ?? container.decodeIfPresent(TripSkeletonDto.self, forKey: .skeletonPascal)
        self.nextPossibleActions = try container.decodeIfPresent([String].self, forKey: .nextPossibleActions)
            ?? container.decodeIfPresent([String].self, forKey: .nextPossibleActionsPascal)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encodeIfPresent(successMessage, forKey: .successMessage)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
        try container.encodeIfPresent(missingFields, forKey: .missingFields)
        try container.encodeIfPresent(skeleton, forKey: .skeleton)
        try container.encodeIfPresent(nextPossibleActions, forKey: .nextPossibleActions)
    }
}
