import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Murmur library")
            }
            .navigationTitle("Murmur")
        }
    }
}
