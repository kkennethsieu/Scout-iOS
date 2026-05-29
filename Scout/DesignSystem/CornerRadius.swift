import CoreGraphics

enum Radius {
    /// 6pt — chips, tags, small inputs
    static let sm: CGFloat = 6
    
    /// 12pt — buttons, cards, inputs (default)
    static let md: CGFloat = 12
    
    /// 20pt — sheets, large cards
    static let lg: CGFloat = 20
    
    /// 28pt — hero containers, modal sheets
    static let xl: CGFloat = 28
    
    /// 999pt — full pill (chips, pill buttons)
    static let pill: CGFloat = 999
}
