import SwiftUI
import Combine

@main
struct FlowTypeApp: App {
    @StateObject private var appModel = AppModel(services: FlowTypeServiceFactory.makeServices())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
        }
    }
}
