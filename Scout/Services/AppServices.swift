import Foundation

/// Central source of truth for which `SpotService` the app uses by default.
///
/// The iOS Simulator shares the Mac's network, so `localhost:8000` is reachable
/// and we use the live backend. A real device can't reach `localhost`, so it
/// falls back to offline mock data automatically — no manual toggling.
///
/// To test the live backend on a real device instead, point
/// `LiveSpotService.baseURL` at your Mac's LAN IP.
enum AppServices {
    static var spot: SpotService {
        LiveSpotService()
//
//        #if targetEnvironment(simulator)
//        LiveSpotService()
//        #else
//        MockSpotService()
//        #endif
    }

    static var user: UserService {
        LiveUserService()
//
//        #if targetEnvironment(simulator)
//        LiveUserService()
//        #else
//        MockUserService()
//        #endif
    }

    static var legal: LegalService {
        LiveLegalService()
    }
}
