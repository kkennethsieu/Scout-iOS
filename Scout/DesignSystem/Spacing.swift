import CoreGraphics

/// All spacing values in the app should come from this scale.


enum Spacing {
    /// 4pt — icon-to-label gaps, tight clusters
    static let xs: CGFloat = 4
    
    /// 8pt — element padding inside cards
    static let sm: CGFloat = 8
    
    /// 12pt — default gap between elements
    static let md: CGFloat = 12
    
    /// 16pt — default screen edge inset, card padding
    static let lg: CGFloat = 16
    
    /// 24pt — section spacing
    static let xl: CGFloat = 24
    
    /// 32pt — major section breaks (review form sections)
    static let xxl: CGFloat = 32
    
    /// 48pt — top-of-screen breathing room
    static let xxxl: CGFloat = 48
}
