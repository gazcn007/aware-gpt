//
//  ChatAnalyticsView.swift
//  AwareGPT
//
//  Created by AI Assistant on 2025-12-07.
//

import Charts
import SwiftUI

struct ChatAnalyticsView: View {
  let conversation: Conversation
  @Environment(\.dismiss) private var dismiss

  // Heartbeat animation state
  @State private var pulseScale: CGFloat = 1.0
  @State private var glowOpacity: Double = 0.3

  // Calculate statistics
  private var assistantMessages: [Message] {
    conversation.messages.filter { $0.role == .assistant }
  }

  private var messagesWithScores: [Message] {
    assistantMessages.filter { $0.hallucinationScore != nil }
  }

  private var averageConfidence: Double {
    guard !messagesWithScores.isEmpty else { return 0.0 }
    let sum = messagesWithScores.reduce(0.0) { $0 + ($1.hallucinationScore ?? 0.0) }
    return sum / Double(messagesWithScores.count)
  }

  private var confidenceData: [ConfidenceDataPoint] {
    messagesWithScores.enumerated().map { index, message in
      ConfidenceDataPoint(
        index: index,
        confidence: message.hallucinationScore ?? 0.0,
        date: message.createdAt
      )
    }
  }

  private var highConfidenceCount: Int {
    messagesWithScores.filter { ($0.hallucinationScore ?? 0.0) >= 0.7 }.count
  }

  private var mediumConfidenceCount: Int {
    messagesWithScores.filter {
      let score = $0.hallucinationScore ?? 0.0
      return score >= 0.4 && score < 0.7
    }.count
  }

  private var lowConfidenceCount: Int {
    messagesWithScores.filter { ($0.hallucinationScore ?? 0.0) < 0.4 }.count
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 32) {
          // Overall Confidence Card
          overallConfidenceCard

          // Trend Chart
          trendChartCard

          // Confidence Breakdown
          confidenceBreakdownCard
        }
        .padding()
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle("Analytics")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.secondary)
          }
        }
      }
    }
  }

  // MARK: - Overall Confidence Card
  private var overallConfidenceCard: some View {
    VStack(spacing: 20) {
      Text("Overall Confidence")
        .font(.headline)
        .foregroundColor(.secondary)

      ZStack {
        // Glow effect (outer ring)
        Circle()
          .stroke(
            confidenceColor(averageConfidence).opacity(glowOpacity),
            style: StrokeStyle(lineWidth: 24, lineCap: .round)
          )
          .frame(width: 200, height: 200)
          .scaleEffect(pulseScale)
          .blur(radius: 4)

        // Background circle
        Circle()
          .stroke(Color.secondary.opacity(0.2), lineWidth: 20)
          .frame(width: 180, height: 180)

        // Confidence circle with pulse
        Circle()
          .trim(from: 0, to: averageConfidence)
          .stroke(
            confidenceColor(averageConfidence),
            style: StrokeStyle(lineWidth: 20, lineCap: .round)
          )
          .frame(width: 180, height: 180)
          .rotationEffect(.degrees(-90))
          .scaleEffect(pulseScale)
          .animation(.spring(response: 0.8, dampingFraction: 0.7), value: averageConfidence)

        // Percentage text with subtle pulse
        VStack(spacing: 4) {
          Text("\(Int(averageConfidence * 100))%")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundColor(confidenceColor(averageConfidence))
            .scaleEffect(pulseScale * 0.98)  // Slightly less pulse on text
          Text("Average")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }
    }
    .frame(maxWidth: .infinity)
    .padding(24)
    .background {
      RoundedRectangle(cornerRadius: 20)
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    .onAppear {
      startHeartbeatAnimation()
    }
  }

  private func startHeartbeatAnimation() {
    // Heartbeat effect: quick pulse, pause, quick pulse, longer pause
    withAnimation(.easeInOut(duration: 0.15)) {
      pulseScale = 1.08
      glowOpacity = 0.6
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      withAnimation(.easeInOut(duration: 0.2)) {
        pulseScale = 1.0
        glowOpacity = 0.3
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
      withAnimation(.easeInOut(duration: 0.15)) {
        pulseScale = 1.06
        glowOpacity = 0.5
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
      withAnimation(.easeInOut(duration: 0.25)) {
        pulseScale = 1.0
        glowOpacity = 0.3
      }
    }

    // Repeat after a pause (heartbeat rhythm)
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      startHeartbeatAnimation()
    }
  }

  // MARK: - Trend Chart Card
  private var trendChartCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Confidence Trend")
        .font(.headline)
        .foregroundColor(.primary)

      if confidenceData.isEmpty {
        VStack(spacing: 12) {
          Image(systemName: "chart.line.uptrend.xyaxis")
            .font(.system(size: 40))
            .foregroundColor(.secondary.opacity(0.5))
          Text("No data yet")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
      } else {
        Chart {
          // Target line (70% confidence threshold)
          RuleMark(y: .value("Target", 0.7))
            .foregroundStyle(Color.blue.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            .annotation(position: .top, alignment: .trailing) {
              Text("Target")
                .font(.caption2)
                .foregroundColor(.secondary)
            }

          // Confidence line
          ForEach(confidenceData) { dataPoint in
            LineMark(
              x: .value("Message", dataPoint.index),
              y: .value("Confidence", dataPoint.confidence)
            )
            .foregroundStyle(confidenceGradient)
            .interpolationMethod(.catmullRom)
            .symbol {
              Circle()
                .fill(confidenceColor(dataPoint.confidence))
                .frame(width: 6, height: 6)
            }

            AreaMark(
              x: .value("Message", dataPoint.index),
              y: .value("Confidence", dataPoint.confidence)
            )
            .foregroundStyle(
              LinearGradient(
                colors: [
                  confidenceColor(dataPoint.confidence).opacity(0.3),
                  confidenceColor(dataPoint.confidence).opacity(0.05),
                ],
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .interpolationMethod(.catmullRom)
          }
        }
        .chartYScale(domain: 0...1)
        .chartXAxis {
          AxisMarks(values: .automatic) { _ in
            AxisGridLine()
            AxisValueLabel()
          }
        }
        .chartYAxis {
          AxisMarks(position: .leading, values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
            AxisGridLine()
            AxisValueLabel {
              if let doubleValue = value.as(Double.self) {
                Text("\(Int(doubleValue * 100))%")
                  .font(.caption2)
                  .foregroundColor(.secondary)
              }
            }
          }
        }
        .frame(height: 200)
      }
    }
    .padding(20)
    .background {
      RoundedRectangle(cornerRadius: 20)
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
  }

  // MARK: - Confidence Breakdown Card
  private var confidenceBreakdownCard: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Confidence Breakdown")
        .font(.headline)
        .foregroundColor(.primary)

      VStack(spacing: 16) {
        // High Confidence
        confidenceStatRow(
          label: "High Confidence",
          count: highConfidenceCount,
          total: messagesWithScores.count,
          color: .green,
          icon: "checkmark.circle.fill"
        )

        // Medium Confidence
        confidenceStatRow(
          label: "Medium Confidence",
          count: mediumConfidenceCount,
          total: messagesWithScores.count,
          color: .orange,
          icon: "exclamationmark.circle.fill"
        )

        // Low Confidence
        confidenceStatRow(
          label: "Low Confidence",
          count: lowConfidenceCount,
          total: messagesWithScores.count,
          color: .red,
          icon: "xmark.circle.fill"
        )
      }
    }
    .padding(20)
    .background {
      RoundedRectangle(cornerRadius: 20)
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
  }

  private func confidenceStatRow(
    label: String,
    count: Int,
    total: Int,
    color: Color,
    icon: String
  ) -> some View {
    HStack(spacing: 16) {
      // Icon
      ZStack {
        Circle()
          .fill(color.opacity(0.2))
          .frame(width: 50, height: 50)
        Image(systemName: icon)
          .font(.system(size: 24))
          .foregroundColor(color)
      }

      // Label and count
      VStack(alignment: .leading, spacing: 4) {
        Text(label)
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundColor(.primary)
        Text("\(count) response\(count == 1 ? "" : "s")")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      // Percentage and progress bar
      VStack(alignment: .trailing, spacing: 6) {
        Text(total > 0 ? "\(Int((Double(count) / Double(total)) * 100))%" : "0%")
          .font(.headline)
          .foregroundColor(color)

        GeometryReader { geometry in
          ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: 4)
              .fill(color.opacity(0.2))
              .frame(height: 8)

            // Progress
            RoundedRectangle(cornerRadius: 4)
              .fill(
                LinearGradient(
                  colors: [color, color.opacity(0.7)],
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
              .frame(
                width: total > 0 ? geometry.size.width * (Double(count) / Double(total)) : 0,
                height: 8
              )
              .animation(.spring(response: 0.6, dampingFraction: 0.8), value: count)
          }
        }
        .frame(width: 80, height: 8)
      }
    }
    .padding(16)
    .background {
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.secondarySystemBackground))
    }
  }

  // MARK: - Helper Functions
  private func confidenceColor(_ confidence: Double) -> Color {
    if confidence >= 0.7 {
      return .green
    } else if confidence >= 0.4 {
      return .yellow
    } else {
      return .red
    }
  }

  private var confidenceGradient: LinearGradient {
    LinearGradient(
      colors: [.green, .orange, .red],
      startPoint: .top,
      endPoint: .bottom
    )
  }
}

struct ConfidenceDataPoint: Identifiable {
  let id = UUID()
  let index: Int
  let confidence: Double
  let date: Date
}

#Preview {
  ChatAnalyticsView(conversation: Conversation())
}
