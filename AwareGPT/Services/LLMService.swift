//
//  LLMService.swift
//  AwareGPT
//
//  Created by AI Assistant on 2025-12-07.
//

import Combine
import Foundation
import SwiftLlama

struct ChatResult {
  let text: String
  let hallucinationScore: Double?  // 0.0 to 1.0, where higher = more likely hallucination
}

@MainActor
class LLMService: ObservableObject {
  @Published var isModelLoaded = false
  @Published var error: String?

  private var llamaService: LlamaService?
  private let config: LlamaConfig
  private let hallucinationDetector = HallucinationDetectorCoreML()

  init() {
    // Default config - can be adjusted based on settings
    self.config = LlamaConfig(
      batchSize: 256,
      maxTokenCount: 2048,
      useGPU: true
    )
    // Don't load model automatically - will be loaded when chat opens
  }

  func loadModel() async {
    guard let modelPath = Bundle.main.path(forResource: "LFM2-1.2B-Q4_K_M", ofType: "gguf") else {
      self.error =
        "Model file not found. Please download LFM2-1.2B-Q4_K_M.gguf and add it to the project."
      return
    }

    do {
      let modelUrl = URL(fileURLWithPath: modelPath)
      self.llamaService = LlamaService(modelUrl: modelUrl, config: config)
      self.isModelLoaded = true
    } catch {
      self.error = "Failed to load model: \(error.localizedDescription)"
    }
  }

  func chat(history: [Message], systemPrompt: String, temperature: Double, seed: Int)
    -> AsyncThrowingStream<ChatResult, Error>
  {
    return AsyncThrowingStream { continuation in
      guard let llamaService = self.llamaService else {
        continuation.finish(
          throwing: NSError(
            domain: "LLMService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"]
          ))
        return
      }

      Task {
        do {
          // Convert our Message array to LlamaChatMessage array
          var llamaMessages: [LlamaChatMessage] = []

          // Add system message if provided
          if !systemPrompt.isEmpty {
            llamaMessages.append(LlamaChatMessage(role: .system, content: systemPrompt))
          }

          // Add conversation history
          for message in history {
            let role: LlamaChatMessage.Role = message.role == .user ? .user : .assistant
            llamaMessages.append(LlamaChatMessage(role: role, content: message.content))
          }

          // Create sampling config
          let samplingConfig = LlamaSamplingConfig(
            temperature: Float(temperature),
            seed: UInt32(seed)
          )

          // Get the stream from LlamaService
          let stream = try await llamaService.streamCompletion(
            of: llamaMessages, samplingConfig: samplingConfig)

          var fullText = ""
          var tokenCount = 0
          let maxTokens = 1000  // Safety limit to prevent infinite generation

          // Forward tokens to our continuation
          for try await token in stream {
            fullText += token
            tokenCount += 1

            // Stream text as it comes
            continuation.yield(ChatResult(text: token, hallucinationScore: nil))

            // Safety check: prevent infinite generation
            if tokenCount >= maxTokens {
              print("⚠️ Reached max token limit (\(maxTokens)), stopping generation")
              break
            }

            // Check for common stop patterns
            if fullText.hasSuffix("<|im_end|>") || fullText.hasSuffix("\n\n\n") {
              // Natural stopping point
              break
            }
          }

          // After completion, compute hallucination score
          // Note: We need to get embeddings/activations from the model
          // For now, we'll use a placeholder approach - you may need to access
          // the underlying Llama actor to get FC activations
          let hallucinationScore = await computeHallucinationScore(
            for: fullText,
            llamaService: llamaService
          )

          // Send final result with score
          continuation.yield(ChatResult(text: "", hallucinationScore: hallucinationScore))
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }

  /// Compute hallucination score using CoreML model
  ///
  /// IMPORTANT: To get real FC activations, you need to:
  /// 1. Access the underlying Llama actor from LlamaService (requires modifying SwiftLlama)
  /// 2. Or use embeddings as a proxy (if your model supports it)
  /// 3. Or implement a custom inference path that captures activations during forward pass
  ///
  /// Current implementation uses placeholder activations for testing.
  /// To extract real FC activations:
  /// - The LFM2-1.2B model has ~14 transformer layers
  /// - Each layer has FC (fully connected) activations you need to capture
  /// - These should be extracted during the forward pass, not after completion
  private func computeHallucinationScore(for text: String, llamaService: LlamaService) async
    -> Double?
  {
    // TODO: Extract actual FC activations from intermediate transformer layers
    //
    // Option 1: Modify SwiftLlama to expose the underlying Llama actor and call:
    //   let llama = await llamaService.contextHandle() // If exposed
    //   let embeddings = await llama.getEmbeddings() // Get final embeddings
    //   // Then extract FC activations from each layer during inference
    //
    // Option 2: Use embeddings as proxy (if your CoreML model was trained on embeddings):
    //   let embeddings = await getEmbeddingsFromModel(...)
    //   return hallucinationDetector.predictFromEmbeddings(embeddings)
    //
    // Option 3: Implement custom inference that captures activations at each layer

    // PLACEHOLDER: Using dummy activations for testing
    // Replace this with actual FC activations from the model
    // Expected format: [[Float]] where each inner array is activations from one layer
    // For LFM2-1.2B: ~14 layers, each with ~2048 hidden dimensions
    let dummyActivations: [[Float]] = (0..<14).map { layerIndex in
      // In reality, these would be the FC layer outputs from each transformer block
      Array(repeating: Float.random(in: -1...1), count: 2048)
    }

    if let result = hallucinationDetector.predict(fcActivations: dummyActivations) {
      return Double(result.probability)
    }

    return nil
  }
}
