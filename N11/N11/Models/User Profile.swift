import SwiftUI
import Combine
import Foundation
import UIKit


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

//  User Profile.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

