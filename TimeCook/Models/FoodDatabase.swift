import Foundation

// MARK: - Category

enum FoodCategory: String, CaseIterable, Identifiable {
    case viandes    = "Viandes"
    case poissons   = "Poissons & Fruits de mer"
    case legumes    = "Légumes"
    case feculents  = "Féculents"
    case oeufs      = "Œufs"
    case snacks     = "Snacks & Surgelés"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .viandes:   return "🥩"
        case .poissons:  return "🐟"
        case .legumes:   return "🥦"
        case .feculents: return "🍚"
        case .oeufs:     return "🥚"
        case .snacks:    return "🍟"
        }
    }
}

// MARK: - FoodItem

struct FoodItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: FoodCategory
    let modeConfigs: [ModeConfig]

    init(name: String, category: FoodCategory, modes: [ModeConfig]) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.modeConfigs = modes
    }

    func config(for mode: CookingModeType) -> ModeConfig? {
        modeConfigs.first { $0.mode == mode }
    }

    var availableModes: [CookingModeType] {
        modeConfigs.map { $0.mode }
    }

    static func == (lhs: FoodItem, rhs: FoodItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Database

class FoodDatabase {
    static let shared = FoodDatabase()

    let items: [FoodItem]

    private init() {
        items = FoodDatabase.buildItems()
    }

    // Grouped by category for UI display
    func items(for category: FoodCategory) -> [FoodItem] {
        items.filter { $0.category == category }
    }

    // MARK: - Builder

    // swiftlint:disable function_body_length
    private static func buildItems() -> [FoodItem] {

        // ─────────────────── HELPERS ────────────────────
        // panSear with levels, no temp control
        func poele(levels: [CookingLevel]) -> ModeConfig {
            ModeConfig(mode: .panSear, levels: levels)
        }
        func poeleSimple(_ seconds: Int) -> ModeConfig {
            ModeConfig(mode: .panSear, baseTime: seconds)
        }
        func airFryer(levels: [CookingLevel]? = nil, base: Int = 0, temp: Int = 180,
                      minT: Int = 160, maxT: Int = 210,
                      weight: Int? = nil, minW: Int? = nil, maxW: Int? = nil,
                      step: Int = 50, sensitivity: Double = 0.5) -> ModeConfig {
            ModeConfig(mode: .airFryer, levels: levels, baseTime: base,
                       defaultTemp: temp, minTemp: minT, maxTemp: maxT, tempSensitivity: sensitivity,
                       supportsWeight: weight != nil, defaultWeight: weight,
                       minWeight: minW, maxWeight: maxW, weightStep: step)
        }
        func four(levels: [CookingLevel]? = nil, base: Int = 0, temp: Int = 180,
                  minT: Int = 140, maxT: Int = 240,
                  weight: Int? = nil, minW: Int? = nil, maxW: Int? = nil,
                  step: Int = 50, sensitivity: Double = 0.55) -> ModeConfig {
            ModeConfig(mode: .oven, levels: levels, baseTime: base,
                       defaultTemp: temp, minTemp: minT, maxTemp: maxT, tempSensitivity: sensitivity,
                       supportsWeight: weight != nil, defaultWeight: weight,
                       minWeight: minW, maxWeight: maxW, weightStep: step)
        }
        func grill(_ levels: [CookingLevel]? = nil, base: Int = 0) -> ModeConfig {
            ModeConfig(mode: .grill, levels: levels, baseTime: base)
        }
        func plancha(_ seconds: Int) -> ModeConfig {
            ModeConfig(mode: .plancha, baseTime: seconds)
        }
        func vapeur(base: Int) -> ModeConfig {
            ModeConfig(mode: .steam, baseTime: base)
        }
        func bouillante(levels: [CookingLevel]? = nil, base: Int = 0) -> ModeConfig {
            ModeConfig(mode: .boiling, levels: levels, baseTime: base)
        }
        func microOndes(base: Int) -> ModeConfig {
            ModeConfig(mode: .microwave, baseTime: base)
        }

        // ─────────────────── VIANDES ────────────────────

        let steakLevels = [
            CookingLevel(name: "Bleu", baseTime: 180),
            CookingLevel(name: "Saignant", baseTime: 300),
            CookingLevel(name: "À point", baseTime: 480),
            CookingLevel(name: "Bien cuit", baseTime: 660),
        ]
        let steakLevelsAF = [
            CookingLevel(name: "Bleu", baseTime: 360),
            CookingLevel(name: "Saignant", baseTime: 480),
            CookingLevel(name: "À point", baseTime: 600),
            CookingLevel(name: "Bien cuit", baseTime: 780),
        ]
        let steakLevelsFour = [
            CookingLevel(name: "Saignant", baseTime: 660),
            CookingLevel(name: "À point", baseTime: 900),
            CookingLevel(name: "Bien cuit", baseTime: 1200),
        ]

        let agneauLevels = [
            CookingLevel(name: "Rosé", baseTime: 240),
            CookingLevel(name: "À point", baseTime: 360),
            CookingLevel(name: "Bien cuit", baseTime: 480),
        ]

        let thonLevels = [
            CookingLevel(name: "Saignant", baseTime: 120),
            CookingLevel(name: "À point", baseTime: 240),
            CookingLevel(name: "Bien cuit", baseTime: 360),
        ]

        return [

            // ── Steak ──────────────────────────────────────────
            FoodItem(name: "Steak", category: .viandes, modes: [
                poele(levels: steakLevels),
                airFryer(levels: steakLevelsAF, temp: 200, minT: 170, maxT: 220,
                         weight: 200, minW: 100, maxW: 500),
                four(levels: steakLevelsFour, temp: 180, minT: 160, maxT: 220,
                     weight: 200, minW: 100, maxW: 500),
                grill(steakLevels),
                plancha(360),
            ]),

            // ── Burger ────────────────────────────────────────
            FoodItem(name: "Burger (steak haché)", category: .viandes, modes: [
                poele(levels: [
                    CookingLevel(name: "Rosé", baseTime: 300),
                    CookingLevel(name: "Bien cuit", baseTime: 480),
                ]),
                airFryer(base: 480, temp: 180, minT: 160, maxT: 200,
                         weight: 150, minW: 100, maxW: 250, step: 25),
                grill(nil, base: 420),
            ]),

            // ── Poulet filet ───────────────────────────────────
            FoodItem(name: "Poulet (filet)", category: .viandes, modes: [
                poeleSimple(720),
                airFryer(base: 840, temp: 180, minT: 160, maxT: 200,
                         weight: 150, minW: 80, maxW: 300, step: 25),
                four(base: 1200, temp: 180, minT: 160, maxT: 200,
                     weight: 150, minW: 80, maxW: 300, step: 25),
                plancha(720),
                grill(nil, base: 900),
            ]),

            // ── Cuisse de poulet ───────────────────────────────
            FoodItem(name: "Cuisse de poulet", category: .viandes, modes: [
                airFryer(base: 1500, temp: 180, minT: 160, maxT: 200,
                         weight: 250, minW: 150, maxW: 400, step: 50),
                four(base: 2100, temp: 180, minT: 160, maxT: 200,
                     weight: 250, minW: 150, maxW: 400, step: 50, sensitivity: 0.6),
                grill(nil, base: 1800),
            ]),

            // ── Côte de porc ───────────────────────────────────
            FoodItem(name: "Côte de porc", category: .viandes, modes: [
                poeleSimple(600),
                airFryer(base: 720, temp: 180, minT: 160, maxT: 200,
                         weight: 180, minW: 100, maxW: 350, step: 25),
                grill(nil, base: 660),
                four(base: 1200, temp: 180, weight: 180, minW: 100, maxW: 350, step: 25),
            ]),

            // ── Filet mignon de porc ───────────────────────────
            FoodItem(name: "Filet mignon de porc", category: .viandes, modes: [
                airFryer(base: 1200, temp: 180, minT: 160, maxT: 200,
                         weight: 300, minW: 200, maxW: 500, step: 50, sensitivity: 0.6),
                four(base: 1500, temp: 180, minT: 160, maxT: 200,
                     weight: 300, minW: 200, maxW: 500, step: 50, sensitivity: 0.6),
                poeleSimple(900),
            ]),

            // ── Agneau ────────────────────────────────────────
            FoodItem(name: "Agneau (côtelettes)", category: .viandes, modes: [
                poele(levels: agneauLevels),
                airFryer(levels: agneauLevels.map { CookingLevel(name: $0.name, baseTime: $0.baseTime + 120) },
                         temp: 190, minT: 170, maxT: 210,
                         weight: 150, minW: 80, maxW: 300, step: 25),
                grill(agneauLevels),
            ]),

            // ── Saucisse ──────────────────────────────────────
            FoodItem(name: "Saucisse", category: .viandes, modes: [
                poeleSimple(480),
                airFryer(base: 540, temp: 180, minT: 160, maxT: 200,
                         weight: 200, minW: 100, maxW: 400, step: 50),
                grill(nil, base: 480),
            ]),

            // ── Bacon ─────────────────────────────────────────
            FoodItem(name: "Bacon", category: .viandes, modes: [
                poeleSimple(240),
                airFryer(base: 360, temp: 180, minT: 160, maxT: 200,
                         weight: 100, minW: 50, maxW: 200, step: 25),
            ]),

            // ─────────────────── POISSONS ───────────────────

            // ── Saumon ────────────────────────────────────────
            FoodItem(name: "Saumon", category: .poissons, modes: [
                poele(levels: [
                    CookingLevel(name: "Rosé", baseTime: 300),
                    CookingLevel(name: "Bien cuit", baseTime: 420),
                ]),
                airFryer(levels: [
                    CookingLevel(name: "Rosé", baseTime: 480),
                    CookingLevel(name: "Bien cuit", baseTime: 600),
                ], temp: 180, minT: 160, maxT: 200,
                weight: 200, minW: 100, maxW: 400, step: 50),
                four(base: 780, temp: 180, minT: 160, maxT: 200,
                     weight: 200, minW: 100, maxW: 400, step: 50),
                vapeur(base: 600),
            ]),

            // ── Cabillaud ─────────────────────────────────────
            FoodItem(name: "Cabillaud", category: .poissons, modes: [
                vapeur(base: 600),
                airFryer(base: 600, temp: 180, minT: 160, maxT: 200,
                         weight: 200, minW: 100, maxW: 400, step: 50),
                four(base: 900, temp: 180, minT: 160, maxT: 200,
                     weight: 200, minW: 100, maxW: 400, step: 50),
                poeleSimple(360),
            ]),

            // ── Thon ──────────────────────────────────────────
            FoodItem(name: "Thon (steak)", category: .poissons, modes: [
                poele(levels: thonLevels),
                grill(thonLevels),
                airFryer(levels: [
                    CookingLevel(name: "Saignant", baseTime: 240),
                    CookingLevel(name: "À point", baseTime: 360),
                ], temp: 200, minT: 180, maxT: 220,
                weight: 150, minW: 100, maxW: 300, step: 25),
            ]),

            // ── Poisson filet ─────────────────────────────────
            FoodItem(name: "Poisson (filet)", category: .poissons, modes: [
                poeleSimple(360),
                airFryer(base: 480, temp: 180, minT: 160, maxT: 200,
                         weight: 150, minW: 80, maxW: 300, step: 25),
                four(base: 720, temp: 180, minT: 160, maxT: 200,
                     weight: 150, minW: 80, maxW: 300, step: 25),
                vapeur(base: 600),
            ]),

            // ── Crevettes ─────────────────────────────────────
            FoodItem(name: "Crevettes", category: .poissons, modes: [
                poeleSimple(240),
                airFryer(base: 360, temp: 180, minT: 160, maxT: 200,
                         weight: 200, minW: 100, maxW: 400, step: 50),
                grill(nil, base: 300),
            ]),

            // ── Moules ────────────────────────────────────────
            FoodItem(name: "Moules", category: .poissons, modes: [
                poeleSimple(480),
                bouillante(base: 420),
            ]),

            // ─────────────────── LÉGUMES ────────────────────

            // ── Brocoli ───────────────────────────────────────
            FoodItem(name: "Brocoli", category: .legumes, modes: [
                vapeur(base: 300),
                bouillante(base: 300),
                airFryer(base: 480, temp: 180, minT: 160, maxT: 200,
                         weight: 200, minW: 100, maxW: 400, step: 50),
            ]),

            // ── Chou-fleur ────────────────────────────────────
            FoodItem(name: "Chou-fleur", category: .legumes, modes: [
                vapeur(base: 480),
                bouillante(base: 420),
                airFryer(base: 600, temp: 180, minT: 160, maxT: 200,
                         weight: 200, minW: 100, maxW: 400, step: 50),
            ]),

            // ── Carottes ─────────────────────────────────────
            FoodItem(name: "Carottes", category: .legumes, modes: [
                vapeur(base: 720),
                bouillante(base: 600),
                airFryer(base: 900, temp: 180, minT: 160, maxT: 200,
                         weight: 200, minW: 100, maxW: 400, step: 50),
            ]),

            // ── Courgettes ────────────────────────────────────
            FoodItem(name: "Courgettes", category: .legumes, modes: [
                poeleSimple(300),
                airFryer(base: 480, temp: 180, minT: 160, maxT: 200,
                         weight: 200, minW: 100, maxW: 400, step: 50),
                four(base: 1200, temp: 180, weight: 200, minW: 100, maxW: 400, step: 50),
                grill(nil, base: 360),
            ]),

            // ── Asperges ──────────────────────────────────────
            FoodItem(name: "Asperges", category: .legumes, modes: [
                vapeur(base: 480),
                airFryer(base: 480, temp: 180, minT: 160, maxT: 200,
                         weight: 200, minW: 100, maxW: 300, step: 50),
                four(base: 900, temp: 180, weight: 200, minW: 100, maxW: 300, step: 50),
                poeleSimple(300),
            ]),

            // ── Aubergines ────────────────────────────────────
            FoodItem(name: "Aubergines", category: .legumes, modes: [
                poeleSimple(480),
                airFryer(base: 600, temp: 180, minT: 160, maxT: 200,
                         weight: 250, minW: 100, maxW: 400, step: 50),
                four(base: 1500, temp: 180, weight: 250, minW: 100, maxW: 400, step: 50),
                grill(nil, base: 480),
            ]),

            // ── Poivrons ──────────────────────────────────────
            FoodItem(name: "Poivrons", category: .legumes, modes: [
                poeleSimple(480),
                airFryer(base: 600, temp: 180, minT: 160, maxT: 200,
                         weight: 200, minW: 100, maxW: 400, step: 50),
                four(base: 1500, temp: 200, weight: 200, minW: 100, maxW: 400, step: 50),
            ]),

            // ── Champignons ───────────────────────────────────
            FoodItem(name: "Champignons", category: .legumes, modes: [
                poeleSimple(300),
                airFryer(base: 360, temp: 180, minT: 160, maxT: 200,
                         weight: 200, minW: 100, maxW: 400, step: 50),
            ]),

            // ── Pommes de terre (entières) ────────────────────
            FoodItem(name: "Pommes de terre", category: .legumes, modes: [
                airFryer(base: 2100, temp: 180, minT: 160, maxT: 200,
                         weight: 200, minW: 100, maxW: 350, step: 50, sensitivity: 0.6),
                four(base: 2700, temp: 200, minT: 180, maxT: 230,
                     weight: 200, minW: 100, maxW: 350, step: 50, sensitivity: 0.65),
                microOndes(base: 480),
                bouillante(base: 1200),
            ]),

            // ── Patates douces ────────────────────────────────
            FoodItem(name: "Patates douces", category: .legumes, modes: [
                airFryer(base: 1800, temp: 180, minT: 160, maxT: 200,
                         weight: 200, minW: 100, maxW: 350, step: 50, sensitivity: 0.6),
                four(base: 2400, temp: 200, minT: 180, maxT: 220,
                     weight: 200, minW: 100, maxW: 350, step: 50, sensitivity: 0.65),
                microOndes(base: 360),
            ]),

            // ── Haricots verts ────────────────────────────────
            FoodItem(name: "Haricots verts", category: .legumes, modes: [
                vapeur(base: 420),
                bouillante(base: 360),
                airFryer(base: 480, temp: 180, minT: 160, maxT: 200,
                         weight: 200, minW: 100, maxW: 400, step: 50),
            ]),

            // ── Épinards ──────────────────────────────────────
            FoodItem(name: "Épinards", category: .legumes, modes: [
                poeleSimple(180),
                vapeur(base: 240),
                airFryer(base: 300, temp: 160, minT: 140, maxT: 190,
                         weight: 150, minW: 80, maxW: 300, step: 25),
            ]),

            // ── Maïs ──────────────────────────────────────────
            FoodItem(name: "Maïs (épi)", category: .legumes, modes: [
                bouillante(base: 480),
                airFryer(base: 720, temp: 190, minT: 170, maxT: 210),
                microOndes(base: 300),
                grill(nil, base: 600),
            ]),

            // ─────────────────── FÉCULENTS ──────────────────

            FoodItem(name: "Riz blanc", category: .feculents, modes: [
                bouillante(base: 720),
                microOndes(base: 900),
            ]),

            FoodItem(name: "Pâtes", category: .feculents, modes: [
                bouillante(levels: [
                    CookingLevel(name: "Al dente", baseTime: 480),
                    CookingLevel(name: "Bien cuites", baseTime: 600),
                ]),
            ]),

            FoodItem(name: "Quinoa", category: .feculents, modes: [
                bouillante(base: 900),
            ]),

            FoodItem(name: "Semoule (couscous)", category: .feculents, modes: [
                bouillante(base: 300),
                microOndes(base: 180),
            ]),

            FoodItem(name: "Lentilles", category: .feculents, modes: [
                bouillante(base: 1200),
            ]),

            FoodItem(name: "Gnocchis", category: .feculents, modes: [
                bouillante(base: 180),
                poeleSimple(300),
                airFryer(base: 540, temp: 180, minT: 160, maxT: 200,
                         weight: 250, minW: 100, maxW: 500, step: 50),
            ]),

            // ─────────────────── ŒUFS ───────────────────────

            FoodItem(name: "Œuf", category: .oeufs, modes: [
                bouillante(levels: [
                    CookingLevel(name: "Mollet", baseTime: 360),
                    CookingLevel(name: "Coulant", baseTime: 420),
                    CookingLevel(name: "Dur", baseTime: 600),
                ]),
                airFryer(levels: [
                    CookingLevel(name: "Mollet", baseTime: 600),
                    CookingLevel(name: "Dur", baseTime: 900),
                ], temp: 150, minT: 130, maxT: 170),
            ]),

            FoodItem(name: "Omelette", category: .oeufs, modes: [
                poeleSimple(240),
                airFryer(base: 420, temp: 160, minT: 140, maxT: 180),
            ]),

            FoodItem(name: "Œufs brouillés", category: .oeufs, modes: [
                poeleSimple(180),
                microOndes(base: 120),
            ]),

            // ─────────────────── SNACKS & SURGELÉS ──────────

            FoodItem(name: "Nuggets de poulet", category: .snacks, modes: [
                airFryer(base: 720, temp: 180, minT: 160, maxT: 200,
                         weight: 200, minW: 100, maxW: 400, step: 50, sensitivity: 0.7),
                four(base: 1080, temp: 200, minT: 180, maxT: 220,
                     weight: 200, minW: 100, maxW: 400, step: 50, sensitivity: 0.7),
                poeleSimple(480),
            ]),

            FoodItem(name: "Frites (fraîches)", category: .snacks, modes: [
                airFryer(base: 1320, temp: 180, minT: 160, maxT: 210,
                         weight: 300, minW: 150, maxW: 600, step: 50, sensitivity: 0.7),
                four(base: 1800, temp: 220, minT: 200, maxT: 240,
                     weight: 300, minW: 150, maxW: 600, step: 50, sensitivity: 0.7),
            ]),

            FoodItem(name: "Frites (surgelées)", category: .snacks, modes: [
                airFryer(base: 900, temp: 180, minT: 160, maxT: 210,
                         weight: 300, minW: 150, maxW: 600, step: 50, sensitivity: 0.7),
                four(base: 1200, temp: 220, minT: 200, maxT: 240,
                     weight: 300, minW: 150, maxW: 600, step: 50, sensitivity: 0.7),
            ]),

            FoodItem(name: "Nems / Spring rolls", category: .snacks, modes: [
                airFryer(base: 540, temp: 180, minT: 160, maxT: 200,
                         weight: 200, minW: 100, maxW: 400, step: 50),
                four(base: 900, temp: 200, minT: 180, maxT: 220,
                     weight: 200, minW: 100, maxW: 400, step: 50),
                poeleSimple(480),
            ]),

            FoodItem(name: "Samosas", category: .snacks, modes: [
                airFryer(base: 540, temp: 180, minT: 160, maxT: 200),
                four(base: 900, temp: 200, minT: 180, maxT: 220),
                poeleSimple(480),
            ]),

            FoodItem(name: "Mozzarella sticks", category: .snacks, modes: [
                airFryer(base: 420, temp: 180, minT: 160, maxT: 200,
                         weight: 150, minW: 100, maxW: 300, step: 25),
                four(base: 720, temp: 200, minT: 180, maxT: 220,
                     weight: 150, minW: 100, maxW: 300, step: 25),
            ]),

            FoodItem(name: "Onion rings", category: .snacks, modes: [
                airFryer(base: 540, temp: 180, minT: 160, maxT: 200,
                         weight: 200, minW: 100, maxW: 400, step: 50),
                four(base: 840, temp: 200, weight: 200, minW: 100, maxW: 400, step: 50),
            ]),

            FoodItem(name: "Pizza (surgelée)", category: .snacks, modes: [
                four(base: 900, temp: 220, minT: 200, maxT: 240, sensitivity: 0.65),
                airFryer(base: 720, temp: 190, minT: 170, maxT: 210, sensitivity: 0.65),
            ]),

            FoodItem(name: "Croissants", category: .snacks, modes: [
                four(base: 720, temp: 180, minT: 160, maxT: 200),
                airFryer(base: 480, temp: 160, minT: 140, maxT: 180),
            ]),
        ]
    }
}
