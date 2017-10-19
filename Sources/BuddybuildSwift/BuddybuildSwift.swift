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
        guard let v = config["BUDDYBUILD_\(key)"] else {
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

    public struct IOS {
        public let IPA: File?
        public let appStoreIPA: File?
        public let testDir: Folder?
        public let scheme: String

        init(env: Environment) throws {
            self.IPA = try? File(path: env.get("IPA_PATH"))
            self.appStoreIPA = try? File(path: env.get("APP_STORE_IPA_PATH"))
            self.testDir = try? Folder(path: env.get("TEST_DIR"))
            self.scheme = try env.get("SCHEME")
        }
    }

    public struct Android {
        public let APKs: Folder
        public let variants: [String] // TODO: CHECK THIS
        public let home: Folder
        public let NDKHome: Folder

        init(env: Environment) throws {
            self.APKs = try Folder(path: env.get("APKS_DIR"))
            self.variants = [try env.get("VARIANTS")]
            self.home = try env.folder("ANDROID_HOME")
            self.NDKHome = try env.folder("ANDROID_NDK_HOME")
        }
    }

    public struct Build {
        public let buildNumber: Int
        public let buildId: String
        public let appId: String
        public let branch: String
        public let baseBranch: String?
        public let repoSlug: String
        public let pullRequestId: Int?
        public let workspace: Folder
        public let secureFiles: Folder
        public let triggeredBy: Trigger

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

    static public let build: Build = {
        do {
            return try Build(env: Environment(config: ProcessInfo.processInfo.environment))
        } catch let Error.missingKey(key) {
            fatalError("Missing environement key \(key), are you sure it's a Buddybuild custom script?")
        } catch {
            fatalError("Unable to retrieve informations about the build, are you sure it's a Buddybuild custom script?")
        }
    }()

    static public let ios: IOS? = {
        return try? IOS(env: Environment(config: ProcessInfo.processInfo.environment))
    }()

    static public let android: Android? = {
        return try? Android(env: Environment(config: ProcessInfo.processInfo.environment))
    }()
}
