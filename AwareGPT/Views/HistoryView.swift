//
//  HistoryView.swift
//  AwareGPT
//
//  Created by AI Assistant on 2025-12-07.
//

import SwiftData
import SwiftUI

struct HistoryView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Conversation.createdAt, order: .reverse) private var conversations: [Conversation]
  @Binding var selectedConversation: Conversation?
  @State private var showingSettings = false

  var body: some View {
    List(selection: $selectedConversation) {
      ForEach(conversations) { conversation in
        NavigationLink(value: conversation) {
          HStack(spacing: 12) {
            // Confidence ring
            if let confidence = conversation.averageConfidence {
              ConfidenceRing(confidence: confidence, size: 44)
            } else {
              // Empty ring for new conversations
              ZStack {
                Circle()
                  .stroke(
                    Color.secondary.opacity(0.2),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                  )
                  .frame(width: 44, height: 44)
                Text("—")
                  .font(.system(size: 11, weight: .semibold))
                  .foregroundColor(.secondary)
              }
            }

            // Conversation info
            VStack(alignment: .leading, spacing: 4) {
              Text(conversation.displayTitle)
                .font(.headline)
                .lineLimit(1)

              HStack(spacing: 8) {
                Text(conversation.createdAt.formatted(date: .numeric, time: .shortened))
                  .font(.caption)
                  .foregroundColor(.secondary)

                if let confidence = conversation.averageConfidence {
                  Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)
                  Text("\(Int(confidence * 100))% avg")
                    .font(.caption)
                    .foregroundColor(confidenceColor(confidence))
                }
              }
            }

            Spacer()
          }
          .padding(.vertical, 4)
        }
      }
      .onDelete(perform: deleteConversations)
    }
    .navigationTitle("Chats")
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: createNewChat) {
          Image(systemName: "square.and.pencil")
        }
      }
      ToolbarItem(placement: .navigationBarLeading) {
        Button(action: { showingSettings = true }) {
          Image(systemName: "gear")
        }
      }
    }
    .sheet(isPresented: $showingSettings) {
      NavigationStack {
        SettingsView()
      }
    }
  }

  private func createNewChat() {
    let newChat = Conversation(title: "New Chat")
    modelContext.insert(newChat)
    selectedConversation = newChat
  }

  private func deleteConversations(offsets: IndexSet) {
    withAnimation {
      for index in offsets {
        modelContext.delete(conversations[index])
      }
    }
  }

  private func confidenceColor(_ confidence: Double) -> Color {
    if confidence >= 0.7 {
      return .green
    } else if confidence >= 0.4 {
      return .orange
    } else {
      return .red
    }
  }
}
