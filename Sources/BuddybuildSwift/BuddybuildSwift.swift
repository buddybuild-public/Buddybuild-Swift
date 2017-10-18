import Foundation
import Files

public struct Folder {
    let path: String
}

public struct File {
    let path: String
}

public enum Error: Swift.Error {
    case invalidEnv
}

func bbEnv(for key: String, in env: [String: String]) throws -> String {
    guard let v = env[key] else {
        throw Error.invalidEnv
    }

    return v
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

        init(env: [String: String]) throws {
            self.IPA = try? File(path: bbEnv(for: "IPA_PATH", in: env))
            self.appStoreIPA = try? File(path: bbEnv(for: "APP_STORE_IPA_PATH", in: env))
            self.testDir = try? Folder(path: bbEnv(for: "TEST_DIR", in: env))
            self.scheme = try bbEnv(for: "SCHEME", in: env)
        }
    }

    struct Android {
        let APKs: Folder
        let variants: [String] // TODO: CHECK THIS
        let home: Folder
        let NDKHome: Folder

        init(env: [String: String]) throws {
            self.APKs = try Folder(path: bbEnv(for: "APKS_DIR", in: env))
            self.variants = [try bbEnv(for: "VARIANTS", in: env)]
            guard let home = env["ANDROID_HOME"] else {
                throw Error.invalidEnv
            }
            self.home = Folder(path: home)

            guard let NDKHome = env["ANDROID_NDK_HOME"] else {
                throw Error.invalidEnv
            }
            self.NDKHome = Folder(path: NDKHome)
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

        init(env: [String: String]) throws {
            let f = NumberFormatter()
            guard let buildNumber = f.number(from: try bbEnv(for: "BUILD_NUMBER", in: env))?.intValue else {
                throw Error.invalidEnv
            }
            self.buildNumber = buildNumber

            self.buildId = try bbEnv(for: "BUILD_ID", in: env)
            self.appId = try bbEnv(for: "APP_ID", in: env)
            self.branch = try bbEnv(for: "BRANCH", in: env)
            if let baseBranch = try? bbEnv(for: "BASE_BRANCH", in: env), !baseBranch.isEmpty {
                self.baseBranch = baseBranch
            } else {
                self.baseBranch = nil
            }

            self.repoSlug = try bbEnv(for: "REPO_SLUG", in: env)

            guard let pr = try? bbEnv(for: "PULL_REQUEST", in: env), let pullRequest = f.number(from: pr)?.intValue else {
                throw Error.invalidEnv
            }
            self.pullRequestId = pullRequest

            self.workspace = try Folder(path: bbEnv(for: "WORKSPACE", in: env))
            self.secureFiles = try Folder(path: bbEnv(for: "SECURE_FILES", in: env))
            guard let trigger = (try? bbEnv(for: "TRIGGERED_BY", in: env)).flatMap(Trigger.init) else {
                throw Error.invalidEnv
            }

            self.triggeredBy = trigger
        }
    }

    static let build: Build = {
        do {
            return try Build(env: ProcessInfo.processInfo.environment)
        } catch {
            fatalError("Unable to retrieve informations about the build, are you sure it's a Buddybuild custom script?")
        }
    }()

    static let ios: IOS? = {
        return try? IOS(env: ProcessInfo.processInfo.environment)
    }()

    static let android: Android? = {
        return try? Android(env: ProcessInfo.processInfo.environment)
    }()
}
