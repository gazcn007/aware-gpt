//
//  HallucinationDetectorCoreML.swift
//  AwareGPT
//
//  CoreML-based hallucination detector
//

import CoreML
import Foundation

class HallucinationDetectorCoreML {
  private var model: neural_network?

  init() {
    loadModel()
  }

  private func loadModel() {
    // Try different possible locations and names
    var modelURL: URL?

    // IMPORTANT: Xcode compiles .mlpackage to .mlmodelc during build
    // So we need to look for .mlmodelc in the bundle, not .mlpackage

    // First try: neural_network.mlmodelc (compiled CoreML model in bundle)
    if let url = Bundle.main.url(forResource: "neural_network", withExtension: "mlmodelc") {
      modelURL = url
      print("📦 Found compiled model (.mlmodelc) at: \(url.path)")
    }
    // Second try: neural_network.mlpackage (if not compiled, though unlikely in production)
    else if let url = Bundle.main.url(forResource: "neural_network", withExtension: "mlpackage") {
      modelURL = url
      print("📦 Found model package (.mlpackage) at: \(url.path)")
    }
    // Third try: check subdirectories
    else if let resourcePath = Bundle.main.resourcePath {
      let possiblePaths = [
        "\(resourcePath)/neural_network.mlmodelc",
        "\(resourcePath)/neural_network.mlpackage",
        "\(resourcePath)/MLModels/neural_network.mlmodelc",
        "\(resourcePath)/MLModels/neural_network.mlpackage",
      ]

      for path in possiblePaths {
        if FileManager.default.fileExists(atPath: path) {
          modelURL = URL(fileURLWithPath: path)
          print("📦 Found model at: \(path)")
          break
        }
      }
    }

    // Third try: For development/debugging, try to find it in the project directory
    // This is a fallback and won't work in production, but helps during development
    #if DEBUG
      if modelURL == nil {
        let projectPaths = [
          "AwareGPT/MLModels/neural_network.mlpackage",
          "MLModels/neural_network.mlpackage",
        ]

        for relativePath in projectPaths {
          let fullPath = (FileManager.default.currentDirectoryPath as NSString)
            .appendingPathComponent(relativePath)
          if FileManager.default.fileExists(atPath: fullPath) {
            modelURL = URL(fileURLWithPath: fullPath)
            print("📦 Found model in project directory (DEBUG only): \(fullPath)")
            print("   ⚠️ This won't work in production - ensure file is in app bundle!")
            break
          }
        }
      }
    #endif

    // Final fallback: if mlmodelc exists in bundle but url() didn't find it, use direct path
    if modelURL == nil, let resourcePath = Bundle.main.resourcePath {
      let directPath = "\(resourcePath)/neural_network.mlmodelc"
      if FileManager.default.fileExists(atPath: directPath) {
        modelURL = URL(fileURLWithPath: directPath)
        print("📦 Found model using direct path: \(directPath)")
      }
    }

    guard let url = modelURL else {
      print("⚠️ CoreML model not found: neural_network.mlmodelc or neural_network.mlpackage")
      print("   Searched in Bundle.main for both .mlmodelc and .mlpackage")
      if let resourcePath = Bundle.main.resourcePath {
        print("   Resource path: \(resourcePath)")
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) {
          print("   Bundle contents: \(contents)")
        }
      }
      print("   ⚠️ Make sure the .mlpackage file is:")
      print("      1. Added to your Xcode project")
      print("      2. Included in the 'AwareGPT' target")
      print("      3. Listed in 'Build Phases' > 'Copy Bundle Resources'")
      return
    }

    do {
      let config = MLModelConfiguration()
      // Use CPU and Neural Engine for best performance
      config.computeUnits = .cpuAndNeuralEngine

      model = try neural_network(contentsOf: url, configuration: config)
      print("✓ Successfully loaded CoreML model: neural_network")

      // Print model info for debugging
      printModelInfo()
    } catch {
      print("✗ Failed to load CoreML model: \(error)")
      print("   Error details: \(error.localizedDescription)")
      if let nsError = error as NSError? {
        print("   Domain: \(nsError.domain), Code: \(nsError.code)")
        print("   UserInfo: \(nsError.userInfo)")
      }
    }
  }

  /// Preprocess FC activations to match model input requirements
  func preprocessFCActivations(_ activations: [[Float]]) -> [Float] {
    // Flatten: [layers, hidden_dim] -> [layers * hidden_dim]
    let flattened = activations.flatMap { $0 }

    // Expected size from the model (adjust based on your model's input)
    // For now, using 2204 as that was the ONNX model size
    let expectedSize = 2204
    var processed = Array(flattened.prefix(expectedSize))

    // Pad with zeros if needed
    while processed.count < expectedSize {
      processed.append(0.0)
    }

    return processed
  }

  /// Predict hallucination probability
  /// - Parameter fcActivations: 2D array of FC activations [layers, hidden_dim]
  /// - Returns: Tuple of (probability: Float, isHallucination: Bool) or nil if prediction fails
  func predict(fcActivations: [[Float]]) -> (probability: Float, isHallucination: Bool)? {
    guard let model = model else {
      print("⚠️ Model not loaded")
      return nil
    }

    // Preprocess activations
    let processed = preprocessFCActivations(fcActivations)

    do {
      // Create MLMultiArray from the processed activations
      // Model expects rank 2: [batch_size, features] = [1, 2204]
      guard let inputArray = try? MLMultiArray(shape: [1, 2204], dataType: .float32) else {
        print("✗ Failed to create MLMultiArray")
        return nil
      }

      // Copy data into MLMultiArray
      // For 2D array, we need to calculate the index: row * numColumns + column
      for (index, value) in processed.enumerated() {
        let row = 0  // batch index
        let col = index  // feature index
        let arrayIndex = row * 2204 + col
        inputArray[arrayIndex] = NSNumber(value: value)
      }

      // Create input - the input name is "features" based on the model
      let input = try neural_networkInput(features: inputArray)

      // Make prediction
      let prediction = try model.prediction(input: input)

      // Extract outputs - adjust based on your CoreML model's output structure
      // Common outputs: label (Int64), probability (MLMultiArray or Dictionary)
      var probability: Float = 0.5
      var isHallucination: Bool = false

      // Debug: Print all available output features
      let output = prediction
      print("🔍 Available output features:")
      // Access feature names through the model description or try to get them from the output
      let mlModel = model.model
      for (name, desc) in mlModel.modelDescription.outputDescriptionsByName {
        print("   - \(name): type=\(desc.type)")
      }

      // Try to get probability output using featureValue
      // The actual output name is "hallucination_probability" based on the model
      let probOutputNames = [
        "hallucination_probability",  // Your model's actual output name
        "probability", "probabilities", "output_probability", "confidence", "output",
      ]
      var foundProb = false
      for probName in probOutputNames {
        if let probOutput = output.featureValue(for: probName) {
          print("🔍 Found probability output: \(probName), type: \(probOutput.type)")
          foundProb = true
          // Check if it's a multi-array
          if probOutput.type == .multiArray, let multiArray = probOutput.multiArrayValue {
            print("   MultiArray shape: \(multiArray.shape), count: \(multiArray.count)")
            // If it's a multi-array, get the probability of class 1 (hallucination)
            if multiArray.count >= 2 {
              probability = Float(truncating: multiArray[1])
              print("   ✓ Extracted probability[1] = \(probability)")
              break
            } else if multiArray.count == 1 {
              probability = Float(truncating: multiArray[0])
              print("   ✓ Extracted probability[0] = \(probability)")
              break
            }
          }
          // Check if it's a dictionary
          else if probOutput.type == .dictionary {
            let dict = probOutput.dictionaryValue
            print("   Dictionary keys: \(dict.keys)")
            // If it's a dictionary, get the probability for class 1
            if let probValue = dict["1"] as? NSNumber {
              probability = Float(truncating: probValue)
              print("   ✓ Extracted probability from dict[\"1\"] = \(probability)")
              break
            } else if let probValue = dict[1] as? NSNumber {
              probability = Float(truncating: probValue)
              print("   ✓ Extracted probability from dict[1] = \(probability)")
              break
            } else {
              // Try to get any value from the dictionary
              if let firstValue = dict.values.first as? NSNumber {
                probability = Float(truncating: firstValue)
                print("   ⚠️ Using first dictionary value = \(probability)")
                break
              }
            }
          }
          // Check if it's a double (type 5 = MLFeatureType.double)
          else if probOutput.type == .double {
            probability = Float(probOutput.doubleValue)
            print("   ✓ Extracted probability from double = \(probability)")
            break
          }
          // Also check for type 5 explicitly (in case enum comparison doesn't work)
          else if probOutput.type.rawValue == 5 {
            // Type 5 is double
            probability = Float(probOutput.doubleValue)
            print("   ✓ Extracted probability from type 5 (double) = \(probability)")
            break
          }
        }
      }

      if !foundProb {
        print("⚠️ No probability output found with common names. Trying direct property access...")
        // Try accessing properties directly on the prediction object
        // The CoreML generated class might have direct properties
        let mirror = Mirror(reflecting: prediction)
        print("   Prediction object properties:")
        for child in mirror.children {
          if let label = child.label {
            print("     - \(label): \(type(of: child.value))")
            // Try to get the value if it's a property
            if label == "hallucination_probability" || label.contains("probability") {
              print("       Value: \(child.value)")
            }
          }
        }

        // Also try to access all feature values
        print("   All feature values in output:")
        let mlModel = model.model
        for (name, _) in mlModel.modelDescription.outputDescriptionsByName {
          if let featureValue = output.featureValue(for: name) {
            print("     - \(name): type=\(featureValue.type), value=\(featureValue)")
            // Try to extract the actual value
            if featureValue.type == .double {
              print("       Double value: \(featureValue.doubleValue)")
            } else if featureValue.type == .int64 {
              print("       Int64 value: \(featureValue.int64Value)")
            } else if featureValue.type == .multiArray,
              let multiArray = featureValue.multiArrayValue
            {
              print("       MultiArray shape: \(multiArray.shape), count: \(multiArray.count)")
              if multiArray.count > 0 {
                print("       First value: \(multiArray[0])")
              }
            } else if featureValue.type == .dictionary {
              print("       Dictionary: \(featureValue.dictionaryValue)")
            }
          }
        }
      }

      // Try to get label/class prediction
      // Common output names: "label", "classLabel", "output_label", "prediction", etc.
      let labelOutputNames = ["label", "classLabel", "output_label", "prediction", "class"]
      for labelName in labelOutputNames {
        if let labelOutput = output.featureValue(for: labelName) {
          // Check if it's an Int64
          if labelOutput.type == .int64 {
            isHallucination = (labelOutput.int64Value == 1)
            break
          }
          // Check if it's a multi-array
          else if labelOutput.type == .multiArray, let multiArray = labelOutput.multiArrayValue,
            multiArray.count > 0
          {
            let predictedClass = Int64(truncating: multiArray[0])
            isHallucination = (predictedClass == 1)
            break
          }
          // Check if it's a string
          else if labelOutput.type == .string {
            // Sometimes labels are strings like "0" or "1"
            isHallucination = (labelOutput.stringValue == "1")
            break
          }
        }
      }

      // Fallback: determine from probability
      if probability > 0.5 && !isHallucination {
        isHallucination = true
      }

      return (probability, isHallucination)

    } catch {
      print("✗ Prediction error: \(error)")
      return nil
    }
  }

  /// Alternative: Predict using embeddings if FC activations aren't available
  func predictFromEmbeddings(_ embeddings: [Float]) -> (probability: Float, isHallucination: Bool)?
  {
    // Convert embeddings to 2D format expected by the model
    let activations = [embeddings]  // Single layer
    return predict(fcActivations: activations)
  }

  /// Debug: Print model information
  func printModelInfo() {
    guard let model = model else {
      print("⚠️ Model not loaded")
      return
    }

    print("\n=== CoreML Model Information ===")
    let mlModel = model.model
    print("Model description: \(mlModel.modelDescription)")
    print("Input descriptions:")
    for (name, desc) in mlModel.modelDescription.inputDescriptionsByName {
      print("  \(name): \(desc)")
    }
    print("Output descriptions:")
    for (name, desc) in mlModel.modelDescription.outputDescriptionsByName {
      print("  \(name): \(desc)")
    }
    print("===============================\n")
  }
}
