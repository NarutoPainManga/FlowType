import SwiftUI
import Combine

@main
struct FlowTypeApp: App {
    @StateObject private var appModel: AppModel

    init() {
        let environment = ProcessInfo.processInfo.environment
        let arguments = ProcessInfo.processInfo.arguments
        let isUITestMode = environment["FLOWTYPE_UI_TEST_MODE"] == "1" || arguments.contains("-FlowTypeUITestMode")
        let screenshotScenario = environment["FLOWTYPE_SCREENSHOT_SCENE"] ?? Self.launchArgumentValue("-FlowTypeScreenshotScene")

        if environment["FLOWTYPE_RESET_STATE"] == "1" || arguments.contains("-FlowTypeResetState") {
            AppModel.resetLocalState()
        }

        if environment["FLOWTYPE_SKIP_ONBOARDING"] == "1" || arguments.contains("-FlowTypeSkipOnboarding") {
            AppModel.seedForTesting(hasCompletedOnboarding: true)
        }

        let services = isUITestMode || environment["FLOWTYPE_USE_MOCK_SERVICES"] == "1" || arguments.contains("-FlowTypeUseMockServices")
            ? FlowTypeServices.mock()
            : FlowTypeServiceFactory.makeServices()

        let model = AppModel(services: services, shouldBootstrap: screenshotScenario == nil)
        if let screenshotScenario, !screenshotScenario.isEmpty {
            model.applyScreenshotScenario(screenshotScenario)
        }

        _appModel = StateObject(wrappedValue: model)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
        }
    }

    private static func launchArgumentValue(_ flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }

        return arguments[index + 1]
    }
}
