import AVFoundation
import DesignSystem
import Domain
import SwiftUI
import VisionKit

/// Scan-Flow: Scan → Haptik → Lookup (Cache → OFF) → Ergebnis. Fängt fehlende
/// Kamera-Berechtigung und Geräte ohne `DataScannerViewController`-Unterstützung ab.
/// Kennt `FeatureLog` bewusst nicht – das Ergebnis wird über reine Domain-Typen
/// (`Food`/`String`) an den Composition Root zurückgereicht.
public struct ScannerView: View {
    private let foodCatalogRepository: any FoodCatalogRepository
    private let onFoodFound: (Food) -> Void
    private let onBarcodeNotFound: (String) -> Void
    private let onCancel: () -> Void

    @State private var cameraAuthorization = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var isLookingUp = false
    @State private var errorMessage: String?

    public init(
        foodCatalogRepository: any FoodCatalogRepository,
        onFoodFound: @escaping (Food) -> Void,
        onBarcodeNotFound: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.foodCatalogRepository = foodCatalogRepository
        self.onFoodFound = onFoodFound
        self.onBarcodeNotFound = onBarcodeNotFound
        self.onCancel = onCancel
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Scannen")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { onCancel() }
                    }
                }
                .onAppear { cameraAuthorization = AVCaptureDevice.authorizationStatus(for: .video) }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch cameraAuthorization {
        case .denied, .restricted:
            permissionDeniedView
        default:
            if DataScannerViewController.isSupported {
                scannerContent
            } else {
                ContentUnavailableView(
                    "Scannen nicht unterstützt",
                    systemImage: "barcode.viewfinder",
                    description: Text(
                        "Dieses Gerät unterstützt die Barcode-Erkennung nicht. Nutze stattdessen Suche oder Schnelleintrag."
                    )
                )
            }
        }
    }

    private var permissionDeniedView: some View {
        ContentUnavailableView {
            Label("Kamera-Zugriff benötigt", systemImage: "camera.fill")
        } description: {
            Text("Bitte erlaube den Kamera-Zugriff in den Einstellungen, um Barcodes zu scannen.")
        } actions: {
            Button("Einstellungen öffnen") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    private var scannerContent: some View {
        ZStack {
            DataScannerView(onScan: handleScan)
                .ignoresSafeArea()

            if isLookingUp {
                ProgressView()
                    .padding(Spacing.md)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if let errorMessage {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .font(TypographyToken.body)
                        .padding(Spacing.md)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.bottom, Spacing.xl)
                }
            }
        }
    }

    private func handleScan(barcode: String) {
        guard !isLookingUp else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        isLookingUp = true
        errorMessage = nil

        Task {
            do {
                if let food = try await foodCatalogRepository.food(barcode: barcode) {
                    onFoodFound(food)
                } else {
                    onBarcodeNotFound(barcode)
                }
            } catch {
                errorMessage = "Lookup fehlgeschlagen. Bitte erneut versuchen."
                isLookingUp = false
            }
        }
    }
}
