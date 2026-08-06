import SwiftUI
import Combine
import Foundation
import UIKit

// MARK: - n11 Özel Kampanya Renkleri
extension Color {
    /// Kampanya baloncuğunda ve genel temada kullanılacak pembe/magenta vurgu rengi
    static let n11Accent = Color(red: 240/255, green: 0/255, blue: 224/255)
    /// Kampanya baloncuğunda kullanılacak koyu ton
    static let n11DarkSpot = Color(red: 20/255, green: 20/255, blue: 20/255)
}

// MARK: - String Extension (Arama Geliştirmesi)
extension String {
    /// Metni Türkçe karakterlerden (diacritic) ve büyük harf duyarlılığından arındırır.
    var searchNormalized: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "tr_TR"))
    }
}

// MARK: - Models
struct ProductResponse: Codable, Sendable {
    let page: String?
    let nextPage: String?
    let publishedAt: String?
    let sponsoredProducts: [Product]?
    let products: [Product]?
    
    enum CodingKeys: String, CodingKey {
        case page, nextPage, sponsoredProducts, products
        case publishedAt = "published_at"
    }
}

struct Product: Codable, Identifiable, Sendable {
    let id: Int
    let title: String
    let image: String
    let price: Double
    let instantDiscountPrice: Double?
    let rate: Double?
    let sellerName: String?
    
    var validImageUrl: URL? {
        let cleanUrlString = image.replacingOccurrences(of: "{0}", with: "500")
        return URL(string: cleanUrlString)
    }
}

struct ProductDetail: Codable, Sendable {
    let title: String
    let description: String
    let images: [String]
    let price: Double
    let instantDiscountPrice: Double?
    let rate: Double?
    let sellerName: String?
    
    var validImageUrls: [URL] {
        return images.compactMap { imageString in
            let cleanUrlString = imageString.replacingOccurrences(of: "{0}", with: "500")
            return URL(string: cleanUrlString)
        }
    }
}

// UserProfile
struct UserProfile: Identifiable, Codable {
    var id = UUID()
    var name: String
    var surname: String
    var username: String
    var password: String
    var birthDate: Date
    var address: String
    var postalCode: String
}

// Sepet Öğesi Modeli
struct CartItem: Identifiable, Codable {
    var id = UUID()
    let product: Product
    var quantity: Int
}

// Sipariş Durumu
enum OrderStatus: String, Codable, CaseIterable {
    case received = "Sipariş Alındı"
    case preparing = "Hazırlanıyor"
    case shipped = "Kargoya Verildi"
    case delivered = "Teslim Edildi"
}

// Sipariş Modeli
struct Order: Identifiable, Codable {
    var id = UUID()
    let orderNumber: String
    let date: Date
    let items: [CartItem]
    let totalAmount: Double        // Kupon varsa indirim uygulanmış NİHAİ tutar
    let address: String
    var status: OrderStatus
    var originalAmount: Double? = nil      // İndirim öncesi ara toplam (kupon yoksa nil)
    var appliedCouponCode: String? = nil   // Kullanılan kupon kodu (kupon yoksa nil)
    var discountAmount: Double? = nil      // Düşülen tutar (kupon yoksa nil)
}

// MARK: - Menü Sekmeleri
enum AppTab: String, CaseIterable {
    case home = "Ana Sayfa"
    case favorites = "Favorilerim"
    case cart = "Sepetim"
    case orders = "Siparişlerim"
    case account = "Hesap Bilgileri"
    
    var iconName: String {
        switch self {
        case .home: return "house"
        case .favorites: return "heart"
        case .cart: return "cart"
        case .orders: return "shippingbox"
        case .account: return "person"
        }
    }
}

// MARK: - Sıralama Seçenekleri
enum SortOption: String, CaseIterable {
    case none = "Önerilen"
    case priceAsc = "En Düşük Fiyat"
    case priceDesc = "En Yüksek Fiyat"
    case topRated = "En Çok Değerlendirilenler"
}

// MARK: - State Managers
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    
    @Published var registeredUsers: [UserProfile] = [] {
        didSet { saveUsersToUserDefaults() }
    }
    
    @Published var showSuccessMessage = false
    @Published var loginError = false
    
    init() {
        loadUsersFromUserDefaults()
    }
    
    private func saveUsersToUserDefaults() {
        if let encodedData = try? JSONEncoder().encode(registeredUsers) {
            UserDefaults.standard.set(encodedData, forKey: "registeredUsers_Key")
        }
    }
    
    private func loadUsersFromUserDefaults() {
        if let savedData = UserDefaults.standard.data(forKey: "registeredUsers_Key"),
           let decodedUsers = try? JSONDecoder().decode([UserProfile].self, from: savedData) {
            self.registeredUsers = decodedUsers
        }
    }
    
    func register(user: UserProfile) {
        registeredUsers.append(user)
        withAnimation { showSuccessMessage = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { self.showSuccessMessage = false }
        }
    }
    
    func login(username: String, password: String) {
        if let user = registeredUsers.first(where: { $0.username == username && $0.password == password }) {
            currentUser = user
            isAuthenticated = true
            loginError = false
        } else {
            loginError = true
        }
    }
    
    func logout() {
        isAuthenticated = false
        currentUser = nil
    }
    
    func updateProfile(birthDate: Date, address: String, postalCode: String) {
        guard let index = registeredUsers.firstIndex(where: { $0.id == currentUser?.id }) else { return }
        registeredUsers[index].birthDate = birthDate
        registeredUsers[index].address = address
        registeredUsers[index].postalCode = postalCode
        currentUser = registeredUsers[index]
    }
}

// MARK: - Favorites Manager
class FavoritesManager: ObservableObject {
    @Published var favoriteProducts: [Product] = [] {
        didSet { saveFavorites() }
    }
    
    var currentUserId: String = "" {
        didSet {
            if !currentUserId.isEmpty {
                loadFavorites()
            }
        }
    }
    
    func toggleFavorite(product: Product) {
        if let index = favoriteProducts.firstIndex(where: { $0.id == product.id }) {
            favoriteProducts.remove(at: index)
        } else {
            favoriteProducts.append(product)
        }
    }
    
    func isFavorite(product: Product) -> Bool {
        return favoriteProducts.contains(where: { $0.id == product.id })
    }
    
    private func saveFavorites() {
        guard !currentUserId.isEmpty else { return }
        if let encodedData = try? JSONEncoder().encode(favoriteProducts) {
            UserDefaults.standard.set(encodedData, forKey: "saved_favorites_\(currentUserId)")
        }
    }
    
    private func loadFavorites() {
        guard !currentUserId.isEmpty else { return }
        if let savedData = UserDefaults.standard.data(forKey: "saved_favorites_\(currentUserId)"),
           let decoded = try? JSONDecoder().decode([Product].self, from: savedData) {
            self.favoriteProducts = decoded
        } else {
            self.favoriteProducts = []
        }
    }
}

// MARK: - Cart Manager
class CartManager: ObservableObject {
    @Published var cartItems: [CartItem] = [] {
        didSet { saveCart() }
    }
    
    var currentUserId: String = "" {
        didSet {
            if !currentUserId.isEmpty {
                loadCart()
            }
        }
    }
    
    func addToCart(product: Product) {
        if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
            cartItems[index].quantity += 1
        } else {
            cartItems.append(CartItem(product: product, quantity: 1))
        }
    }
    
    func removeFromCart(product: Product) {
        if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
            if cartItems[index].quantity > 1 {
                cartItems[index].quantity -= 1
            } else {
                cartItems.remove(at: index)
            }
        }
    }
    
    func getQuantity(for product: Product) -> Int {
        return cartItems.first(where: { $0.product.id == product.id })?.quantity ?? 0
    }
    
    func totalPrice() -> Double {
        return cartItems.reduce(0) { total, item in
            let price = item.product.instantDiscountPrice ?? item.product.price
            return total + (price * Double(item.quantity))
        }
    }
    
    func clearCart() {
        cartItems.removeAll()
    }
    
    private func saveCart() {
        guard !currentUserId.isEmpty else { return }
        if let encodedData = try? JSONEncoder().encode(cartItems) {
            UserDefaults.standard.set(encodedData, forKey: "saved_cart_\(currentUserId)")
        }
    }
    
    private func loadCart() {
        guard !currentUserId.isEmpty else { return }
        if let savedData = UserDefaults.standard.data(forKey: "saved_cart_\(currentUserId)"),
           let decoded = try? JSONDecoder().decode([CartItem].self, from: savedData) {
            self.cartItems = decoded
        } else {
            self.cartItems = []
        }
    }
}

// MARK: - Order Manager
class OrderManager: ObservableObject {
    @Published var orders: [Order] = [] {
        didSet { saveOrders() }
    }
    
    var currentUserId: String = "" {
        didSet {
            if !currentUserId.isEmpty {
                loadOrders()
            }
        }
    }
    
    func createOrder(items: [CartItem], totalAmount: Double, originalAmount: Double? = nil, address: String, appliedCouponCode: String? = nil, discountAmount: Double? = nil) {
        let newOrder = Order(
            orderNumber: String(Int.random(in: 10000000...99999999)),
            date: Date(),
            items: items,
            totalAmount: totalAmount,
            address: address,
            status: .preparing,
            originalAmount: originalAmount,
            appliedCouponCode: appliedCouponCode,
            discountAmount: discountAmount
        )
        orders.insert(newOrder, at: 0)
    }
    
    private func saveOrders() {
        guard !currentUserId.isEmpty else { return }
        if let encodedData = try? JSONEncoder().encode(orders) {
            UserDefaults.standard.set(encodedData, forKey: "saved_orders_\(currentUserId)")
        }
    }
    
    private func loadOrders() {
        guard !currentUserId.isEmpty else { return }
        if let savedData = UserDefaults.standard.data(forKey: "saved_orders_\(currentUserId)"),
           let decoded = try? JSONDecoder().decode([Order].self, from: savedData) {
            self.orders = decoded
        } else {
            self.orders = []
        }
    }
}

class StoreViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var sponsoredProducts: [Product] = []
    @Published var detailedProduct: ProductDetail? = nil
    
    @Published var currentPage = 1
    @Published var isLoadingMore = false
    
    init() {
        fetchListing(page: 1)
        fetchProductDetail(productId: 12333)
    }
    
    func fetchListing(page: Int) {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        
        guard let url = URL(string: "https://private-d3ae2-n11case.apiary-mock.com/listing/\(page)") else {
            isLoadingMore = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingMore = false
                guard let data = data, error == nil else {
                    self.simulateInfiniteScroll()
                    return
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(ProductResponse.self, from: data)
                    let fetchedProducts = decodedResponse.products ?? []
                    
                    if fetchedProducts.isEmpty {
                        self.simulateInfiniteScroll()
                    } else {
                        if page == 1 {
                            self.products = fetchedProducts
                            self.sponsoredProducts = decodedResponse.sponsoredProducts ?? []
                        } else {
                            self.products.append(contentsOf: fetchedProducts)
                        }
                        self.currentPage = page
                    }
                    
                } catch {
                    print("Listing JSON Decode Hatası (Sayfa \(page)): \(error)")
                    self.simulateInfiniteScroll()
                }
            }
        }.resume()
    }
    
    private func simulateInfiniteScroll() {
        if !self.products.isEmpty {
            let loopData = self.products.prefix(10)
            self.products.append(contentsOf: loopData)
            self.currentPage += 1
        }
    }
    
    func fetchProductDetail(productId: Int) {
        guard let url = URL(string: "https://private-d3ae2-n11case.apiary-mock.com/product?productId=\(productId)") else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                do {
                    let decodedDetail = try JSONDecoder().decode(ProductDetail.self, from: data)
                    self.detailedProduct = decodedDetail
                } catch {
                    print("Detay JSON Decode Hatası: \(error)")
                }
            }
        }.resume()
    }
    
    func loadNextPage() {
        guard !isLoadingMore else { return }
        fetchListing(page: currentPage + 1)
    }
}

// MARK: - Root View
struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainAppView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}

// MARK: - Auth Views
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

// MARK: - Main App View
struct MainAppView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = StoreViewModel()
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var cartManager = CartManager()
    @StateObject private var orderManager = OrderManager()
    
    @State private var currentTab: AppTab = .home
    @State private var isMenuOpen: Bool = false
    @State private var showWheelSheet: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                switch currentTab {
                case .home:
                    HomeView(viewModel: viewModel, favoritesManager: favoritesManager, cartManager: cartManager)
                case .favorites:
                    FavoritesView(favoritesManager: favoritesManager, cartManager: cartManager)
                case .cart:
                    CartView(cartManager: cartManager, orderManager: orderManager, currentTab: $currentTab)
                case .orders:
                    OrdersView(orderManager: orderManager)
                case .account:
                    AccountView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if isMenuOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            isMenuOpen = false
                        }
                    }
            }
            
            if isMenuOpen {
                VStack(alignment: .leading, spacing: 20) {
                    
                    HStack(spacing: 15) {
                        Image("n11Logo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.n11Accent.opacity(0.4), lineWidth: 1)) // TEMA RENGİ
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.name ?? "Kullanıcı")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.n11Accent) // TEMA RENGİ
                            Text("@\(authManager.currentUser?.username ?? "")")
                                .font(.caption)
                                .foregroundColor(.n11Accent) // TEMA RENGİ
                        }
                    }
                    .padding(.bottom, 10)
                    
                    Divider()
                        .background(Color.n11Accent.opacity(0.4)) // TEMA RENGİ
                    
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        Button(action: {
                            currentTab = tab
                            withAnimation(.easeInOut) {
                                isMenuOpen = false
                            }
                        }) {
                            HStack(spacing: 15) {
                                Image(systemName: tab.iconName)
                                    .frame(width: 24)
                                Text(tab.rawValue)
                                    .font(.headline)
                            }
                            .foregroundColor(.n11Accent) // TEMA RENGİ
                            .padding(.vertical, 8)
                        }
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut) {
                            isMenuOpen = false
                        }
                        // Menü kapanış animasyonu bittikten sonra çarkı aç
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            showWheelSheet = true
                        }
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "gift.fill")
                                .frame(width: 24)
                            Text("Bana Ne Var")
                                .font(.headline)
                        }
                        .foregroundColor(.n11Accent) // TEMA RENGİ
                        .padding(.vertical, 8)
                    }
                    
                    Spacer()
                    Divider()
                        .background(Color.n11Accent.opacity(0.4)) // TEMA RENGİ
                    
                    Button(action: {
                        authManager.logout()
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .frame(width: 24)
                            Text("Çıkış Yap")
                                .font(.headline)
                        }
                        .foregroundColor(.n11Accent) // TEMA RENGİ
                        .padding(.vertical, 8)
                    }
                }
                .padding(25)
                .frame(width: 280, alignment: .leading)
                .background(Color.black)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(.leading, 20)
                .padding(.bottom, 120)
                .transition(.move(edge: .leading).combined(with: .opacity))
                .zIndex(1)
            }
            
            Button(action: {
                withAnimation(.easeInOut) {
                    isMenuOpen.toggle()
                }
            }) {
                Circle()
                    .fill(Color.black)
                    .frame(width: 55, height: 55)
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                    .overlay(
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.n11Accent) // TEMA RENGİ
                            .font(.system(size: 22, weight: .bold))
                    )
            }
            .padding(.leading, 20)
            .padding(.bottom, 120)
            .zIndex(2)
        }
        .onAppear {
            if let username = authManager.currentUser?.username {
                favoritesManager.currentUserId = username
                cartManager.currentUserId = username
                orderManager.currentUserId = username
            }
        }
        .sheet(isPresented: $showWheelSheet) {
            SpinWheelView()
        }
    }
}

// MARK: - Sepet Görünümü (CartView)
struct CartView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var cartManager: CartManager
    @ObservedObject var orderManager: OrderManager
    @Binding var currentTab: AppTab
    
    @State private var showCheckout = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if cartManager.cartItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Sepetiniz şu an boş.")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(cartManager.cartItems) { item in
                                HStack(spacing: 15) {
                                    AsyncImage(url: item.product.validImageUrl) { image in
                                        image.resizable().scaledToFit()
                                    } placeholder: {
                                        Color.gray.opacity(0.2)
                                    }
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(8)
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(item.product.title)
                                            .font(.subheadline)
                                            .lineLimit(2)
                                        
                                        let price = item.product.instantDiscountPrice ?? item.product.price
                                        Text("\(String(format: "%.2f", price)) TL")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(spacing: 8) {
                                        Button(action: { cartManager.addToCart(product: item.product) }) {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.title3)
                                        }
                                        Text("\(item.quantity)")
                                            .font(.headline)
                                        Button(action: { cartManager.removeFromCart(product: item.product) }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.title3)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
                            }
                        }
                        .padding()
                        .padding(.bottom, 120)
                    }
                    
                    VStack {
                        HStack {
                            Text("Toplam Tutar:")
                                .font(.headline)
                            Spacer()
                            Text("\(String(format: "%.2f", cartManager.totalPrice())) TL")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        Button(action: {
                            showCheckout = true
                        }) {
                            Text("Ödeme Yap")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.n11Accent) // TEMA RENGİ
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                    .background(Color.white)
                    .shadow(radius: 5)
                }
            }
            .navigationTitle("Sepetim")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCheckout) {
                CheckoutView(cartManager: cartManager, orderManager: orderManager, currentTab: $currentTab)
                    .environmentObject(authManager)
            }
        }
    }
}

// MARK: - CheckoutView (Sipariş ve Ödeme Ekranı)
struct CheckoutView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var cartManager: CartManager
    @ObservedObject var orderManager: OrderManager
    @Binding var currentTab: AppTab
    
    @StateObject private var couponManager = CouponManager()
    
    @State private var name = ""
    @State private var address = ""
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var isProcessing = false
    
    @State private var couponCode = ""
    @State private var appliedCoupon: DiscountCoupon? = nil
    @State private var couponMessage: String? = nil
    @State private var couponMessageIsError = false
    
    // MARK: Tutar Hesaplamaları
    
    private var subtotal: Double {
        cartManager.totalPrice()
    }
    
    private var discountAmount: Double {
        guard let coupon = appliedCoupon, let value = DiscountCodeSystem.parse(coupon.code) else { return 0 }
        switch value {
        case .amount(let tl):
            return min(Double(tl), subtotal) // İndirim sepet tutarını geçmesin
        case .percent(let p):
            return subtotal * (Double(p) / 100)
        }
    }
    
    private var finalTotal: Double {
        max(subtotal - discountAmount, 0)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Teslimat Bilgileri")) {
                    TextField("Ad Soyad", text: $name)
                    TextField("Açık Adres", text: $address)
                }
                
                Section(header: Text("Ödeme Bilgileri (Sanal Kart)")) {
                    TextField("Kart Numarası", text: $cardNumber)
                        .keyboardType(.numberPad)
                    HStack {
                        TextField("AA/YY", text: $expiryDate)
                        TextField("CVV", text: $cvv)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section(header: Text("İndirim Kuponu")) {
                    HStack {
                        TextField("Kupon kodunu buraya yapıştır", text: $couponCode)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .onChange(of: couponCode) { newValue in
                                tryApplyCoupon(newValue)
                            }
                        
                        if appliedCoupon != nil {
                            Button(action: removeCoupon) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    if let message = couponMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(couponMessageIsError ? .red : .green)
                    }
                }
                
                Section(header: Text("Sipariş Özeti")) {
                    HStack {
                        Text("Ara Toplam:")
                        Spacer()
                        Text("\(String(format: "%.2f", subtotal)) TL")
                            .foregroundColor(.secondary)
                    }
                    
                    if appliedCoupon != nil {
                        HStack {
                            Text("İndirim (\(appliedCoupon?.code.uppercased() ?? "")):")
                            Spacer()
                            Text("-\(String(format: "%.2f", discountAmount)) TL")
                                .foregroundColor(.n11Accent) // TEMA RENGİ
                        }
                    }
                    
                    HStack {
                        Text("Ödenecek Tutar:")
                            .font(.headline)
                        Spacer()
                        Text("\(String(format: "%.2f", finalTotal)) TL")
                            .bold()
                            .foregroundColor(.green)
                    }
                }
                
                Section {
                    Button(action: processOrder) {
                        if isProcessing {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Siparişi Onayla")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .listRowBackground(Color.green)
                    .disabled(address.isEmpty || cardNumber.isEmpty || isProcessing)
                }
            }
            .navigationTitle("Ödeme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
            .onAppear {
                if let user = authManager.currentUser {
                    name = "\(user.name) \(user.surname)"
                    address = user.address
                }
            }
        }
    }
    
    // MARK: Kupon Doğrulama
    
    private func tryApplyCoupon(_ rawCode: String) {
        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard code.count == 8 else {
            appliedCoupon = nil
            couponMessage = nil
            return
        }
        
        guard let coupon = couponManager.coupons.first(where: { $0.code == code }) else {
            appliedCoupon = nil
            couponMessage = "Bu kod geçerli değil."
            couponMessageIsError = true
            return
        }
        
        guard !coupon.isUsed else {
            appliedCoupon = nil
            couponMessage = "Bu kod daha önce kullanılmış."
            couponMessageIsError = true
            return
        }
        
        guard let value = DiscountCodeSystem.parse(coupon.code) else {
            appliedCoupon = nil
            couponMessage = "Bu kod okunamadı."
            couponMessageIsError = true
            return
        }
        
        appliedCoupon = coupon
        couponMessage = "\(value.displayText) indirim uygulandı!"
        couponMessageIsError = false
    }
    
    private func removeCoupon() {
        couponCode = ""
        appliedCoupon = nil
        couponMessage = nil
    }
    
    private func processOrder() {
        isProcessing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            orderManager.createOrder(
                items: cartManager.cartItems,
                totalAmount: finalTotal,
                originalAmount: appliedCoupon != nil ? subtotal : nil,
                address: address,
                appliedCouponCode: appliedCoupon?.code,
                discountAmount: appliedCoupon != nil ? discountAmount : nil
            )
            
            if let coupon = appliedCoupon {
                couponManager.markUsed(code: coupon.code)
            }
            
            cartManager.clearCart()
            isProcessing = false
            dismiss()
            currentTab = .orders
        }
    }
}

// MARK: - OrdersView (Siparişler)
struct OrdersView: View {
    @ObservedObject var orderManager: OrderManager
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if orderManager.orders.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Henüz siparişiniz bulunmuyor.")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(orderManager.orders) { order in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Sipariş No: \(order.orderNumber)")
                                        .font(.subheadline)
                                        .bold()
                                    Spacer()
                                    Text(order.date, formatter: dateFormatter)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Text("\(order.items.count) ürün")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                
                                Divider()
                                
                                HStack {
                                    Text(order.status.rawValue)
                                        .font(.caption)
                                        .bold()
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(statusColor(for: order.status).opacity(0.1))
                                        .foregroundColor(statusColor(for: order.status))
                                        .cornerRadius(6)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        if let original = order.originalAmount, let code = order.appliedCouponCode {
                                            Text("\(String(format: "%.2f", original)) TL")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .strikethrough()
                                            Text("\(String(format: "%.2f", order.totalAmount)) TL")
                                                .font(.headline)
                                                .foregroundColor(.green)
                                            Text("Kupon: \(code.uppercased())")
                                                .font(.caption2)
                                                .foregroundColor(.n11Accent) // TEMA RENGİ
                                        } else {
                                            Text("\(String(format: "%.2f", order.totalAmount)) TL")
                                                .font(.headline)
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Siparişlerim")
        }
    }
    
    private func statusColor(for status: OrderStatus) -> Color {
        switch status {
        case .received: return .orange
        case .preparing: return .blue
        case .shipped: return .purple
        case .delivered: return .green
        }
    }
}

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

// MARK: - Placeholder View
struct PlaceholderView: View {
    let title: String
    let icon: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("\(title) sayfası çok yakında!")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            .navigationTitle(title)
        }
    }
}

// MARK: - Kampanya Ürünü Özel Apple Store Tarzı Parlayan Baloncuk (Bubble)
struct CampaignProductBubble: View {
    let detail: ProductDetail
    @ObservedObject var cartManager: CartManager
    
    var body: some View {
        NavigationLink(destination: FullProductDetailView(productDetail: detail, cartManager: cartManager)) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Günün Fırsatı")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.n11Accent) // TEMA RENGİ
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black)
                        .cornerRadius(6)
                    
                    Text(detail.title)
                        .font(.headline)
                        .bold()
                        .lineLimit(2)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 16, weight: .bold))
            }
            .padding(20)
            .background(
                Color.n11Accent
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 6, x: 0, y: 0)
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Ana Sayfa (HomeView)
struct HomeView: View {
    @ObservedObject var viewModel: StoreViewModel
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var cartManager: CartManager
    
    @State private var searchText = ""
    @State private var selectedCategory = "Tümü"
    @State private var selectedSort: SortOption = .none
    
    let categories = ["Tümü", "Elektronik", "Moda", "Süpermarket", "Ev & Yaşam"]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var filteredAndSortedProducts: [Product] {
        var combinedProducts = viewModel.products
        
        for sponsored in viewModel.sponsoredProducts {
            if !combinedProducts.contains(where: { $0.id == sponsored.id }) {
                combinedProducts.append(sponsored)
            }
        }
        
        var result = combinedProducts
        
        if !searchText.isEmpty {
            let searchTerms = searchText.searchNormalized.split(separator: " ").map { String($0) }
            result = result.filter { product in
                let normalizedTitle = product.title.searchNormalized
                return searchTerms.allSatisfy { term in
                    normalizedTitle.contains(term)
                }
            }
        }
        
        if selectedCategory != "Tümü" {
            let keywords: [String]
            switch selectedCategory {
            case "Elektronik": keywords = ["telefon", "bilgisayar", "kulaklik", "tv", "apple", "samsung", "xiaomi", "iphone", "kilif"]
            case "Moda": keywords = ["ayakkabi", "canta", "tisort", "giyim", "kiyafet", "pantolon"]
            case "Süpermarket": keywords = ["kahve", "deterjan", "bebek", "bez", "gida", "atistirmalik"]
            case "Ev & Yaşam": keywords = ["mobilya", "dekorasyon", "masa", "lamba"]
            default: keywords = []
            }
            
            if !keywords.isEmpty {
                result = result.filter { product in
                    let normalizedTitle = product.title.searchNormalized
                    return keywords.contains { keyword in
                        normalizedTitle.contains(keyword)
                    }
                }
            }
        }
        
        switch selectedSort {
        case .priceAsc:
            result.sort { ($0.instantDiscountPrice ?? $0.price) < ($1.instantDiscountPrice ?? $1.price) }
        case .priceDesc:
            result.sort { ($0.instantDiscountPrice ?? $0.price) > ($1.instantDiscountPrice ?? $1.price) }
        case .topRated:
            result.sort { ($0.rate ?? 0) > ($1.rate ?? 0) }
        case .none:
            break
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { category in
                                Text(category)
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.n11Accent : Color.gray.opacity(0.1)) // TEMA RENGİ
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(20)
                                    .onTapGesture {
                                        withAnimation { selectedCategory = category }
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    
                    if let detail = viewModel.detailedProduct {
                        CampaignProductBubble(detail: detail, cartManager: cartManager)
                    }
                    
                    Divider()
                    
                    if !viewModel.sponsoredProducts.isEmpty && searchText.isEmpty && selectedCategory == "Tümü" {
                        VStack(alignment: .leading) {
                            Text("Bu ürünleri gördünüz mü?")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(viewModel.sponsoredProducts.indices, id: \.self) { index in
                                        let product = viewModel.sponsoredProducts[index]
                                        NavigationLink(destination: ProductDetailLoader(baseProduct: product, favoritesManager: favoritesManager, cartManager: cartManager)) {
                                            ProductCard(product: product, favoritesManager: favoritesManager)
                                                .frame(width: 160)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        Divider()
                    }
                    
                    HStack {
                        Text("Tüm Ürünler")
                            .font(.headline)
                        Spacer()
                        Menu {
                            Picker("Sıralama", selection: $selectedSort) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.arrow.down")
                                Text(selectedSort.rawValue)
                            }
                            .font(.subheadline)
                            .foregroundColor(.n11Accent) // TEMA RENGİ
                        }
                    }
                    .padding(.horizontal)
                    
                    if filteredAndSortedProducts.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("Aradığınız kriterlere uygun ürün bulunamadı.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(filteredAndSortedProducts.indices, id: \.self) { index in
                                let product = filteredAndSortedProducts[index]
                                NavigationLink(destination: ProductDetailLoader(baseProduct: product, favoritesManager: favoritesManager, cartManager: cartManager)) {
                                    ProductCard(product: product, favoritesManager: favoritesManager)
                                        .onAppear {
                                            if index == filteredAndSortedProducts.count - 1 {
                                                viewModel.loadNextPage()
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        
                        if viewModel.isLoadingMore {
                            ProgressView("Daha fazla yükleniyor...")
                                .padding()
                                .frame(maxWidth: .infinity)
                        }
                        
                        Spacer().frame(height: 130)
                    }
                }
            }
            .navigationTitle("n11 Klon")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Ürün, kategori veya marka ara")
        }
    }
}

// MARK: - Favoriler Sayfası
struct FavoritesView: View {
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var cartManager: CartManager
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if favoritesManager.favoriteProducts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Henüz favori ürününüz yok.")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(favoritesManager.favoriteProducts.indices, id: \.self) { index in
                            let product = favoritesManager.favoriteProducts[index]
                            NavigationLink(destination: ProductDetailLoader(baseProduct: product, favoritesManager: favoritesManager, cartManager: cartManager)) {
                                ProductCard(product: product, favoritesManager: favoritesManager)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 15)
                    .padding(.bottom, 130)
                }
            }
            .navigationTitle("Favorilerim")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Dinamik Ürün Detay Yükleyici
struct ProductDetailLoader: View {
    let baseProduct: Product
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var cartManager: CartManager
    
    @State private var productDetail: ProductDetail?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Ürün bilgileri getiriliyor...")
                        .font(.callout)
                        .foregroundColor(.gray)
                }
            } else if let detail = productDetail {
                FullProductDetailView(baseProduct: baseProduct, productDetail: detail, cartManager: cartManager)
            } else {
                Text("Ürün bilgisine ulaşılamadı.")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            fetchDetail()
        }
    }
    
    private func fetchDetail() {
        guard let url = URL(string: "https://private-d3ae2-n11case.apiary-mock.com/product?productId=\(baseProduct.id)") else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let data = data {
                    do {
                        self.productDetail = try JSONDecoder().decode(ProductDetail.self, from: data)
                    } catch {
                        print("Detay sayfası parse hatası: \(error)")
                    }
                }
            }
        }.resume()
    }
}

// MARK: - Ürün Kartı
struct ProductCard: View {
    let product: Product
    @ObservedObject var favoritesManager: FavoritesManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: product.validImageUrl) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Color.gray.opacity(0.1)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                Button(action: {
                    favoritesManager.toggleFavorite(product: product)
                }) {
                    Image(systemName: favoritesManager.isFavorite(product: product) ? "heart.fill" : "heart")
                        .foregroundColor(favoritesManager.isFavorite(product: product) ? .n11Accent : .black) // TEMA RENGİ
                        .font(.system(size: 20))
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 3)
                }
                .padding(.top, 8)
                .padding(.trailing, 2)
            }
            
            Text(product.title)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(minHeight: 40, alignment: .topLeading)
                .padding(.horizontal, 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(String(format: "%.2f", product.price)) TL")
                    .font(.caption)
                    .strikethrough()
                    .foregroundColor(.secondary)
                
                if let discountPrice = product.instantDiscountPrice {
                    Text("\(String(format: "%.2f", discountPrice)) TL")
                        .font(.headline)
                        .bold()
                } else {
                    Text(" ")
                        .font(.headline)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Gelişmiş Detay Sayfası
struct FullProductDetailView: View {
    var baseProduct: Product? = nil
    let productDetail: ProductDetail
    @ObservedObject var cartManager: CartManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                TabView {
                    if let mainImage = baseProduct?.validImageUrl {
                        AsyncImage(url: mainImage) { image in
                            image.resizable().scaledToFit()
                        } placeholder: { ProgressView() }
                    } else {
                        ForEach(productDetail.validImageUrls, id: \.self) { url in
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFit()
                            } placeholder: { ProgressView() }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .frame(height: 350)
                .background(Color.white)
                
                VStack(alignment: .leading, spacing: 12) {
                    
                    Text(baseProduct?.title ?? productDetail.title)
                        .font(.title3)
                        .bold()
                    
                    if let rate = baseProduct?.rate ?? productDetail.rate {
                        HStack {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(rate) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 12))
                            }
                            Text("\(String(format: "%.1f", rate))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let seller = baseProduct?.sellerName ?? productDetail.sellerName {
                        Text("Satıcı: \(seller)")
                            .font(.subheadline)
                            .foregroundColor(.n11Accent) // TEMA RENGİ
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(String(format: "%.2f", baseProduct?.price ?? productDetail.price)) TL")
                                .strikethrough()
                                .foregroundColor(.gray)
                            
                            if let discountPrice = baseProduct?.instantDiscountPrice ?? productDetail.instantDiscountPrice {
                                Text("\(String(format: "%.2f", discountPrice)) TL")
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(.green)
                            }
                        }
                        Spacer()
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ürün Özellikleri")
                            .font(.headline)
                        
                        Text(productDetail.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Spacer(minLength: 20)
                    
                    if let product = baseProduct {
                        let quantity = cartManager.getQuantity(for: product)
                        
                        HStack(spacing: 15) {
                            if quantity > 0 {
                                HStack(spacing: 20) {
                                    Button(action: {
                                        cartManager.removeFromCart(product: product)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.red)
                                    }
                                    
                                    Text("\(quantity)")
                                        .font(.title2)
                                        .bold()
                                        .frame(minWidth: 30)
                                    
                                    Button(action: {
                                        cartManager.addToCart(product: product)
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(.trailing, 10)
                            }
                            
                            Button(action: {
                                if quantity == 0 {
                                    cartManager.addToCart(product: product)
                                }
                            }) {
                                Text(quantity == 0 ? "Sepete Ekle" : "Sepete Eklendi")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(quantity == 0 ? Color.green : Color.gray)
                                    .cornerRadius(10)
                            }
                            .disabled(quantity > 0)
                        }
                    } else {
                        Text("Bu, özel indirimli bir kampanya ürünüdür. Lütfen sepete eklemek için detay sayfasına gitmek yerine sepet üzerinden doğrudan işlem yapınız.")
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}

// MARK: - Şans Çarkı (Bana Ne Var) - Ödül Tanımları

struct WheelPrize: Identifiable, Equatable {
    let id = UUID()
    let label: String        // Çarkta görünen yazı
    let codePrefix: String?  // Kupon kodunun ilk 3 hanesi (nil = kazanç yok, kupon üretilmez)
}

let wheelPrizes: [WheelPrize] = [
    WheelPrize(label: "Kazanamadın", codePrefix: nil),
    WheelPrize(label: "150 TL", codePrefix: "150"),
    WheelPrize(label: "250 TL", codePrefix: "250"),
    WheelPrize(label: "400 TL", codePrefix: "400"),
    WheelPrize(label: "%20", codePrefix: "P20"),
    WheelPrize(label: "%50", codePrefix: "P50"),
    WheelPrize(label: "%10", codePrefix: "P10"),
    WheelPrize(label: "%25", codePrefix: "P25")
]

// MARK: - İndirim Kodu Sistemi
// Kod 8 haneli: ilk 3 hane indirimin ne olduğunu taşır, kalan 5 hane rastgele harftir.
// TL indirimleri: sayı doğrudan yazılır -> "150", "250", "400"
// Yüzde indirimleri: 3 haneye sığmadığı için başına P konur -> "P10", "P20", "P25", "P50"
// Böylece kod okunduğu anda (henüz hiçbir yere kaydedilmeden) sistem ne indirimi olduğunu anlayabilir.
// Kodun kullanılıp kullanılmadığı ise CouponManager'ın sakladığı listede bu tam koda karşılık gelen
// "isUsed" alanıyla takip edilir; rastgele son 5 harf her kuponu birbirinden ayıran benzersiz anahtardır.

enum DiscountValue: Equatable {
    case amount(Int)   // TL indirimi
    case percent(Int)  // Yüzde indirimi

    var displayText: String {
        switch self {
        case .amount(let tl): return "\(tl) TL"
        case .percent(let p): return "%\(p)"
        }
    }
}

enum DiscountCodeSystem {
    /// Kod her zaman küçük harfle saklanır (kanonik form); ekranda gösterirken .uppercased() kullanılır.
    /// Bu sayede kullanıcı kodu ister büyük ister küçük harfle yapıştırsın, karşılaştırma her zaman tutarlı olur.
    static func generateCode(prefix: String) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz"
        let suffix = String((0..<5).compactMap { _ in letters.randomElement() })
        return prefix.lowercased() + suffix
    }

    /// Kodun ilk 3 hanesine bakarak indirim tipini/miktarını çözer.
    static func parse(_ rawCode: String) -> DiscountValue? {
        let code = rawCode.lowercased()
        guard code.count == 8 else { return nil }
        let prefix = String(code.prefix(3))
        if prefix.hasPrefix("p"), let percent = Int(prefix.dropFirst()) {
            return .percent(percent)
        }
        if let tl = Int(prefix) {
            return .amount(tl)
        }
        return nil
    }
}

// MARK: - Kupon Modeli

struct DiscountCoupon: Codable, Identifiable, Equatable {
    var id: String { code }
    let code: String
    let prefix: String
    let createdAt: Date
    var isUsed: Bool = false
}

// MARK: - Kupon Yöneticisi (üretim + saklama + kullanıldı/kullanılmadı takibi)

final class CouponManager: ObservableObject {
    @Published private(set) var coupons: [DiscountCoupon] = []

    private let storageKey = "n11klon_generated_coupons"

    init() {
        load()
    }

    /// Verilen ödül için 8 haneli benzersiz kupon üretir, saklar ve döner.
    /// "Kazanamadın" için (codePrefix nil) kupon üretilmez.
    @discardableResult
    func generateCoupon(for prize: WheelPrize) -> DiscountCoupon? {
        guard let prefix = prize.codePrefix else { return nil }

        var newCode = DiscountCodeSystem.generateCode(prefix: prefix)
        while coupons.contains(where: { $0.code == newCode }) {
            newCode = DiscountCodeSystem.generateCode(prefix: prefix)
        }

        let coupon = DiscountCoupon(code: newCode, prefix: prefix.lowercased(), createdAt: Date(), isUsed: false)
        coupons.append(coupon)
        save()
        return coupon
    }

    /// Kuponu kullanıldı olarak işaretler (sepette/ödemede kupon uygulanırken çağrılabilir).
    func markUsed(code: String) {
        guard let index = coupons.firstIndex(where: { $0.code == code }) else { return }
        coupons[index].isUsed = true
        save()
    }

    func isUsed(code: String) -> Bool {
        coupons.first(where: { $0.code == code })?.isUsed ?? false
    }

    private func save() {
        if let data = try? JSONEncoder().encode(coupons) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([DiscountCoupon].self, from: data) {
            coupons = decoded
        }
    }
}

// MARK: - Çark Dilimi Şekli (8 eşit dilim, elle hesaplanmış yay - addArc belirsizliğinden kaçınmak için)

struct WheelSlice: Shape {
    let startAngle: Double // derece, saat 12 hizasından saat yönünde
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)

        let steps = 24
        for step in 0...steps {
            let t = Double(step) / Double(steps)
            let angleDeg = startAngle + (endAngle - startAngle) * t
            let angleRad = angleDeg * .pi / 180
            let x = center.x + radius * sin(angleRad)
            let y = center.y - radius * cos(angleRad)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Şans Çarkı Görünümü (Bana Ne Var)

struct SpinWheelView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var couponManager = CouponManager()

    @State private var shuffledPrizes: [WheelPrize] = wheelPrizes.shuffled()
    @State private var rotation: Double = 0
    @State private var isSpinning: Bool = false
    @State private var lastDragAngle: Double? = nil
    @State private var lastDragTime: Date = Date()
    @State private var angularVelocity: Double = 0 // derece / saniye

    @State private var showResult: Bool = false
    @State private var resultPrize: WheelPrize? = nil
    @State private var resultCoupon: DiscountCoupon? = nil
    @State private var didCopyCode: Bool = false

    private let wheelDiameter: CGFloat = 300
    private let sliceAngle: Double = 45 // 360 / 8

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 36) {
                    Text("Çarkı basılı tutup çevir, nerede durursa onu kazan!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 10)

                    ZStack {
                        // Sabit gösterge (ok) - dönmez
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.black)
                            .offset(y: -wheelDiameter / 2 - 8)
                            .zIndex(2)

                        // Sadece görsel: dönen çark yüzü
                        wheelFace
                            .rotationEffect(.degrees(rotation))
                            .allowsHitTesting(false)

                        // Sabit, görünmez sürükleme katmanı - açı hesabı hep bunun üzerinden yapılır,
                        // böylece çarkın kendi rotationEffect'i dokunma koordinatlarını etkilemez.
                        Color.clear
                            .contentShape(Circle())
                            .frame(width: wheelDiameter, height: wheelDiameter)
                            .gesture(dragGesture)
                    }
                    .frame(width: wheelDiameter, height: wheelDiameter + 40)

                    Text(isSpinning ? "Çark dönüyor..." : "Başlamak için çarka dokun ve çevir")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    Spacer()
                }

                if showResult {
                    resultOverlay
                }
            }
            .navigationTitle("Bana Ne Var")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: Çarkın Görseli

    private var wheelFace: some View {
        ZStack {
            ForEach(Array(shuffledPrizes.enumerated()), id: \.offset) { index, prize in
                let start = Double(index) * sliceAngle
                let end = start + sliceAngle
                let mid = start + sliceAngle / 2
                let isBlackSlice = index % 2 == 0

                WheelSlice(startAngle: start, endAngle: end)
                    .fill(isBlackSlice ? Color.black : Color.n11Accent)

                Text(prize.label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isBlackSlice ? Color.n11Accent : Color.black)
                    .multilineTextAlignment(.center)
                    .frame(width: 64)
                    .fixedSize(horizontal: false, vertical: true)
                    .offset(y: -wheelDiameter * 0.32)
                    .rotationEffect(.degrees(mid))
            }

            Circle()
                .fill(Color.white)
                .frame(width: 54, height: 54)
                .overlay(Circle().stroke(Color.black, lineWidth: 2))
                .overlay(
                    Image(systemName: "gift.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.n11Accent)
                )
        }
        .frame(width: wheelDiameter, height: wheelDiameter)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.black, lineWidth: 4))
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
    }

    // MARK: Basılı Tutup Çevirme Hareketi

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !isSpinning else { return }

                let center = CGPoint(x: wheelDiameter / 2, y: wheelDiameter / 2)
                let currentAngle = rawAngle(from: center, to: value.location)
                let now = Date()

                if let last = lastDragAngle {
                    var delta = currentAngle - last
                    if delta > 180 { delta -= 360 }
                    if delta < -180 { delta += 360 }

                    rotation += delta

                    let dt = now.timeIntervalSince(lastDragTime)
                    if dt > 0 {
                        let instantVelocity = delta / dt
                        angularVelocity = (angularVelocity * 0.7) + (instantVelocity * 0.3)
                    }
                }

                lastDragAngle = currentAngle
                lastDragTime = now
            }
            .onEnded { _ in
                guard !isSpinning else { return }
                lastDragAngle = nil
                spinToStop()
            }
    }

    private func rawAngle(from center: CGPoint, to point: CGPoint) -> Double {
        let dx = point.x - center.x
        let dy = point.y - center.y
        var degrees = atan2(dy, dx) * 180 / .pi
        if degrees < 0 { degrees += 360 }
        return degrees
    }

    // MARK: Parmak Kalkınca Yavaşlayarak Durma

    private func spinToStop() {
        isSpinning = true

        let direction: Double = angularVelocity >= 0 ? 1 : -1
        let baseSpeed = min(max(abs(angularVelocity), 90), 1800) // çok yavaş ya da aşırı hızlı olmasın
        let extraTurns = Double.random(in: 3...6) * 360
        let randomOffset = Double.random(in: 0..<360)
        let travel = extraTurns + (baseSpeed * 0.5) + randomOffset

        let finalRotation = rotation + (direction * travel)
        let duration = 4.0

        withAnimation(.timingCurve(0.12, 0.85, 0.25, 1.0, duration: duration)) {
            rotation = finalRotation
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            finishSpin(at: finalRotation)
        }
    }

    private func finishSpin(at finalRotation: Double) {
        let normalized = finalRotation.truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        let pointerAngleOnWheel = (360 - positive).truncatingRemainder(dividingBy: 360)
        let index = Int(pointerAngleOnWheel / sliceAngle) % shuffledPrizes.count

        let prize = shuffledPrizes[index]
        resultPrize = prize
        resultCoupon = couponManager.generateCoupon(for: prize)
        didCopyCode = false
        isSpinning = false
        angularVelocity = 0

        withAnimation {
            showResult = true
        }
    }

    // MARK: Sonuç Kartı

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                if let prize = resultPrize, let coupon = resultCoupon {
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.n11Accent)

                    Text("Tebrikler!")
                        .font(.title2).bold()

                    Text("\(prize.label) değerinde kupon kazandın")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    HStack {
                        Text(coupon.code.uppercased())
                            .font(.system(.title3, design: .monospaced))
                            .bold()
                            .kerning(2)

                        Button(action: {
                            UIPasteboard.general.string = coupon.code.uppercased()
                            didCopyCode = true
                        }) {
                            Image(systemName: didCopyCode ? "checkmark.circle.fill" : "doc.on.doc")
                                .foregroundColor(didCopyCode ? .green : .n11Accent)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.06))
                    .cornerRadius(10)

                    if didCopyCode {
                        Text("Kod kopyalandı")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Image(systemName: "face.dashed")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("Bu sefer olmadı")
                        .font(.title2).bold()

                    Text("Kazanamadın, tekrar deneyebilirsin")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Button(action: {
                    withAnimation {
                        showResult = false
                    }
                    shuffledPrizes = wheelPrizes.shuffled()
                }) {
                    Text("Tamam")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.n11Accent)
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(20)
            .padding(.horizontal, 40)
            .shadow(radius: 20)
        }
    }
}
