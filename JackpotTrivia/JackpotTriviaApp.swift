//
//  JackpotTriviaApp.swift
//  JackpotTrivia
//
//  Created by Cole Cobb on 5/20/26.
//

import SwiftUI

@main
struct JackpotTriviaApp: App {
    @StateObject private var authManager = AuthManager.shared

    init() {
        AccessControlStore.loadIntoAccessControl()
    }

    var body: some Scene {
        WindowGroup {
            RootContentView()
                .preferredColorScheme(.dark)
                .environmentObject(authManager)
                .task {
                    await BackendEnvironment.bootstrap()
                }
                .onOpenURL { url in
                    _ = ChallengeService.handleIncomingURL(url)
                }
        }
    }
}
