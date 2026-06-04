//
//  ComfortPreferencesView.swift
//  JackpotTrivia
//

import SwiftUI

struct ComfortPreferencesView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var profile = UserProfileStore.profile

    var body: some View {
        Form {
            Section {
                Picker("Age setting", selection: $profile.ageBand) {
                    ForEach(ProfileAgeBand.allCases) { band in
                        Text(band.displayName).tag(band)
                    }
                }
            } header: {
                Text("Profile")
            } footer: {
                Text("Mixed group uses the strictest family-safe filters for everyone in the room.")
            }

            Section {
                Toggle("Mature topics", isOn: $profile.matureTopicsEnabled)
                Toggle("Family-safe mode", isOn: $profile.familySafeMode)
                Toggle("Educational only", isOn: $profile.educationalOnly)
            } header: {
                Text("Content filters")
            } footer: {
                Text("Questions are filtered by these comfort preferences before each round.")
            }
        }
        .navigationTitle("Comfort & Content")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    UserProfileStore.profile = profile
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ComfortPreferencesView()
    }
}
