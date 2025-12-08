//
//  HistoryView.swift
//  AwareGPT
//
//  Created by AI Assistant on 2025-12-07.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.createdAt, order: .reverse) private var conversations: [Conversation]
    @Binding var selectedConversation: Conversation?
    @State private var showingSettings = false
    
    var body: some View {
        List(selection: $selectedConversation) {
            ForEach(conversations) { conversation in
                NavigationLink(value: conversation) {
                    VStack(alignment: .leading) {
                        Text(conversation.title.isEmpty ? "New Chat" : conversation.title)
                            .font(.headline)
                        Text(conversation.createdAt.formatted(date: .numeric, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
}

