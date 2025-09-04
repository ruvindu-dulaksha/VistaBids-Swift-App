import SwiftUI

struct PropertyRowView: View {
    let property: Property
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: property.images.first ?? "")) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.2))
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(property.title)
                    .font(.headline)
                Text(property.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(property.formattedPrice)
                    .font(.subheadline)
                    .foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 4)
    }
}