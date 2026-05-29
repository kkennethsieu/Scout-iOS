import SwiftUI
import UIKit

struct STextField: View {
    var label: String = ""
    @Binding var text: String
    
    var placeholder: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences

    @FocusState private var isFocused: Bool
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            
            if !label.isEmpty {
                Text(label)
                    .font(.sHeadingS)
                    .foregroundStyle(Color.sTextTertiary)
            }
            
            HStack(spacing: Spacing.sm) {
                fieldView
                    .font(.sBodyL)
                    .foregroundStyle(Color.sTextPrimary)
                    .tint(Color.sAccent)
                    .focused($isFocused)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled(isSecure || keyboardType == .emailAddress)
                
                if isSecure {
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.sTextTertiary)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .frame(minHeight: 28)
            
            Rectangle()
                .fill(isFocused ? Color.sAccent : Color.sBorderDefault)
                .frame(height: isFocused ? 1.5 : 1)
                .animation(.easeOut(duration: 0.15), value: isFocused)
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
    }
    
    @ViewBuilder
    private var fieldView: some View {
        if isSecure && !isPasswordVisible {
            SecureField(placeholder, text: $text)
        } else {
            SwiftUI.TextField(placeholder, text: $text)
        }
    }
}

// MARK: - Preview

#Preview("STextField") {
    struct Demo: View {
        @State var email = ""
        @State var password = ""
        @State var name = "Pre-filled value"
        
        var body: some View {
            VStack(spacing: Spacing.xl) {
                STextField(
                    label: "Email Address",
                    text: $email,
                    placeholder: "email@example.com",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocapitalization: .never
                )
                
                STextField(
                    label: "Password",
                    text: $password,
                    isSecure: true,
                    textContentType: .password
                )
                
                STextField(
                    text: $name,
                    placeholder: "Display Name"
                )
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.sBackground)
        }
    }
    
    return Demo()
}
