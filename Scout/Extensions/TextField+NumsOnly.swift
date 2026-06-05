import SwiftUI

extension View {
    /// Forces a text field to only accept numeric characters, with an optional max limit on decimal places.
    func numbersOnly(_ text: Binding<String>, allowDecimals: Bool = false, maxDecimalPlaces: Int? = nil) -> some View {
        self.onChange(of: text.wrappedValue) { oldValue, newValue in
            var hasDecimal = false
            
            // 1. First pass: Clean out any illegal characters
            var filtered = newValue.filter { char in
                if char.isNumber { return true }
                if allowDecimals && (char == "." || char == ",") && !hasDecimal {
                    hasDecimal = true
                    return true
                }
                return false
            }
            
            // 2. Second pass: Enforce the maximum decimal places if specified
            if allowDecimals, let maxPlaces = maxDecimalPlaces {
                // Standardize comma to period just for splitting logic consistency
                let normalized = filtered.replacingOccurrences(of: ",", with: ".")
                let components = normalized.components(separatedBy: ".")
                
                // If there's a fractional component and it exceeds our maximum limit
                if components.count == 2, components[1].count > maxPlaces {
                    let integerPart = components[0]
                    let fractionalPart = String(components[1].prefix(maxPlaces))
                    
                    // Reconstruct using the user's original separator preference (comma vs dot)
                    let separator = filtered.contains(",") ? "," : "."
                    filtered = "\(integerPart)\(separator)\(fractionalPart)"
                }
            }
            
            // 3. Update binding if changes were made
            if filtered != newValue {
                text.wrappedValue = filtered
            }
        }
    }
}
