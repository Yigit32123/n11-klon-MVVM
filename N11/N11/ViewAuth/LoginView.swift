import SwiftUI
import Combine
import Foundation
import UIKit


struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var username = ""
    @State private var password = ""
    @State private var showRegister = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 25) {
                    
                    // N11 LOGO KISMI
                    // Bu ismin Assets.xcassets klasöründeki resmin adıyla birebir aynı olması zorunludur.
                    Image("n11LogoText")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .padding(.bottom, 20)
                    
                    Text("Giriş Yap")
                        .font(.largeTitle)
                        .bold()
                    
                    VStack(spacing: 15) {
                        TextField("Kullanıcı Adı", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .padding(.horizontal)
                        
                        SecureField("Şifre", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }
                    
                    if authManager.loginError {
                        Text("Kullanıcı adı veya şifre hatalı.")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: {
                        authManager.login(username: username, password: password)
                    }) {
                        Text("Giriş Yap")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.n11Accent) // TEMA RENGİ
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.top, 10)
                    
                    Button("Hesabın yok mu? Kayıt Ol") {
                        showRegister = true
                    }
                    .foregroundColor(.n11Accent) // TEMA RENGİ
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding(.top, 50)
                .navigationDestination(isPresented: $showRegister) {
                    RegisterView(showRegister: $showRegister)
                }
                
                if authManager.showSuccessMessage {
                    VStack {
                        Spacer()
                        Text("Kayıt Başarılı! Giriş yapabilirsiniz.")
                            .font(.headline)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.bottom, 50)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(2)
                }
            }
        }
    }
}
//  LoginView.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

