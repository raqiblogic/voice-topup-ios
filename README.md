# VoiceTopup — Native iOS & macOS POC

**Proof of Concept:** Intelligent Voice-Assisted Mobile Recharge & Airtime Top-Up App  
**Platforms:** iOS 17.0+, iPadOS 17.0+, macOS 14.0+ (Apple Silicon)  
**Supported Regions:** Bangladesh (BD) & Malaysia (MY)  
**GitHub Repository:** [https://github.com/raqiblogic/voice-topup-ios](https://github.com/raqiblogic/voice-topup-ios)

---

## 📌 Do I Need to Build from Source or is `.dmg` Enough?

| What You Want to Do | Is `.dmg` Enough? | What You Need |
| :--- | :--- | :--- |
| **Test on Mac (Instant Demo)** |  **YES, `.dmg` is 100% enough!** | Just double-click `VoiceTopup-Mac.dmg`, drag to Applications, and open. **No Xcode or build tools required.** |
| **Run on Physical iPhone** | ⚠️ **Requires Xcode / Code Signing** | Apple requires apps installed directly on physical iPhones to be signed with an Apple ID. (Takes 2 minutes in Xcode). |
| **Run on iOS Simulator** |  **Requires Xcode** | Open project in Xcode, pick any iPhone simulator, press `Cmd + R`. |

---

## 🚀 Option 1: Instant Test on Mac (Zero Build, No Xcode)

If your manager or CTO wants to evaluate the app immediately on their Mac:
1. Double-click **`VoiceTopup-Mac.dmg`** (located in the `Dist/` folder or downloaded).
2. Drag **VoiceTopup.app** into the **Applications** folder.
3. Open **VoiceTopup** from Applications or Spotlight.
4. Grant Microphone & Speech permissions when prompted.
5. Tap the **Mic** button and test voice commands!

---

## 🛠 Option 2: How to Build & Run on Physical iPhone (via Xcode)

Follow these steps to deploy and test directly on a connected iPhone:

### Requirements:
- Mac running macOS Sonoma / Sequoia with **Xcode 15+** or **Xcode 16+**.
- Lightning or USB-C cable to connect the iPhone.
- Any Apple ID (Free personal account, paid Apple Developer Program not required).

### Step-by-Step Instructions:

#### 1. Clone & Open the Project
```bash
git clone https://github.com/raqiblogic/voice-topup-ios.git
cd voice-topup-ios
open VoiceTopup.xcodeproj
```

#### 2. Configure Code Signing (1-Minute Setup)
1. In Xcode's left sidebar, click the top blue **VoiceTopup** icon.
2. Select the **VoiceTopup** target under **TARGETS**.
3. Go to the **Signing & Capabilities** tab.
4. Check **Automatically manage signing**.
5. In the **Team** dropdown, select your **Personal Team** (or click *Add Account...* to log in with your Apple ID).

#### 3. Connect iPhone & Enable Developer Mode (iOS 16+)
1. Plug the iPhone into the Mac using a USB cable.
2. If prompted on the iPhone, tap **Trust This Computer**.
3. On the iPhone, go to **Settings > Privacy & Security > Developer Mode** > toggle **ON** and reboot the iPhone.

#### 4. Build & Install
1. At the top of the Xcode window, click the destination selector next to `VoiceTopup` and choose your connected iPhone (e.g. *Moon's iPhone*).
2. Press **`Cmd + R`** (or click the **▶ Play** button).
3. Xcode will build and install the app on the iPhone.

#### 5. Trust the Free Developer Certificate (First Run Only)
When opening the app for the first time on the iPhone:
1. Open **Settings > General > VPN & Device Management**.
2. Tap your developer Apple ID.
3. Tap **Trust** > **Trust**.
4. Launch **VoiceTopup** from the iPhone home screen!

---

## 🔑 Groq API Key Configuration

The app parses **90%+ of commands on-device without any API key**.

To enable the intelligent Groq LLM fallback for conversational/unstructured speech:
1. Open [`VoiceTopup/Utilities/Secrets.swift`](file:///Users/moon/Projects/VoiceTopup/VoiceTopup/Utilities/Secrets.swift).
2. Set your Groq API key:
   ```swift
   enum Secrets {
       static let groqAPIKey = "gsk_..."
   }
   ```
*(This file is gitignored to ensure API keys are never leaked to source control).*

---

## 📱 Demo Test Scenarios

| Scenario | What to Speak / Do | Expected Result |
| :--- | :--- | :--- |
| **BD English Voice** | *"Send 500 to Mom"* | Resolves contact, detects **Grameenphone (GP)**, currency **৳**, amount **500**. |
| **BD Bangla Voice** | Switch to **বাংলা (BD)** → *"আম্মুকে ৫০০ টাকা পাঠাও"* | On-device Bangla regex extraction without internet. |
| **MY Malaysian Voice** | *"Send RM 50 to John"* (012... number) | Detects **Maxis / Hotlink**, switches currency to **RM**, amount **50**. |
| **Contact Alias** | Settings ⚙️ > Add Alias `Ammu` → link contact | Spoken *"Ammu"* dynamically resolves to chosen contact identifier. |
| **Groq AI Fallback** | *"Hey could you please top up twenty ringgit for John"* | Groq `llama-3.1-8b-instant` extracts entity & amount in <300ms. |
| **Quick Reload** | Tap **Reload** on Home screen | Repeats previous transaction in 1 tap without voice or search. |

---

## 🏗 Architecture Overview

```
VoiceTopup/
├── App/
│   └── VoiceTopupApp.swift          # App entry point
├── Views/
│   ├── HomeView.swift               # Voice capture, contact search, Quick Reload
│   ├── ConfirmView.swift            # Operator detection & amount confirmation
│   ├── ResultView.swift             # Success/failure receipt
│   └── AliasSettingsView.swift      # Persistent alias manager
├── ViewModels/
│   ├── HomeViewModel.swift          # Coordinator for voice & local/Groq parsing
│   └── ConfirmViewModel.swift       # Async transaction validation
├── Services/
│   ├── SpeechService.swift          # Live SFSpeechRecognizer + AVAudioEngine
│   ├── ContactsService.swift        # On-device Contacts framework search
│   ├── TopupParser.swift            # On-device regex engine (BD & MY)
│   ├── GroqService.swift            # Fallback LLM client (llama-3.1-8b-instant)
│   ├── DummyTopupService.swift      # Simulated 1-2s top-up backend
│   └── AliasStore.swift             # UserDefaults alias persistence
└── Utilities/
    ├── PhoneNormalizer.swift        # BD (+880) & MY (+60) number normalizer
    ├── OperatorDetector.swift       # Static carrier prefix table
    ├── Color+Theme.swift            # Cross-platform theme styling
    └── Secrets.swift                # Gitignored API credentials
```
