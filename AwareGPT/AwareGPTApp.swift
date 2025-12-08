//
//  AwareGPTApp.swift
//  AwareGPT
//
//  Created by Carl Liu on 2025-12-07.
//

import SwiftData
import SwiftUI

@main
struct AwareGPTApp: App {
  @StateObject private var llmService = LLMService()

  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Conversation.self,
      Message.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(llmService)
    }
    .modelContainer(sharedModelContainer)
  }
}
