//
//  ChatView.swift
//  AwareGPT
//
//  Created by AI Assistant on 2025-12-07.
//

import SwiftData
import SwiftUI
import UIKit

struct ChatView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var llmService: LLMService
  @Bindable var conversation: Conversation

  @State private var inputText: String = ""
  @State private var isGenerating: Bool = false
  @State private var scrollProxy: ScrollViewProxy?
  @State private var hasStartedLoading = false
  @State private var isFirstMessage = false

  @AppStorage("systemPrompt") private var systemPrompt = "You are a helpful assistant."
  @AppStorage("temperature") private var temperature = 0.7
  @AppStorage("seed") private var seed = 42
  @AppStorage("useRandomSeed") private var useRandomSeed = true
  @AppStorage("hapticFeedback") private var hapticFeedback = true
  @AppStorage("hasSentFirstMessage") private var hasSentFirstMessage = false

  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        ScrollViewReader { proxy in
          ScrollView {
            LazyVStack(spacing: 16) {
              ForEach(conversation.messages.sorted(by: { $0.createdAt < $1.createdAt })) {
                message in
                MessageBubble(message: message)
                  .id(message.id)
              }

              if isGenerating {
                HStack {
                  ProgressView()
                    .padding()
                  Spacer()
                }
              }
            }
            .padding()
          }
          .onChange(of: conversation.messages) {
            scrollToBottom(proxy: proxy)
          }
          .onAppear {
            self.scrollProxy = proxy
            scrollToBottom(proxy: proxy)
          }
        }

        // Floating Liquid Glass input
        HStack(alignment: .bottom, spacing: 0) {
          // Text input with liquid glass effect
          HStack(alignment: .bottom, spacing: 0) {
            TextField("Message...", text: $inputText, axis: .vertical)
              .padding(.leading, 20)
              .padding(.trailing, 12)
              .padding(.vertical, 14)
              .lineLimit(1...5)
              .disabled(!llmService.isModelLoaded || isGenerating)

            // Send button integrated into input
            Button(action: sendMessage) {
              Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(
                  inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || isGenerating || !llmService.isModelLoaded
                    ? Color.secondary.opacity(0.4)
                    : Color.accentColor
                )
            }
            .disabled(
              inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating
                || !llmService.isModelLoaded
            )
            .padding(.trailing, 12)
            .padding(.bottom, 6)
          }
          .background {
            // Floating liquid glass background with advanced blur and gradient
            ZStack {
              // Base blur material
              RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)

              // Subtle inner glow
              RoundedRectangle(cornerRadius: 28)
                .fill(
                  LinearGradient(
                    colors: [
                      .white.opacity(0.15),
                      .white.opacity(0.05),
                      .clear,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
                )

              // Glass border with gradient
              RoundedRectangle(cornerRadius: 28)
                .strokeBorder(
                  LinearGradient(
                    colors: [
                      .white.opacity(0.4),
                      .white.opacity(0.2),
                      .white.opacity(0.1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  ),
                  lineWidth: 1.5
                )
            }
            .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 10)
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 5)
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, max(12, 0))  // Account for safe area
      }

      // Loading overlay when model is not loaded
      if !llmService.isModelLoaded && llmService.error == nil {
        ModelLoadingOverlay()
      }

      // Loading overlay during generation - only show on first message
      if isGenerating && llmService.isModelLoaded && isFirstMessage {
        GeneratingOverlay()
      }
    }
    .navigationTitle(conversation.title)
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      // Start loading model when chat view appears
      if !hasStartedLoading && !llmService.isModelLoaded {
        hasStartedLoading = true
        Task {
          await llmService.loadModel()
        }
      }
    }
  }

  private func sendMessage() {
    guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

    // Check if this is the first message ever
    let isFirstEver = !hasSentFirstMessage
    if isFirstEver {
      isFirstMessage = true
      hasSentFirstMessage = true
    }

    let userMessage = Message(role: .user, content: inputText)
    userMessage.conversation = conversation  // Explicitly set relationship
    conversation.messages.append(userMessage)

    // Save user message immediately
    try? modelContext.save()

    let promptText = inputText
    inputText = ""
    isGenerating = true

    Task { @MainActor in
      // Create and prepare haptic feedback generator on main thread
      let generator = UIImpactFeedbackGenerator(style: .medium)
      if hapticFeedback {
        generator.prepare()
      }
      var lastHapticTime: Date = Date()
      let hapticInterval: TimeInterval = 0.2  // Haptic every 200ms during streaming
      var tokenCount = 0

      let assistantMessage = Message(role: .assistant, content: "")
      assistantMessage.conversation = conversation
      conversation.messages.append(assistantMessage)

      let currentSeed = useRandomSeed ? Int.random(in: 0...100000) : seed

      do {
        let stream = llmService.chat(
          history: conversation.messages.filter { $0.role != .assistant || !$0.content.isEmpty },  // basic filter
          systemPrompt: systemPrompt,
          temperature: temperature,
          seed: currentSeed
        )

        // Use Task.withTimeout pattern for proper timeout handling
        try await withThrowingTaskGroup(of: Void.self) { group in
          // Stream processing task
          group.addTask { @MainActor in
            for try await result in stream {
              // Append text tokens
              if !result.text.isEmpty {
                assistantMessage.content += result.text
                tokenCount += 1

                // Haptic feedback during streaming (like ChatGPT)
                // Must be on main thread
                if hapticFeedback {
                  let now = Date()
                  if now.timeIntervalSince(lastHapticTime) >= hapticInterval {
                    // Use slightly higher intensity for better feel
                    generator.impactOccurred(intensity: 0.5)
                    lastHapticTime = now
                    // Re-prepare for next haptic
                    generator.prepare()
                  }
                }

                // Save periodically to prevent data loss (every 10 tokens)
                if tokenCount % 10 == 0 {
                  try? modelContext.save()
                }
              }

              // Update hallucination score when available
              if let score = result.hallucinationScore {
                assistantMessage.hallucinationScore = score
                // Update conversation average confidence
                updateConversationConfidence()
              }
            }
          }

          // Timeout task
          group.addTask {
            try await Task.sleep(nanoseconds: 60_000_000_000)  // 60 seconds
            throw NSError(
              domain: "ChatView", code: 1,
              userInfo: [NSLocalizedDescriptionKey: "Generation timeout after 60 seconds"])
          }

          // Wait for first task to complete (either stream finishes or timeout)
          try await group.next()
          group.cancelAll()  // Cancel remaining tasks
        }

        // Final save
        try? modelContext.save()
      } catch {
        if assistantMessage.content.isEmpty {
          assistantMessage.content = "[Error: \(error.localizedDescription)]"
        } else {
          assistantMessage.content += "\n\n[Error: \(error.localizedDescription)]"
        }
        try? modelContext.save()
      }

      isGenerating = false
      isFirstMessage = false  // Reset after first message completes

      // Final update of conversation confidence
      updateConversationConfidence()
    }
  }

  private func updateConversationConfidence() {
    // Calculate average confidence from all assistant messages with scores
    let assistantMessages = conversation.messages.filter { $0.role == .assistant }
    let scores = assistantMessages.compactMap { $0.hallucinationScore }

    if !scores.isEmpty {
      let average = scores.reduce(0, +) / Double(scores.count)
      conversation.averageConfidence = average
      try? modelContext.save()
    }
  }

  private func scrollToBottom(proxy: ScrollViewProxy) {
    guard let lastMessage = conversation.messages.sorted(by: { $0.createdAt < $1.createdAt }).last
    else { return }
    withAnimation {
      proxy.scrollTo(lastMessage.id, anchor: .bottom)
    }
  }
}

struct MessageBubble: View {
  let message: Message

  var body: some View {
    VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
      HStack {
        if message.role == .user {
          Spacer()
          Text(message.content)
            .padding(12)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(16)
            .textSelection(.enabled)
        } else {
          Text(message.content)
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .foregroundColor(.primary)
            .cornerRadius(16)
            .textSelection(.enabled)
          Spacer()
        }
      }

      // Show confidence score for assistant messages
      if message.role == .assistant, let score = message.hallucinationScore {
        HStack(spacing: 8) {
          Text("Confidence:")
            .font(.caption2)
            .foregroundColor(.secondary)

          GeometryReader { geometry in
            ZStack(alignment: .leading) {
              Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 6)
                .cornerRadius(3)
              Rectangle()
                .fill(score > 0.7 ? Color.green : score > 0.4 ? Color.orange : Color.red)
                .frame(width: geometry.size.width * CGFloat(score), height: 6)
                .cornerRadius(3)
            }
          }
          .frame(width: 100, height: 6)

          Text("\(Int(score * 100))%")
            .font(.caption2)
            .foregroundColor(.secondary)
            .frame(width: 35, alignment: .trailing)
        }
        .padding(.horizontal, message.role == .user ? 0 : 12)
      }
    }
  }
}
