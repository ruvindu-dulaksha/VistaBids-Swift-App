import SwiftUI
import Firebase

struct ProfileView: View {
    @EnvironmentObject private var authService: FirebaseAuthService
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let user = authService.currentUser {
                        HStack {
                            AsyncImage(url: user.photoURL) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text(user.displayName ?? "User")
                                    .font(.headline)
                                Text(user.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section("Account") {
                    NavigationLink("Settings") {
                        SettingsView()
                    }
                    
                    Button(role: .destructive) {
                        try? authService.signOut()
                    } label: {
                        Text("Sign Out")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(FirebaseAuthService())
}