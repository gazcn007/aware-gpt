//
//  GeneratingOverlay.swift
//  AwareGPT
//
//  Created by AI Assistant on 2025-12-07.
//

import Lottie
import SwiftUI

struct GeneratingOverlay: View {
  let messages = [
    "Loading Local Language Models...",
    "Loading Neural Networks...",
    "Loading Facts...",
    "Understanding Pipelines...",
  ]

  @State private var currentMessageIndex = 0
  @State private var opacity: Double = 1.0
  @State private var displayText = ""
  @State private var task: Task<Void, Never>?

  var body: some View {
    ZStack {
      // Semi-transparent background
      Color(.systemBackground)
        .opacity(0.7)
        .ignoresSafeArea()

      VStack(spacing: 24) {
        // Lottie animation
        LottieView(animation: .named("loading"))
          .playing(loopMode: .loop)
          .animationSpeed(1.0)
          .frame(width: 150, height: 150)

        VStack(spacing: 8) {
          Text(displayText)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .opacity(opacity)
            .animation(.easeInOut(duration: 0.5), value: opacity)
            .animation(.easeInOut(duration: 0.5), value: displayText)
        }
        .padding(.horizontal, 32)
        .frame(height: 30)
      }
    }
    .onAppear {
      startMessageCycle()
    }
    .onDisappear {
      task?.cancel()
    }
  }

  private func startMessageCycle() {
    // Start with first message
    displayText = messages[0]
    opacity = 1.0

    // Cancel any existing task
    task?.cancel()

    // Create new task to cycle messages
    task = Task {
      while !Task.isCancelled {
        // Wait before transitioning
        try? await Task.sleep(nanoseconds: 5_000_000_000)  // 5 seconds

        guard !Task.isCancelled else { break }

        // Fade out
        await MainActor.run {
          withAnimation(.easeInOut(duration: 0.5)) {
            opacity = 0.0
          }
        }

        // Wait for fade out to complete
        try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

        guard !Task.isCancelled else { break }

        // Change message and fade in
        await MainActor.run {
          currentMessageIndex = (currentMessageIndex + 1) % messages.count
          displayText = messages[currentMessageIndex]

          withAnimation(.easeInOut(duration: 0.5)) {
            opacity = 1.0
          }
        }
      }
    }
  }
}

#Preview {
  GeneratingOverlay()
}
