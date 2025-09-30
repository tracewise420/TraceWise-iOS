import SwiftUI

@available(iOS 14.0, macOS 11.0, *)
public struct ProductView: View {
    let product: Product
    
    public init(product: Product) {
        self.product = product
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(product.name)
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack {
                Text("GTIN:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(product.gtin)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            if let serial = product.serial {
                HStack {
                    Text("Serial:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(serial)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            if let description = product.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}