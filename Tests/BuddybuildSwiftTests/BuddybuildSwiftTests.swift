import XCTest
import Quick
import Nimble
import Files

@testable import BuddybuildSwift

class BuddybuildSwiftTests: QuickSpec {

    override func spec() {
        var sandbox: Folder!
        beforeEach {
            print("Creating sandbox...")
            sandbox = try! Folder.temporary.createSubfolderIfNeeded(withName: "buddybuild-test")
        }

        afterEach {
            print("Deleting sandbox...")
            try! sandbox.delete()
        }

        describe("Build") {

        }

        describe("Android") {
            context("building an iOS app") {
                var env: Environment!
                beforeEach {

                    env = Environment(config: [
                        "IPA_PATH": try! sandbox.createFile(named: "potato.ipa").path,
                        "APP_STORE_IPA_PATH": try! sandbox.createFile(named: "appStorePotato.ipa").path,
                        "TEST_DIR": "/tmp/workspace/tests-bundle",
                        "SCHEME": "Potato - Debug"
                    ])
                }

                afterEach {
                    env = nil
                }

                it("can't be instanciated") {
                    expect { try Buddybuild.Android(env: env) }.to(throwError())
                }
            }

            context("building and Android app") {
                var env: Environment!
                beforeEach {
                    env = Environment(config: [
                        "APKS_DIR": try! sandbox.createSubfolder(named: "apks").path,
                        "VARIANTS": "release",
                        "ANDROID_HOME": try! sandbox.createSubfolder(named: "android-sdk").path,
                        "ANDROID_NDK_HOME": try! sandbox.createSubfolder(named: "android-ndk").path
                    ])
                }

                it("can be instanciated") {
                    expect { try Buddybuild.Android(env: env) }.notTo(throwError())
                }
            }
        }

        describe("iOS") {
            context("building an iOS app") {
                var env: Environment!

                beforeEach {
                    env = Environment(config: [
                        "IPA_PATH": try! sandbox.createFile(named: "potato.ipa").path,
                        "APP_STORE_IPA_PATH": try! sandbox.createFile(named: "appStorePotato.ipa").path,
                        "TEST_DIR": "/tmp/workspace/tests-bundle",
                        "SCHEME": "Potato - Debug"
                    ])
                }

                it("can be instanciated") {
                    expect { try Buddybuild.IOS(env: env) }.notTo(throwError())
                }
            }

            context("building and Android app") {
                var env: Environment!

                beforeEach {
                    env = Environment(config: [
                        "APKS_DIR": try! sandbox.createSubfolder(named: "apks").path,
                        "VARIANTS": "release",
                        "ANDROID_HOME": try! sandbox.createSubfolder(named: "android-sdk").path,
                        "ANDROID_NDK_HOME": try! sandbox.createSubfolder(named: "android-ndk").path
                    ])
                }

                it("can't be instanciated") {
                    expect { try Buddybuild.IOS(env: env) }.to(throwError())
                }
            }
       }
    }
}
