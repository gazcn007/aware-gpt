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

  // Initialize SwiftData container at app startup with proper error handling
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Conversation.self,
      Message.self,
    ])

    // Ensure the application support directory exists
    // SwiftData will create its files here automatically
    let appSupportURL = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first!

    do {
      try FileManager.default.createDirectory(
        at: appSupportURL,
        withIntermediateDirectories: true,
        attributes: nil
      )
      print("✓ Application Support directory ready at: \(appSupportURL.path)")
    } catch {
      print("⚠️ Failed to create Application Support directory: \(error.localizedDescription)")
    }

    // Use default ModelConfiguration - SwiftData will handle file location
    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false
    )

    do {
      let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
      print("✓ SwiftData initialized successfully")
      return container
    } catch {
      print("✗ Failed to create ModelContainer: \(error.localizedDescription)")
      // Try with in-memory storage as fallback
      do {
        let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [inMemoryConfig])
        print("⚠️ Using in-memory storage (data will not persist)")
        return container
      } catch {
        // This should never happen, but if it does, we need to crash gracefully
        fatalError("Could not create ModelContainer: \(error.localizedDescription)")
      }
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
