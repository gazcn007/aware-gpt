//
//  ModelLoadingOverlay.swift
//  AwareGPT
//
//  Created by AI Assistant on 2025-12-07.
//

import SwiftUI
import Lottie

struct ModelLoadingOverlay: View {
  var body: some View {
    ZStack {
      // Semi-transparent background
      Color(.systemBackground)
        .opacity(0.95)
        .ignoresSafeArea()
      
      VStack(spacing: 24) {
        // Lottie animation placeholder
        // TODO: To use actual Lottie animation:
        // 1. Add lottie-ios package: https://github.com/airbnb/lottie-ios
        // 2. Import Lottie
        // 3. Replace LoadingAnimation with:
        //    LottieView(animation: .named("loading"))
        //      .playing(loopMode: .loop)
        //      .frame(width: 200, height: 200)
        LottieView(animation: .named("loading"))
          .playing(loopMode: .loop)
          .animationSpeed(1.0)
          .frame(width: 200, height: 200)
          
        VStack(spacing: 8) {
          Text("Warming things up")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
          
          Text("Loading the local language model...")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
      }
    }
  }
}

#Preview {
  ModelLoadingOverlay()
}

