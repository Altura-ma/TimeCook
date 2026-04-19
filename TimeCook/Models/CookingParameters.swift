import Foundation

// MARK: - Cooking Mode

enum CookingModeType: String, CaseIterable, Identifiable, Hashable, Codable {
    case panSear    = "Poêle"
    case airFryer   = "Air Fryer"
    case oven       = "Four"
    case grill      = "Grill / BBQ"
    case plancha    = "Plancha"
    case steam      = "Vapeur"
    case boiling    = "Eau bouillante"
    case microwave  = "Micro-ondes"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .panSear:   return "flame.fill"
        case .airFryer:  return "wind"
        case .oven:      return "square.grid.3x3.fill"
        case .grill:     return "smoke.fill"
        case .plancha:   return "rectangle.fill"
        case .steam:     return "cloud.fill"
        case .boiling:   return "drop.fill"
        case .microwave: return "bolt.circle.fill"
        }
    }
}

// MARK: - Cooking Level (doneness)

struct CookingLevel: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let baseTime: Int  // seconds at reference temp/weight

    init(name: String, baseTime: Int) {
        self.id = UUID()
        self.name = name
        self.baseTime = baseTime
    }

    static func == (lhs: CookingLevel, rhs: CookingLevel) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Mode Configuration

struct ModeConfig: Identifiable, Hashable {
    let id: UUID
    let mode: CookingModeType

    // Doneness levels (nil = no choice, single time)
    let levels: [CookingLevel]?
    let baseTime: Int  // seconds when no levels, at reference settings

    // Temperature
    let defaultTemp: Int?      // °C  (nil = temperature doesn't apply, e.g. boiling)
    let minTemp: Int?
    let maxTemp: Int?
    // Exponent for temperature sensitivity: higher = more impact
    // thin foods ~0.4, thick foods/pastry ~0.6, snacks ~0.7
    let tempSensitivity: Double

    // Weight (portion)
    let supportsWeight: Bool
    let defaultWeight: Int?    // grams reference
    let minWeight: Int?
    let maxWeight: Int?
    let weightStep: Int        // stepper increment

    init(
        mode: CookingModeType,
        levels: [CookingLevel]? = nil,
        baseTime: Int = 0,
        defaultTemp: Int? = nil,
        minTemp: Int? = nil,
        maxTemp: Int? = nil,
        tempSensitivity: Double = 0.5,
        supportsWeight: Bool = false,
        defaultWeight: Int? = nil,
        minWeight: Int? = nil,
        maxWeight: Int? = nil,
        weightStep: Int = 50
    ) {
        self.id = UUID()
        self.mode = mode
        self.levels = levels
        self.baseTime = baseTime
        self.defaultTemp = defaultTemp
        self.minTemp = minTemp
        self.maxTemp = maxTemp
        self.tempSensitivity = tempSensitivity
        self.supportsWeight = supportsWeight
        self.defaultWeight = defaultWeight
        self.minWeight = minWeight
        self.maxWeight = maxWeight
        self.weightStep = weightStep
    }

    // MARK: Time calculation
    // Higher temp → shorter time (power law: t_new = t_ref × (T_ref/T_new)^exponent)
    // More weight → longer time (square root: t_new = t_ref × √(w_new/w_ref))
    func computeTime(level: CookingLevel?, temp: Int?, weight: Int?) -> Int {
        var time = Double(level?.baseTime ?? baseTime)

        if let t = temp, let tRef = defaultTemp, tRef > 0, t != tRef {
            time *= pow(Double(tRef) / Double(t), tempSensitivity)
        }

        if supportsWeight, let w = weight, let wRef = defaultWeight, wRef > 0, w != wRef {
            time *= pow(Double(w) / Double(wRef), 0.5)
        }

        return max(30, Int(time.rounded()))
    }

    // Human-readable summary of adjustable parameters
    func parameterSummary(temp: Int?, weight: Int?) -> String {
        var parts: [String] = []
        if let t = temp ?? defaultTemp { parts.append("\(t)°C") }
        if supportsWeight, let w = weight ?? defaultWeight { parts.append("\(w) g") }
        return parts.joined(separator: " · ")
    }

    static func == (lhs: ModeConfig, rhs: ModeConfig) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
