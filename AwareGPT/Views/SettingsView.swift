//
//  SettingsView.swift
//  AwareGPT
//
//  Created by AI Assistant on 2025-12-07.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Conversation.createdAt) private var conversations: [Conversation]

  @AppStorage("systemPrompt") private var systemPrompt =
    "You are a helpful assistant similar to ChatGPT."
  @AppStorage("temperature") private var temperature = 0.7
  @AppStorage("seed") private var seed = 42
  @AppStorage("useRandomSeed") private var useRandomSeed = true
  @AppStorage("hapticFeedback") private var hapticFeedback = true
  @AppStorage("contextWindow") private var contextWindow = 2048.0

  @State private var showClearConfirmation = false
  @State private var showCustomerStory = false

  var body: some View {
    Form {
      Section {
        Button(action: {
          showCustomerStory = true
        }) {
          HStack {
            Label("Customer Story", systemImage: "book.fill")
            Spacer()
            Image(systemName: "chevron.right")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }

      Section(header: Text("Assistant")) {
        VStack(alignment: .leading) {
          Text("System Prompt")
            .font(.headline)
          TextEditor(text: $systemPrompt)
            .frame(height: 100)
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.vertical, 5)
      }

      Section(header: Text("Intelligence")) {
        VStack(alignment: .leading) {
          Text("Meta Llama 3.2 - 1B")
            .font(.headline)
          Text("Very small and fast chat model. Runs well on most mobile devices.")
            .font(.caption)
            .foregroundColor(.secondary)

          Label("Local", systemImage: "lock.fill")
            .font(.caption)
            .padding(4)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(4)
        }
        .padding(.vertical, 5)
      }

      Section(header: Text("Chat Settings")) {
        Toggle("Haptic feedback", isOn: $hapticFeedback)

        Toggle("Random seed", isOn: $useRandomSeed)

        if !useRandomSeed {
          HStack {
            Text("Seed")
            Spacer()
            TextField("Seed", value: $seed, formatter: NumberFormatter())
              .keyboardType(.numberPad)
              .multilineTextAlignment(.trailing)
              .frame(width: 100)
          }
        }

        VStack(alignment: .leading) {
          Text("Temperature: \(String(format: "%.1f", temperature))")
          Slider(value: $temperature, in: 0...1, step: 0.1)
          Text(
            "Controls the creativity of responses; lower values make answers more focused, while higher values increase randomness."
          )
          .font(.caption)
          .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)

        VStack(alignment: .leading) {
          Text("Context window: \(Int(contextWindow))")
          Slider(value: $contextWindow, in: 512...4096, step: 512)
          Text(
            "Maximum number of tokens the model can process at once. Higher values use more memory but allow longer conversations."
          )
          .font(.caption)
          .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
      }

      Section {
        Button("Clear conversation history", role: .destructive) {
          showClearConfirmation = true
        }
      }

      Section {
        VStack(spacing: 8) {
          Text("0.0.1")
            .font(.caption)
            .foregroundColor(.secondary)

          Text("Research Project")
            .font(.caption)
            .foregroundColor(.secondary)

          Text("Made with ❤️ by Manuel Cardenas & Carl Liu")
            .font(.caption)
            .foregroundColor(.secondary)

          Text("at Stanford University")
            .font(.caption)
            .foregroundColor(.secondary)

          Link("csliu@stanford.edu", destination: URL(string: "mailto:csliu@stanford.edu")!)
            .font(.caption)
            .foregroundColor(.accentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
      }
    }
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
    .fullScreenCover(isPresented: $showCustomerStory) {
      OnboardingView(isPresented: $showCustomerStory)
    }
    .alert("Clear All Conversations", isPresented: $showClearConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Clear", role: .destructive) {
        clearAllConversations()
      }
    } message: {
      Text(
        "This will permanently delete all conversations and messages. This action cannot be undone."
      )
    }
  }

  private func clearAllConversations() {
    withAnimation {
      for conversation in conversations {
        modelContext.delete(conversation)
      }
      do {
        try modelContext.save()
      } catch {
        print("Failed to clear conversations: \(error.localizedDescription)")
      }
    }
  }
}

#Preview {
  NavigationStack {
    SettingsView()
  }
}
