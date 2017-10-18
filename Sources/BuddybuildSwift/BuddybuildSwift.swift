import Foundation
import Files

public enum Error: Swift.Error {
    case missingKey(String)
    case invalidEnv
}

typealias EnvironmentConfiguration = [String: String]
struct Environment {

    let config: EnvironmentConfiguration

    func get(_ key: String) throws -> String {
        guard let v = config[key] else {
            throw Error.missingKey(key)
        }

        return v
    }

    func folder(_ key: String) throws -> Folder {
        return try Folder(path: get(key))
    }
}

public struct Buddybuild {
    public enum Trigger: String {
        case webhook
        case pullRequestUpdate = "webhook_pull_request_update"
        case ui = "ui_triggered"
        case scheduler
        case rebuild = "rebuild_of_commit"
        case api = "api_triggered"
    }

    struct IOS {
        let IPA: File?
        let appStoreIPA: File?
        let testDir: Folder?
        let scheme: String

        init(env: Environment) throws {
            self.IPA = try? File(path: env.get("IPA_PATH"))
            self.appStoreIPA = try? File(path: env.get("APP_STORE_IPA_PATH"))
            self.testDir = try? Folder(path: env.get("TEST_DIR"))
            self.scheme = try env.get("SCHEME")
        }
    }

    struct Android {
        let APKs: Folder
        let variants: [String] // TODO: CHECK THIS
        let home: Folder
        let NDKHome: Folder

        init(env: Environment) throws {
            self.APKs = try Folder(path: env.get("APKS_DIR"))
            self.variants = [try env.get("VARIANTS")]
            self.home = try env.folder("ANDROID_HOME")
            self.NDKHome = try env.folder("ANDROID_NDK_HOME")
        }
    }

    struct Build {
        let buildNumber: Int
        let buildId: String
        let appId: String
        let branch: String
        let baseBranch: String?
        let repoSlug: String
        let pullRequestId: Int?
        let workspace: Folder
        let secureFiles: Folder
        let triggeredBy: Trigger

        init(env: Environment) throws {
            let f = NumberFormatter()
            guard let buildNumber = f.number(from: try env.get("BUILD_NUMBER"))?.intValue else {
                throw Error.invalidEnv
            }
            self.buildNumber = buildNumber

            self.buildId = try env.get("BUILD_ID")
            self.appId = try env.get("APP_ID")
            self.branch = try env.get("BRANCH")
            if let baseBranch = try? env.get("BASE_BRANCH"), !baseBranch.isEmpty {
                self.baseBranch = baseBranch
            } else {
                self.baseBranch = nil
            }

            self.repoSlug = try env.get("REPO_SLUG")

            guard let pr = try? env.get("PULL_REQUEST"), let pullRequest = f.number(from: pr)?.intValue else {
                throw Error.invalidEnv
            }
            self.pullRequestId = pullRequest

            self.workspace = try Folder(path: env.get("WORKSPACE"))
            self.secureFiles = try Folder(path: env.get("SECURE_FILES"))
            guard let trigger = (try? env.get("TRIGGERED_BY")).flatMap(Trigger.init) else {
                throw Error.invalidEnv
            }

            self.triggeredBy = trigger
        }
    }

    static let build: Build = {
        do {
            return try Build(env: Environment(config: ProcessInfo.processInfo.environment))
        } catch {
            fatalError("Unable to retrieve informations about the build, are you sure it's a Buddybuild custom script?")
        }
    }()

    static let ios: IOS? = {
        return try? IOS(env: Environment(config: ProcessInfo.processInfo.environment))
    }()

    static let android: Android? = {
        return try? Android(env: Environment(config: ProcessInfo.processInfo.environment))
    }()
}
