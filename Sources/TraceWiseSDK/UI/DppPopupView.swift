import SwiftUI

@available(iOS 14.0, macOS 11.0, *)
public struct DppPopupView: View {
    let dpp: DPP
    let onRepair: (() -> Void)?
    let onResell: (() -> Void)?
    let onFullDpp: (() -> Void)?
    @Binding var isPresented: Bool
    
    public init(
        dpp: DPP,
        isPresented: Binding<Bool>,
        onRepair: (() -> Void)? = nil,
        onResell: (() -> Void)? = nil,
        onFullDpp: (() -> Void)? = nil
    ) {
        self.dpp = dpp
        self._isPresented = isPresented
        self.onRepair = onRepair
        self.onResell = onResell
        self.onFullDpp = onFullDpp
    }
    
    public var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Digital Product Passport")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    InfoRow(label: "GTIN", value: dpp.gtin)
                    
                    if let serial = dpp.serial {
                        InfoRow(label: "Serial", value: serial)
                    }
                    
                    if let brand = dpp.claims["brand"]?.value as? String {
                        InfoRow(label: "Brand", value: brand)
                    }
                    
                    if let materials = dpp.claims["materials"]?.value as? String {
                        InfoRow(label: "Materials", value: materials)
                    }
                }
                
                if let tags = dpp.claims["tags"]?.value as? [String], !tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Simple VStack instead of LazyVGrid for compatibility
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if let onRepair = onRepair {
                        Button("Repair") {
                            onRepair()
                            isPresented = false
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    if let onResell = onResell {
                        Button("Resell") {
                            onResell()
                            isPresented = false
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    if let onFullDpp = onFullDpp {
                        Button("Full DPP") {
                            onFullDpp()
                            isPresented = false
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding()
            .navigationTitle("DPP")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
            #endif
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.body)
            
            Spacer()
        }
    }
}