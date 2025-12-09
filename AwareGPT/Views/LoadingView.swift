//
//  LoadingView.swift
//  AwareGPT
//
//  Created by AI Assistant on 2025-12-07.
//

import SwiftUI

struct LoadingView: View {
  var body: some View {
    ZStack {
      Color(.systemBackground)
        .ignoresSafeArea()
      
      VStack(spacing: 20) {
        // Lottie animation placeholder - will be replaced with actual Lottie view
        // For now, using a simple animated view
        LoadingAnimation()
          .frame(width: 200, height: 200)
        
        Text("Loading models...")
          .font(.title2)
          .foregroundColor(.secondary)
        
        Text("Please wait while we initialize the language model")
          .font(.caption)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
      }
    }
  }
}

struct LoadingAnimation: View {
  @State private var rotation: Double = 0
  @State private var scale: CGFloat = 0.8
  
  var body: some View {
    ZStack {
      // Animated gradient circles - placeholder for Lottie animation
      // TODO: Replace with Lottie animation using loading.json
      // To use Lottie: Add lottie-ios package and use LottieView
      ForEach(0..<4) { index in
        Circle()
          .trim(from: 0, to: 0.6)
          .stroke(
            AngularGradient(
              colors: [
                .blue.opacity(0.3),
                .purple.opacity(0.6),
                .pink.opacity(0.6),
                .blue.opacity(0.3)
              ],
              center: .center,
              angle: .degrees(rotation + Double(index * 90))
            ),
            style: StrokeStyle(lineWidth: 6, lineCap: .round)
          )
          .frame(width: 120 - CGFloat(index * 15), height: 120 - CGFloat(index * 15))
          .rotationEffect(.degrees(rotation + Double(index * 90)))
          .scaleEffect(scale)
      }
    }
    .onAppear {
      // Rotation animation
      withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
        rotation = 360
      }
      // Pulse animation
      withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
        scale = 1.0
      }
    }
  }
}

#Preview {
  LoadingView()
}

