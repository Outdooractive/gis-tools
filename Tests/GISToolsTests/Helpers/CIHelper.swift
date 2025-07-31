import Foundation

struct CIHelper {

    static let isRunningInCI: Bool = {
        let env = ProcessInfo.processInfo.environment

        return env["CI"] != nil
            || env["GITHUB_ACTIONS"] != nil
    }()

}
