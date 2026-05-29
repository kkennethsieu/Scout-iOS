import SwiftUI

struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color.sBackground.ignoresSafeArea()
            
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
        }
    }
}
