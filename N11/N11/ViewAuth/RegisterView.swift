import SwiftUI
import Combine
import Foundation
import UIKit


struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var showRegister: Bool
    
    @State private var name = ""
    @State private var surname = ""
    @State private var username = ""
    @State private var password = ""
    @State private var passwordRepeat = ""
    @State private var birthDate = Date()
    @State private var address = ""
    @State private var postalCode = ""
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Kişisel Bilgiler")) {
                TextField("Ad", text: $name)
                TextField("Soyad", text: $surname)
                DatePicker("Doğum Tarihi", selection: $birthDate, displayedComponents: .date)
            }
            
            Section(header: Text("Hesap Bilgileri")) {
                TextField("Kullanıcı Adı", text: $username)
                    .autocapitalization(.none)
                SecureField("Şifre", text: $password)
                SecureField("Şifre Tekrarı", text: $passwordRepeat)
            }
            
            Section(header: Text("İletişim Bilgileri")) {
                TextField("Adres", text: $address)
                TextField("Posta Kodu", text: $postalCode)
            }
            
            Section {
                Button(action: registerUser) {
                    Text("Kaydı Onayla")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.n11Accent) // TEMA RENGİ
            }
        }
        .navigationTitle("Kayıt Ol")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Kayıt Hatası", isPresented: $showError) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func registerUser() {
        if name.isEmpty || surname.isEmpty || username.isEmpty || password.isEmpty || address.isEmpty || postalCode.isEmpty {
            errorMessage = "Lütfen tüm alanları doldurun."
            showError = true
            return
        }
        if password != passwordRepeat {
            errorMessage = "Şifreler birbiriyle eşleşmiyor."
            showError = true
            return
        }
        
        if authManager.registeredUsers.contains(where: { $0.username == username }) {
            errorMessage = "Bu kullanıcı adı zaten alınmış."
            showError = true
            return
        }
        
        let newUser = UserProfile(name: name, surname: surname, username: username, password: password, birthDate: birthDate, address: address, postalCode: postalCode)
        authManager.register(user: newUser)
        showRegister = false
    }
}
//  RegisterView.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

