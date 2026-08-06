import SwiftUI
import Combine
import Foundation
import UIKit


extension String {
    /// Metni Türkçe karakterlerden (diacritic) ve büyük harf duyarlılığından arındırır.
    var searchNormalized: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "tr_TR"))
    }
}
//  String Search.swift
//  ETdeneme
//
//  Created by yigit.korkmaz on 6.08.2026.
//

