# VoiceTopup — Executive Summary & Testing Guide

**Target Audience:** Line Manager, Chief Technology Officer (CTO), Product Team, QA  
**Version:** 1.0 (Proof of Concept)  
**Platforms:** iOS 17.0+, iPadOS 17.0+, macOS (Apple Silicon)  
**Technology Stack:** SwiftUI, Swift Concurrency, `SFSpeechRecognizer`, `AVAudioEngine`, `Contacts` Framework, Groq Cloud API (`llama-3.1-8b-instant`)

---

## 1. Executive Summary

**VoiceTopup** is a high-performance, native iOS proof-of-concept application designed to streamline mobile recharges and airtime top-ups through intelligent voice commands and local contact search.

### Key Highlights & Cost Efficiency:
1. **On-Device First (Zero AI Cost):** Standard top-up requests (e.g., *"Send 500 to Ammu"*, *"আম্মুকে ৫০০ টাকা পাঠাও"*, *"Send RM 50 to John"*) are parsed **locally on the user's device** using instant regular expressions and number normalizers. No API calls or tokens are used for standard commands.
2. **Groq LLM Fallback (`llama-3.1-8b-instant`):** If a user provides complex, unstructured speech that cannot be parsed locally, the app executes a single, ultra-lightweight fallback request to Groq Cloud to extract `{ "name": "...", "amount": ... }` in ~300ms.
3. **Multi-Region Support (Bangladesh & Malaysia):**
   - **Bangladesh (BD):** Automatic operator detection for **Grameenphone (GP)**, **Robi**, **Banglalink**, **Teletalk**, and **Airtel** with default currency `৳` (BDT).
   - **Malaysia (MY):** Automatic operator detection for **Maxis / Hotlink**, **CelcomDigi**, **U Mobile**, **Unifi Mobile**, and **Yes 5G** with default currency `RM` (MYR).
4. **1-Tap Quick Reload:** Caches the last successful transaction for instant repetition without speech or navigation.
5. **Robust Crash Safety:** Gracefully handles permission denials (Mic, Speech, Contacts), missing contacts, invalid numbers, and network drops.

---

## 2. Core User Journey & Screens

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Home Screen                                              │
│    - Record / Mic button (Live voice transcription)        │
│    - English (en-US) / Bangla (bn-BD) locale switch        │
│    - Manual contact search via device Contacts book         │
│    - Quick Reload card (Repeats last successful top-up)     │
│    - Contact Alias management (e.g. "Ammu" -> Mom)          │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Parsed Name & Amount)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Confirm Top-up Screen                                    │
│    - Verified contact name & normalized phone number        │
│    - Auto-detected mobile operator (GP, Robi, Maxis, etc.)  │
│    - Editable amount field + quick chips (50, 100, 200, 500)│
│    - Configurable currency toggle (৳ BDT / RM MYR)          │
│    - Confirm button (Executes simulated async transaction)  │
└──────────────────────────────┬──────────────────────────────┘
                               │ (1–2s Async Execution)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Result Screen                                            │
│    - Success / Failure visual status                        │
│    - Complete transaction receipt                           │
│    - "Retry" action on failure                              │
│    - Automatic persistence for Quick Reload                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. How to Run the App on Physical iPhone (Step-by-Step)

Follow these instructions to run the application directly on your or your manager's iPhone:

### Prerequisites:
- A Mac with **Xcode 15+** or **Xcode 16+** installed.
- Lightning or USB-C cable to connect the iPhone to the Mac.
- Any Apple ID (Free personal account, no paid Apple Developer account needed).

---

### Step 1: Open the Project in Xcode
1. In Finder or Terminal, open the project:
   ```bash
   open ~/Projects/VoiceTopup/VoiceTopup.xcodeproj
   ```

### Step 2: Configure Code Signing (1-Time Setup)
1. In Xcode's left sidebar (Project Navigator), click on the top blue **VoiceTopup** icon.
2. Select the **VoiceTopup** target under *Targets*.
3. Click the **Signing & Capabilities** tab.
4. Check **Automatically manage signing**.
5. Under **Team**, select your **Personal Team** (or log in with your Apple ID via *Add Account...*).
6. Change the **Bundle Identifier** slightly if needed (e.g. `com.yourname.voicetopup`).

### Step 3: Connect iPhone & Select Run Destination
1. Connect the iPhone to the Mac using a USB cable.
2. If prompted on the iPhone, tap **Trust This Computer** and enter your device passcode.
3. At the top of the Xcode window (Scheme Destination menu), click the device selector next to `VoiceTopup` and select your connected iPhone name (e.g., *John's iPhone*).

### Step 4: Enable Developer Mode on iPhone (iOS 16+)
If you have never run a developer app on this iPhone before:
1. On your iPhone, open **Settings** > **Privacy & Security**.
2. Scroll down to the bottom and tap **Developer Mode**.
3. Toggle it **ON** and follow the prompt to restart your iPhone.

### Step 5: Build & Install
1. In Xcode, press **`Cmd + R`** (or click the **▶ Play** button).
2. Xcode will compile the app and install it onto the iPhone.

### Step 6: Trust the Developer Certificate on iPhone
When launching the app for the first time on the device:
1. On the iPhone, go to **Settings** > **General** > **VPN & Device Management**.
2. Under *Developer App*, tap your Apple ID email.
3. Tap **Trust "[Your Apple ID]"** > **Trust**.
4. Open **VoiceTopup** from the iPhone home screen!

---

## 4. End-to-End Test Matrix & Demo Scenarios

Use these test scenarios during demonstrations:

### Scenario 1: English Voice Top-up (Local Regex Parse)
1. Launch **VoiceTopup**.
2. Tap **Allow** when prompted for Microphone, Speech, and Contacts permissions.
3. Ensure you have a contact in your device Contacts app (e.g. *"Mom"* with number `01712345678`).
4. Tap the **Microphone** button.
5. Say clearly: **"Send 500 to Mom"**.
6. Tap the button again to stop recording.
7. **Expected Result:** The app immediately transitions to *Confirm Top-up* with *Mom*, phone `01712345678`, operator **Grameenphone (GP)**, currency `৳`, and amount `500`.

### Scenario 2: Malaysian Voice Top-up (MY Number & Currency)
1. Add a contact named *"John"* with phone `0123456789` or `+60123456789`.
2. Tap the **Microphone** button.
3. Say: **"Send RM 50 to John"**.
4. Tap to stop recording.
5. **Expected Result:** The app detects *John*, detects **Maxis / Hotlink**, auto-switches currency to `RM`, and pre-fills `50`.

### Scenario 3: Bangla Voice Top-up
1. On the Home screen, toggle the locale picker to **বাংলা (BD)**.
2. Tap the **Microphone** button.
3. Say: **"আম্মুকে ৫০০ টাকা পাঠাও"** (or use English *"Send 200 to Ammu"*).
4. **Expected Result:** The Bangla voice parser extracts *"আম্মু"* / *"Ammu"* and `500` without hitting any external API.

### Scenario 4: Contact Alias Management
1. On the Home screen, tap the **Gear (Settings)** icon in the top right.
2. Tap **+ (Add New Alias)**.
3. Enter Alias Name: `Ammu`.
4. Search and select your desired contact from your address book.
5. Tap **Save Alias** and then **Done**.
6. Speak *"Send 100 to Ammu"* — it will now resolve to that contact even if their address book name is different.

### Scenario 5: Groq LLM Intelligent Fallback
1. Speak a natural, conversational sentence that is not a standard template:
   - *"Hey could you top up twenty ringgit for my colleague John please"*
2. **Expected Result:** Local regex detects ambiguity and calls Groq `llama-3.1-8b-instant`. The app extracts John and 20 within 300ms and opens the Confirm screen.

### Scenario 6: Quick Reload in 1 Tap
1. Complete any successful top-up.
2. On the Result screen, tap **Done** to return to Home.
3. Notice the **Quick Reload** card displaying the last recipient, operator, and amount.
4. Tap **Reload**.
5. **Expected Result:** Re-executes the transaction in one tap, skipping speech and search entirely.

---

## 5. Security & Privacy Note

- **No Gemini Embeddings or API:** Skips external AI embedding endpoints to conserve bandwidth and protect user privacy.
- **Gitignored Secrets:** API keys are encapsulated in `Secrets.swift` and excluded from version control.
- **On-Device Contacts Processing:** Contact names and address book metadata are processed locally on the iPhone.
