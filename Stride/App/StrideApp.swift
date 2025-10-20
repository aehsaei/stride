import SwiftUI

@main
struct StrideApp: App {
    init() {
        // Configure audio session for background playback
        MetronomeEngine.configureAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            SetupView()
        }
    }
}
