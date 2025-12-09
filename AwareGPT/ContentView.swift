//
//  ContentView.swift
//  AwareGPT
//
//  Created by Carl Liu on 2025-12-07.
//

import SwiftData
import SwiftUI

struct ContentView: View {
  @State private var selectedConversation: Conversation?
  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  @EnvironmentObject var llmService: LLMService

  var body: some View {
    NavigationSplitView {
      HistoryView(selectedConversation: $selectedConversation)
    } detail: {
      if let conversation = selectedConversation {
        ChatView(conversation: conversation)
      } else {
        VStack(spacing: 20) {
          Image(systemName: "bubble.left.and.bubble.right")
            .font(.system(size: 60))
            .foregroundStyle(.tint)
          Text("Select or start a new chat")
            .font(.title2)
            .foregroundColor(.secondary)
        }
      }
    }
  }
}

#Preview {
  ContentView()
    .modelContainer(for: Conversation.self, inMemory: true)
    .environmentObject(LLMService())
}
