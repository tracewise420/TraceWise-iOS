import SwiftUI

@available(iOS 14.0, macOS 11.0, *)
public struct DPPView: View {
    let dpp: DPP
    
    public init(dpp: DPP) {
        self.dpp = dpp
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dpp.claims["name"]?.value as? String ?? "Digital Product Passport")
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack {
                Text("GTIN:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(dpp.gtin)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            if let serial = dpp.serial {
                HStack {
                    Text("Serial:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(serial)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            HStack {
                Text("Source:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(dpp.source)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}