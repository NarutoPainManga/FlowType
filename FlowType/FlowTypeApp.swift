import SwiftUI
import Combine

@main
struct FlowTypeApp: App {
    @StateObject private var appModel: AppModel

    init() {
        let environment = ProcessInfo.processInfo.environment
        let isUITestMode = environment["FLOWTYPE_UI_TEST_MODE"] == "1"

        if environment["FLOWTYPE_RESET_STATE"] == "1" {
            AppModel.resetLocalState()
        }

        if environment["FLOWTYPE_SKIP_ONBOARDING"] == "1" {
            AppModel.seedForTesting(hasCompletedOnboarding: true)
        }

        let services = isUITestMode || environment["FLOWTYPE_USE_MOCK_SERVICES"] == "1"
            ? FlowTypeServices.mock()
            : FlowTypeServiceFactory.makeServices()

        _appModel = StateObject(wrappedValue: AppModel(services: services))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
        }
    }
}
