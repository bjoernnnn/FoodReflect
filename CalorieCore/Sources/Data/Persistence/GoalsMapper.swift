import Domain

enum GoalsMapper {
    static func toDomain(_ model: SDGoals) -> MacroGoals {
        MacroGoals(
            dailyKcal: model.dailyKcal,
            proteinGrams: model.proteinGrams,
            carbsGrams: model.carbsGrams,
            fatGrams: model.fatGrams,
            isCustomized: model.isCustomized
        )
    }

    static func toModel(_ goals: MacroGoals) -> SDGoals {
        let model = SDGoals()
        update(model, from: goals)
        return model
    }

    static func update(_ model: SDGoals, from goals: MacroGoals) {
        model.dailyKcal = goals.dailyKcal
        model.proteinGrams = goals.proteinGrams
        model.carbsGrams = goals.carbsGrams
        model.fatGrams = goals.fatGrams
        model.isCustomized = goals.isCustomized
    }
}
