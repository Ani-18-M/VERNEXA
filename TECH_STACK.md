# VERNEXA - Complete Tech Stack Specification

**Project Goal**: Offline-first Android application enabling bidirectional speech-to-speech translation and curriculum learning between Hindi and regional/tribal languages.

---

## 1. High-Level Architecture Overview

```
+-----------------------------------------------------------------------------------+
|                              Flutter Android Client                               |
|                                                                                   |
|  +-----------------------+     +------------------------+     +----------------+  |
|  | Audio I/O (`record`)  | --> | Voice Activity (VAD)   | --> | Audio Buffer   |  |
|  +-----------------------+     +------------------------+     +----------------+  |
|                                                                       |           |
|                                                                       v           |
|  +-----------------------------------------------------------------------------+  |
|  |                   Edge AI Inference Engine (Sherpa-ONNX)                    |  |
|  |                                                                             |  |
|  |  +-------------------+     +---------------------+     +-----------------+  |  |
|  |  | Offline ASR (STT) | --> | Translation (NMT)   | --> | Offline TTS     |  |  |
|  |  | (Zipformer/Wav2Vec|     | (IndicTrans/NLLB)   |     | (VITS / Piper)  |  |  |
|  |  +-------------------+     +---------------------+     +-----------------+  |  |
|  +-----------------------------------------------------------------------------+  |
|                                         |                             |           |
|                                         v                             v           |
|  +---------------------------------------------+     +-------------------------+  |
|  |  Offline Database (Drift / SQLite)          |     | Audio Output            |  |
|  |  - Lexicons & Fallback Phrasebook           |     | (`just_audio`)          |  |
|  |  - Multilingual Curriculum & Progress       |     +-------------------------+  |
|  +---------------------------------------------+                                  |
+-----------------------------------------------------------------------------------+
```

---

## 2. Technology Stack Matrix

| Category | Component / Library | Role & Rationale |
| :--- | :--- | :--- |
| **Mobile Framework** | **Flutter (Dart 3.x)** | Cross-platform offline mobile UI, high-performance rendering, strong FFI/native plugin support. |
| **State Management** | **Flutter BLoC** or **Riverpod** | Deterministic state flow for audio pipelines, model loading states, and offline learning modules. |
| **Audio Capture** | **`record`** / **`flutter_sound`** | Streams 16 kHz 16-bit mono PCM audio from microphone directly to the inference buffer. |
| **Audio Playback** | **`just_audio`** | Ultra-low-latency local playback for synthesized speech and pre-cached educational clips. |
| **Edge AI Engine** | **`sherpa_onnx`** (Flutter) | Integrated C++ runtime for offline ASR, TTS, and VAD without custom audio DSP code in Dart. |
| **General ONNX Runtime** | **`onnxruntime_flutter`** | Powers the quantized translation models (Hindi <-> Tribal) on device CPU / NNAPI. |
| **Offline Database** | **`drift`** (SQLite abstraction) | Type-safe SQL database with reactive Streams, schema migrations, and fast relational indexing. |
| **Local File & Key-Value Storage** | **`path_provider`** & **`hive_flutter`** | Fast caching for model weight assets, voice audio files, and user preferences. |
| **AI/NLP Training** | **Python (PyTorch, HF Transformers)** | Dataset preparation, data augmentation, model fine-tuning, and model pruning. |
| **Model Quantization** | **Hugging Face `optimum[onnxruntime]`** | Quantizing PyTorch checkpoints to INT8/UINT8 ONNX models for mobile efficiency. |
| **Transliteration** | **`indic-transliteration`** | Handling dialect script variations (e.g., Devanagari, Ol Chiki, Latin/Roman scripts). |

---

## 3. Speech & NLP Model Strategy

Because Indian tribal languages are low-resource, standard general-purpose models (like base Whisper) often struggle without specialized transfer learning.

### A. Speech-to-Text (ASR)
- **Base Architecture**: Conformer-CTC, Zipformer, or fine-tuned IndicWav2Vec / Whisper-tiny.
- **Runtime**: Sherpa-ONNX offline recognizer.
- **Audio Spec**: 16,000 Hz, 16-bit, Single-channel Mono PCM.

### B. Machine Translation (NMT: Hindi <-> Tribal)
- **Base Architecture**: 
  - **IndicTrans2** (AI4Bharat) or **NLLB-200** (Meta, distilled 600M).
  - For small micro-models on edge: Quantized MarianMT Seq2Seq.
- **Hybrid Fallback (Crucial for Low-Resource Languages)**:
  - Exact/Fuzzy match dictionary stored in SQLite for common phrases, emergency phrases, and school curriculum terms.
  - If model confidence is low, fall back to rule-based dictionary lookup.

### C. Text-to-Speech (TTS)
- **Base Architecture**: VITS or Piper TTS trained/fine-tuned on local phonetic voice datasets.
- **Runtime**: Sherpa-ONNX offline synthesizer.
- **Asset Fallback**: Pre-recorded human voice clips for core lesson vocabulary.

---

## 4. Hardware Budget & Optimization Constraints

Target Devices: Android phones in rural/semi-urban areas (often **2GB to 4GB RAM**, ARM64/ARMv7 processors).

1. **Model Quantization**: All weights converted to **INT8** (Integer 8-bit quantization), reducing model size by ~75% and enabling fast integer math on mobile CPUs.
2. **Memory Footprint Goal**: Total resident app memory during active translation should remain **under 350 MB RAM**.
3. **Sequential Model Invocation**:
   - Step 1: Run ASR -> Release ASR working tensors -> Output text.
   - Step 2: Run NMT -> Release NMT working tensors -> Output translated text.
   - Step 3: Run TTS -> Release TTS working tensors -> Output audio waveform.
   - Avoid executing all 3 models in memory simultaneously on 2GB RAM devices.
4. **App Delivery / Modular Packages**:
   - Core APK: UI + Database + Default vocabulary (~30-50MB).
   - Language Packs: Downloaded on first setup or transferred via offline sharing (ShareIt / Bluetooth / SD card).

---

## 5. Recommended Directory Layout for the Project

```
VERNEXA/
├── mobile_app/                 # Flutter Application
│   ├── android/
│   ├── lib/
│   │   ├── core/               # Audio services, permissions, constants
│   │   ├── data/               # Drift database, repositories, offline storage
│   │   ├── domain/             # Entities, translation & speech contracts
│   │   ├── presentation/       # UI screens, widgets, BLoC/providers
│   │   └── ai_engine/          # Sherpa-ONNX & ONNX Runtime wrappers
│   ├── assets/
│   │   ├── models/             # Quantized .onnx / .tflite models & tokens
│   │   ├── audio/              # Pre-recorded standard curriculum audio
│   │   └── data/               # Initial SQLite seed data / dictionaries
│   └── pubspec.yaml
│
├── ai_pipeline/                # Python Model Development & Conversion
│   ├── data/                   # Raw audio & parallel translation corpora
│   ├── scripts/
│   │   ├── preprocess.py       # Audio normalizer, transliteration, tokenization
│   │   ├── train_finetune.py   # PyTorch / Hugging Face fine-tuning script
│   │   └── export_onnx.py      # INT8 ONNX export & verification
│   └── requirements.txt
│
└── TECH_STACK.md               # This specification document
```
