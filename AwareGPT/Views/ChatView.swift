//
//  ChatView.swift
//  AwareGPT
//
//  Created by AI Assistant on 2025-12-07.
//

import SwiftData
import SwiftUI

struct ChatView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var llmService: LLMService
  @Bindable var conversation: Conversation

  @State private var inputText: String = ""
  @State private var isGenerating: Bool = false
  @State private var scrollProxy: ScrollViewProxy?

  @AppStorage("systemPrompt") private var systemPrompt = "You are a helpful assistant."
  @AppStorage("temperature") private var temperature = 0.7
  @AppStorage("seed") private var seed = 42
  @AppStorage("useRandomSeed") private var useRandomSeed = true

  var body: some View {
    VStack(spacing: 0) {
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(spacing: 16) {
            ForEach(conversation.messages.sorted(by: { $0.createdAt < $1.createdAt })) { message in
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

      VStack(spacing: 0) {
        Divider()
        HStack(alignment: .bottom) {
          TextField("Message...", text: $inputText, axis: .vertical)
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)
            .lineLimit(1...5)

          Button(action: sendMessage) {
            Image(systemName: "arrow.up.circle.fill")
              .resizable()
              .frame(width: 32, height: 32)
          }
          .disabled(
            inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating
          )
          .padding(.bottom, 2)
        }
        .padding()
      }
      .background(.regularMaterial)
    }
    .navigationTitle(conversation.title)
    .navigationBarTitleDisplayMode(.inline)
  }

  private func sendMessage() {
    guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

    let userMessage = Message(role: .user, content: inputText)
    userMessage.conversation = conversation  // Explicitly set relationship
    conversation.messages.append(userMessage)

    // Save user message immediately
    try? modelContext.save()

    let promptText = inputText
    inputText = ""
    isGenerating = true

    Task {
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

        for try await result in stream {
          // Append text tokens
          if !result.text.isEmpty {
            assistantMessage.content += result.text
          }

          // Update hallucination score when available
          if let score = result.hallucinationScore {
            assistantMessage.hallucinationScore = score
          }
        }

        // Final save
        try? modelContext.save()
      } catch {
        assistantMessage.content += "\n[Error: \(error.localizedDescription)]"
      }

      isGenerating = false
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
            .background(Color.blue)
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
