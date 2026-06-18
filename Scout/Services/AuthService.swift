import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit
import Observation
import GoogleSignIn

import FirebaseCore

@Observable
final class AuthService {
    static let shared = AuthService()
    
    // MARK: - Observable state
    
    private(set) var currentUser: User?
    private(set) var isResolvingAuth = true
    var isAuthenticated: Bool { currentUser != nil }
    
    // MARK: - Private
    
    private var currentAppleNonce: String?
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Lifecycle
    
    private init() {
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            try? Auth.auth().signOut()
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            self?.currentUser = firebaseUser.map { Self.mapUser($0) }
            self?.isResolvingAuth = false
        }
    }
    
    private static func mapUser(_ firebaseUser: FirebaseAuth.User) -> User {
        User(
            id: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL,
            createdAt: firebaseUser.metadata.creationDate ?? Date()
        )
    }
    
    // MARK: - Apple Sign In
    func prepareAppleSignInNonce() -> String {
        let nonce = Self.randomNonceString()
        currentAppleNonce = nonce
        return Self.sha256(nonce)
    }
    
    func signInWithApple(authorization result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .success(let authorization):
            try await completeAppleSignIn(authorization: authorization)
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled {
                return
            }
            throw error
        }
    }
    
    private func completeAppleSignIn(authorization: ASAuthorization) async throws {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentAppleNonce,
              let identityToken = appleCredential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidAppleCredential
        }
        
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )
        
        try await Auth.auth().signIn(with: firebaseCredential)
        currentAppleNonce = nil
    }
    
    // MARK: - SignInOrUpWithGoogle
    
    func signInWithGoogle() async throws {
        guard let rootVC = UIApplication.shared.firstKeyWindow?.rootViewController else {
            throw AuthError.noRootViewController
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.invalidGoogleCredential
        }
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        try await Auth.auth().signIn(with: credential)
    }
    
    // MARK: - Email
    
    func signInWithEmail(email: String, password: String) async throws {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch let error as NSError {
            let authError = AuthErrorCode(rawValue: error.code)
            switch authError {
            case .invalidCredential:
                throw AuthError.invalidCredentials
            case .invalidEmail:
                throw AuthError.invalidEmail
            case .networkError:
                throw AuthError.networkError
            default:
                throw AuthError.unknown(error.localizedDescription)
            }
        }
    }
    
    func createWithEmail(email: String, password: String) async throws {
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
        } catch let error as NSError {
            let authError = AuthErrorCode(rawValue: error.code)
            switch authError {
            case .emailAlreadyInUse:
                throw AuthError.emailAlreadyInUse
            case .invalidEmail:
                throw AuthError.invalidEmail
            case .weakPassword:
                throw AuthError.weakPassword
            case .networkError:
                throw AuthError.networkError
            default:
                throw AuthError.unknown(error.localizedDescription)
            }
        }
    }


    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
        currentAppleNonce = nil
    }

    // MARK: - Token

    func idToken(forcingRefresh: Bool = false) async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.notAuthenticated
        }
        return try await user.getIDToken(forcingRefresh: forcingRefresh)
    }
}

// MARK: - Nonce helpers

private extension AuthService {
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if status != errSecSuccess {
            fatalError("SecRandomCopyBytes failed with status \(status)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
    
    static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        return SHA256.hash(data: data)
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidAppleCredential
    case invalidGoogleCredential
    case noRootViewController
    case notAuthenticated
    case invalidCredentials
    case networkError
    case invalidEmail
    case emailAlreadyInUse
    case weakPassword
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidAppleCredential:
            return "Couldn't read your Apple sign-in. Please try again."
        case .invalidGoogleCredential:
            return "Couldn't read your Google sign-in. Please try again."
        case .noRootViewController:
            return "Unable to present sign-in. Please try again."
        case .notAuthenticated:
            return "You're not signed in. Please sign in and try again."
        case .invalidCredentials:
            return "Incorrect email or password."
        case .networkError:       
            return "Network error. Check your connection."
        case .invalidEmail:       
            return "Please enter a valid email address."
        case .emailAlreadyInUse: 
            return "An account with this email already exists."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .unknown(let msg):
            return msg
        }
    }
}

// MARK: - UIApplication extension

private extension UIApplication {
    var firstKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

