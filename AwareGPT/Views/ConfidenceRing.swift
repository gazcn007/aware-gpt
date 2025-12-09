//
//  ConfidenceRing.swift
//  AwareGPT
//
//  Created by AI Assistant on 2025-12-07.
//

import SwiftUI

struct ConfidenceRing: View {
  let confidence: Double  // 0.0 to 1.0
  let size: CGFloat

  init(confidence: Double, size: CGFloat = 44) {
    self.confidence = confidence
    self.size = size
  }

  private var ringColor: Color {
    if confidence >= 0.7 {
      return .green
    } else if confidence >= 0.4 {
      return .orange
    } else {
      return .red
    }
  }

  var body: some View {
    ZStack {
      // Background ring
      Circle()
        .stroke(
          Color.secondary.opacity(0.2),
          style: StrokeStyle(lineWidth: 4, lineCap: .round)
        )
        .frame(width: size, height: size)

      // Confidence ring
      Circle()
        .trim(from: 0, to: confidence)
        .stroke(
          ringColor,
          style: StrokeStyle(lineWidth: 4, lineCap: .round)
        )
        .frame(width: size, height: size)
        .rotationEffect(.degrees(-90))
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: confidence)

      // Percentage text
      Text("\(Int(confidence * 100))")
        .font(.system(size: size * 0.25, weight: .semibold))
        .foregroundColor(ringColor)
    }
  }
}

#Preview {
  HStack(spacing: 20) {
    ConfidenceRing(confidence: 0.95)
    ConfidenceRing(confidence: 0.65)
    ConfidenceRing(confidence: 0.35)
    ConfidenceRing(confidence: 0.0)
  }
  .padding()
}
