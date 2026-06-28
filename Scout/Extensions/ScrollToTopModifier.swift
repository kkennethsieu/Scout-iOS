struct ScrollToTopModifier: ViewModifier {
    @Environment(TabRouter.self) private var router

    func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            content
                .onChange(of: router.scrollToTopTrigger) {
                    withAnimation {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
        }
    }
}

extension View {
    func scrollsToTopOnTabRetap() -> some View {
        modifier(ScrollToTopModifier())
    }
}