import SwiftUI

@main
struct CCCDNFCScannerApp: App {
    @StateObject private var store = CitizenStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
