# AwareGPT

A local AI chat application for iOS that runs Meta's Llama 3.2 1B model entirely on-device, with hallucination detection using CoreML.

## Features

- 🤖 **Local LLM**: Runs Llama 3.2 1B model completely on-device using `swift-llama-cpp`
- 💬 **ChatGPT-like Interface**: Clean, modern chat UI with conversation history
- 🎯 **Hallucination Detection**: Real-time confidence scoring using CoreML neural network
- ⚙️ **Customizable Settings**: Adjust temperature, seed, context window, and more
- 📱 **Privacy-First**: All conversations and models stored locally, no cloud sync

## Requirements

- iOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.6 or later

## Setup

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd AwareGPT
```

### 2. Download the Language Model

The app requires the Llama 3.2 1B model file. Download it from Hugging Face:

**Option A: Using Hugging Face CLI**

```bash
# Install huggingface-cli if you haven't already
pip install huggingface-hub

# Download the model
huggingface-cli download hugging-quants/Llama-3.2-1B-Instruct-Q4_K_M-GGUF llama-3.2-1b-instruct-q4_k_m.gguf --local-dir ./AwareGPT/MLModels
```

**Option B: Manual Download**

1. Visit: https://huggingface.co/hugging-quants/Llama-3.2-1B-Instruct-Q4_K_M-GGUF
2. Download the `llama-3.2-1b-instruct-q4_k_m.gguf` file
3. Place it in `AwareGPT/MLModels/` directory
4. Rename it to `LFM2-1.2B-Q4_K_M.gguf` (or update the filename in `LLMService.swift`)

**Option C: Using Python Script**

```python
from huggingface_hub import hf_hub_download

# Download the model
model_path = hf_hub_download(
    repo_id="hugging-quants/Llama-3.2-1B-Instruct-Q4_K_M-GGUF",
    filename="llama-3.2-1b-instruct-q4_k_m.gguf",
    local_dir="./AwareGPT/MLModels"
)
print(f"Model downloaded to: {model_path}")
```

### 3. Add Model to Xcode Project

1. Open `AwareGPT.xcodeproj` in Xcode
2. Drag the downloaded `.gguf` file into the `AwareGPT/MLModels` folder in Xcode
3. In the dialog, ensure:
   - ✅ "Copy items if needed" is checked
   - ✅ "Add to targets: AwareGPT" is checked
4. Verify the file appears in the Project Navigator

### 4. Install Dependencies

The project uses Swift Package Manager. Dependencies will be automatically resolved when you build:

- `swift-llama-cpp`: For running the Llama model locally
- `onnxruntime-swift-package-manager`: For ONNX model support (if needed)

### 5. Build and Run

1. Select your target device (iPhone or Simulator)
2. Build the project (⌘B)
3. Run the app (⌘R)

## Project Structure

```
AwareGPT/
├── AwareGPT/
│   ├── MLModels/              # Model files (not in git)
│   │   ├── LFM2-1.2B-Q4_K_M.gguf
│   │   └── neural_network.mlpackage
│   ├── Models/                # SwiftData models
│   │   └── ChatModels.swift
│   ├── Services/              # Business logic
│   │   ├── LLMService.swift
│   │   └── HallucinationDetectorCoreML.swift
│   ├── Views/                 # SwiftUI views
│   │   ├── ChatView.swift
│   │   ├── HistoryView.swift
│   │   └── SettingsView.swift
│   ├── AwareGPTApp.swift      # App entry point
│   └── ContentView.swift      # Main view
└── AwareGPT.xcodeproj/
```

## Usage

1. **Start a Chat**: Tap the "+" button or select an existing conversation
2. **Send Messages**: Type your message and tap the send button
3. **View Confidence**: Each assistant response shows a confidence score (green = high, red = low)
4. **Adjust Settings**: Tap the gear icon to customize model parameters

## Model Information

- **Language Model**: Meta Llama 3.2 1B Instruct (Q4_K_M quantization)
- **Size**: ~700MB-1GB
- **Format**: GGUF
- **Hallucination Detector**: CoreML neural network (trained separately)

## Troubleshooting

### Model Not Found Error

If you see "Model file not found":
1. Verify the `.gguf` file is in `AwareGPT/MLModels/`
2. Check the filename matches exactly: `LFM2-1.2B-Q4_K_M.gguf`
3. Ensure the file is added to the "AwareGPT" target in Build Phases
4. Clean build folder (Shift+⌘+K) and rebuild

### Build Errors

- **"No such module 'SwiftLlama'"**: Resolve packages (File > Packages > Resolve Package Versions)
- **"No such module 'onnxruntime'"**: Ensure the package is added to your target
- **Missing Sources phase**: The project should have Sources, Frameworks, and Resources build phases

### Performance

- The model runs best on physical devices (especially with Neural Engine)
- Simulator performance may be slower
- First load takes longer as the model initializes

## License

[Add your license here]

## Acknowledgments

- [swift-llama-cpp](https://github.com/pgorzelany/swift-llama-cpp) for local LLM inference
- [llama.cpp](https://github.com/ggerganov/llama.cpp) for efficient model execution
- Meta for the Llama 3.2 model

