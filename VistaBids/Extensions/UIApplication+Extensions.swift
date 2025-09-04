//
//  UIApplication+Extensions.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-06.
//

import UIKit

extension UIApplication {
    var keyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    var rootViewController: UIViewController? {
        return keyWindow?.rootViewController
    }
}
