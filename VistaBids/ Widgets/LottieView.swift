//
//  LottieView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-07-22.
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let name: String
        var loopMode: LottieLoopMode = .loop

        func makeUIView(context: Context) -> UIView {
            let view = UIView(frame: .zero)
            let animationView = LottieAnimationView(name: name)
            animationView.loopMode = loopMode
            animationView.play()
            animationView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(animationView)

            NSLayoutConstraint.activate([
                animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
                animationView.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
            return view
        }

        func updateUIView(_ uiView: UIView, context: Context) {}
    }


