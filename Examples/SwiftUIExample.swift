import SwiftUI
import TraceWiseSDK

struct ContentView: View {
    @StateObject private var viewModel = ProductViewModel()
    @State private var qrCodeURL = "https://id.gs1.org/01/04012345678905/21/SN123456"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("QR Code URL", text: $qrCodeURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Scan Product") {
                    Task { await viewModel.scanProduct(url: qrCodeURL) }
                }
                .disabled(viewModel.isLoading)
                
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if let product = viewModel.product {
                    ProductInfoView(product: product)
                } else if let error = viewModel.error {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("TraceWise SDK")
        }
    }
}

struct ProductInfoView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Product Information")
                .font(.headline)
            
            InfoRow(label: "Name", value: product.name)
            InfoRow(label: "GTIN", value: product.gtin)
            if let serial = product.serial {
                InfoRow(label: "Serial", value: serial)
            }
            if let manufacturer = product.manufacturer {
                InfoRow(label: "Manufacturer", value: manufacturer)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

@MainActor
class ProductViewModel: ObservableObject {
    @Published var product: Product?
    @Published var error: TraceWiseError?
    @Published var isLoading = false
    
    private let sdk: TraceWiseSDK
    
    init() {
        let config = SDKConfig(
            baseURL: "https://trace-wise.eu/api",
            enableLogging: true
        )
        self.sdk = TraceWiseSDK(config: config)
    }
    
    func scanProduct(url: String) async {
        isLoading = true
        error = nil
        product = nil
        
        do {
            // Parse Digital Link
            let ids = try sdk.parseDigitalLink(url)
            
            // Get product (exact Trello task signature)
            let product = try await sdk.getProduct(gtin: ids.gtin, serial: ids.serial)
            self.product = product
            
            // Register product to user (exact Trello task signature)
            try await sdk.registerProduct(userId: "demo-user", product: product)
            
            // Add lifecycle event (exact Trello task signature)
            let event = LifecycleEvent(
                gtin: ids.gtin,
                serial: ids.serial,
                bizStep: "scanned",
                timestamp: ISO8601DateFormatter().string(from: Date()),
                details: ["app": "iOS Demo"]
            )
            try await sdk.addLifecycleEvent(event: event)
            
        } catch {
            self.error = error as? TraceWiseError ?? TraceWiseError.unknown(error)
        }
        
        isLoading = false
    }
}

#Preview {
    ContentView()
}