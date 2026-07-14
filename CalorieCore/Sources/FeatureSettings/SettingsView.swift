import DesignSystem
import Domain
import SwiftUI

enum SettingsPushDestination: Hashable {
    case about
}

/// Die Gerichte-/Schnellauswahl-Screens leben in `FeatureMeals`; Features kennen einander nicht,
/// daher werden sie generisch als `@ViewBuilder`-Closures vom Composition Root injiziert.
public struct SettingsView<MealsDestination: View, QuickListDestination: View>: View {
    @State private var viewModel: SettingsViewModel
    @State private var dailyKcalText = ""
    @State private var proteinText = ""
    @State private var carbsText = ""
    @State private var fatText = ""

    private let mealsDestination: () -> MealsDestination
    private let quickListDestination: () -> QuickListDestination

    public init(
        goalsRepository: any GoalsRepository,
        widgetRefreshing: any WidgetRefreshing,
        @ViewBuilder mealsDestination: @escaping () -> MealsDestination,
        @ViewBuilder quickListDestination: @escaping () -> QuickListDestination
    ) {
        _viewModel = State(initialValue: SettingsViewModel(goalsRepository: goalsRepository, widgetRefreshing: widgetRefreshing))
        self.mealsDestination = mealsDestination
        self.quickListDestination = quickListDestination
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Einstellungen")
                .navigationDestination(for: SettingsPushDestination.self) { destination in
                    switch destination {
                    case .about: AboutView()
                    }
                }
                .task { await viewModel.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .empty:
            ContentUnavailableView("Keine Ziele gefunden", systemImage: "target")
        case let .error(message):
            ContentUnavailableView {
                Label("Fehler", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Erneut versuchen") { Task { await viewModel.load() } }
            }
        case let .loaded(goals):
            form(for: goals)
        }
    }

    private var mealsAndQuickListSection: some View {
        Section("Gerichte & Schnellauswahl") {
            NavigationLink {
                mealsDestination()
            } label: {
                Label("Gerichte", systemImage: "fork.knife")
            }
            .accessibilityIdentifier("settings.mealsLink")
            NavigationLink {
                quickListDestination()
            } label: {
                Label("Schnellauswahl", systemImage: "bolt")
            }
            .accessibilityIdentifier("settings.quickListLink")
        }
    }

    private func form(for goals: MacroGoals) -> some View {
        Form {
            Section("Tagesziel") {
                LabeledContent("kcal") {
                    TextField("kcal", text: $dailyKcalText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            Section("Makros (g)") {
                LabeledContent("Protein") {
                    TextField("g", text: $proteinText).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                }
                LabeledContent("Kohlenhydrate") {
                    TextField("g", text: $carbsText).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                }
                LabeledContent("Fett") {
                    TextField("g", text: $fatText).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                }
            }
            Section {
                Button("Speichern") {
                    Task {
                        await viewModel.save(
                            dailyKcal: Int(dailyKcalText) ?? goals.dailyKcal,
                            proteinGrams: Int(proteinText) ?? goals.proteinGrams,
                            carbsGrams: Int(carbsText) ?? goals.carbsGrams,
                            fatGrams: Int(fatText) ?? goals.fatGrams
                        )
                    }
                }
                Button("Auto-Vorschlag wiederherstellen") {
                    Task { await viewModel.restoreAutoSuggestion(dailyKcal: Int(dailyKcalText) ?? goals.dailyKcal) }
                }
            }
            mealsAndQuickListSection
            Section("Info") {
                NavigationLink("Über FoodReflect", value: SettingsPushDestination.about)
            }
        }
        .onAppear {
            dailyKcalText = String(goals.dailyKcal)
            proteinText = String(goals.proteinGrams)
            carbsText = String(goals.carbsGrams)
            fatText = String(goals.fatGrams)
        }
    }
}
