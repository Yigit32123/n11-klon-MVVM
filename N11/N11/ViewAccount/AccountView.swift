import SwiftUI
import Combine
import Foundation
import UIKit


// MARK: - Hesap Bilgileri (AccountView)
struct AccountView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var birthDate = Date()
    @State private var address = ""
    @State private var postalCode = ""
    @State private var showSaveAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    VStack(spacing: 12) {
                        Image("n11Logo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.n11Accent.opacity(0.5), lineWidth: 2)) // TEMA RENGİ
                            .shadow(radius: 5)
                            .padding(.top, 20)
                        
                        Text("\(authManager.currentUser?.name ?? "") \(authManager.currentUser?.surname ?? "")")
                            .font(.title2)
                            .bold()
                        Text("@\(authManager.currentUser?.username ?? "")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 20)
                    
                    Form {
                        Section(header: Text("Değiştirilemez Bilgiler")) {
                            HStack {
                                Text("Ad")
                                Spacer()
                                Text(authManager.currentUser?.name ?? "")
                                    .foregroundColor(.gray)
                            }
                            HStack {
                                Text("Soyad")
                                Spacer()
                                Text(authManager.currentUser?.surname ?? "")
                                    .foregroundColor(.gray)
                            }
                            HStack {
                                Text("Kullanıcı Adı")
                                Spacer()
                                Text(authManager.currentUser?.username ?? "")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Section(header: Text("Düzenlenebilir Bilgiler")) {
                            DatePicker("Doğum Tarihi", selection: $birthDate, displayedComponents: .date)
                            TextField("Adres", text: $address)
                            TextField("Posta Kodu", text: $postalCode)
                        }
                        
                        Section {
                            Button(action: {
                                authManager.updateProfile(birthDate: birthDate, address: address, postalCode: postalCode)
                                showSaveAlert = true
                            }) {
                                Text("Bilgileri Güncelle")
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.n11Accent) // TEMA RENGİ
                            }
                        }
                    }
                    .frame(height: 500)
                }
            }
            .navigationTitle("Hesap Bilgileri")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear {
                if let user = authManager.currentUser {
                    self.birthDate = user.birthDate
                    self.address = user.address
                    self.postalCode = user.postalCode
                }
            }
            .alert("Başarılı", isPresented: $showSaveAlert) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text("Bilgileriniz başarıyla güncellendi.")
            }
        }
    }
}
//  AccountView.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

