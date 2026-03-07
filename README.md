# 🎙️ SolarSpeech: Voice AI Solar Dashboard

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Material Design 3](https://img.shields.io/badge/Material_Design_3-757575?style=for-the-badge&logo=material-design&logoColor=white)
![Generative AI](https://img.shields.io/badge/GenAI_%2F_LLMs-FF6F00?style=for-the-badge&logo=openai&logoColor=white)

**Intelligent Navigation for IoT Monitoring Platforms**
*Hackathon Proposal 2026 - Powered by AI/LLM Speech Recognition*

SolarSpeech is a next-generation voice-controlled dashboard designed for field technicians and system operators. It simplifies navigating complex, multi-layered solar monitoring data through an intuitive conversational AI and multi-modal feedback interface.

---

## 🛑 The Challenge

Solar monitoring dashboards contain complex, multi-layered information across numerous screens, making navigation cumbersome:
- ⏳ **Wasted Time**: Users spend too much time navigating through multiple menus to find specific data.
- 🚨 **Missed Alerts**: Critical alerts may be missed during urgent situations due to information overload.
- 🧤 **Hands-Free Necessity**: Field technicians often wear gloves or carry equipment, making touch screens impractical during inspections.
- ♿ **Accessibility Barriers**: Traditional UI creates friction for users with limited mobility or visual impairments.

---

## 💡 Our Solution

SolarSpeech transforms the solar monitoring experience using a context-aware AI ecosystem that translates human speech into actionable deep-linked dashboard transitions.

1. **"Quick Help" & Text/Voice Input**: A universal button activates the voice assistant, supported by a rich text-chatbot alternative.
2. **Context-Aware AI & LLMs**: We utilize advanced LLMs to parse natural language, mapping speech to specific dashboard states and routing.
3. **Instant Navigation**: Say *"Show me inverter 3 performance"* and the app instantly opens the relevant live data screen.
4. **Multimodal Interaction & Predictive Suggestions**: The app doesn't just listen; it anticipates. While viewing "Inverter 3," the LLM suggests contextually relevant follow-ups (e.g., *"Would you like to see the last week's alerts for low output?"*).

### 🌟 Key Innovations
- **Context-Aware Routing Model**: Unifies the Speech-to-Text pipeline with a deep understanding of the app's current navigational state.
- **Self-Training Suggestion Engine**: Learns from user navigational patterns to auto-suggest the most critical next-views to prevent equipment downtime.

---

## 🏆 Why SolarSpeech is Better

We don't just solve the problem; we elevate the operational standards of solar plants.

| Feature / Aspect | Traditional Dashboards ❌ | SolarSpeech ✅ |
| :--- | :--- | :--- |
| **Navigation Speed** | 5-7 clicks to reach deep device data (inverters, sensors). | **Instant**. Voice-command directly routes to the exact view. |
| **Field Operation** | Requires active hands, making physical inspections tough. | **Hands-Free**. Voice-first design allows multi-tasking on-site. |
| **Alert Management** | Manual digging through logs and notification menus. | **Proactive**. LLM anticipates and suggests relevant alerts. |
| **Accessibility** | Heavily reliant on visual scanning and precise touch. | **Inclusive**. Voice and chatbot options cater to all needs. |
| **Learning Curve** | High. Operators must learn complex dashboard tree structures. | **Zero**. Just ask what you want to see standard natural language. |

---

## 📸 Application Highlights & UI

*(Replace the placeholders below with actual screenshots prior to submission)*

### 1. Unified Dashboard
> *Where cumulative information of the entire plant is visible.*
<p align="center">
  <img src="https://via.placeholder.com/800x400.png?text=Dashboard+Overview" alt="Solar Dashboard" width="70%"/>
</p>

### 2. Voice Assistant & Intelligent Chatbot
> *Say "Show me the alerts" or type in your queries. Multimodal support.*
<p align="center">
  <img src="https://via.placeholder.com/350x650.png?text=Voice+Assistant+UI" alt="Voice UI" width="30%"/>
  <img src="https://via.placeholder.com/350x650.png?text=Chatbot+Interface" alt="Chatbot UI" width="30%"/>
</p>

### 3. Contextual Suggestions Action
> *When visualizing inverter performance, the app suggests historical alert views.*
<p align="center">
  <img src="https://via.placeholder.com/800x400.png?text=Contextual+Suggestions" alt="Next View Suggestions" width="70%"/>
</p>

---

## 🏗️ Technology Stack

- **Frontend**: Flutter 3.x
- **UI/UX**: Material Design 3
- **Voice Capabilities**: Native Speech-to-Text Plugins (`speech_to_text`)
- **AI / LLM Engine**: OpenAI / Gemini (LangChain integration for prompt context)
- **State Management & Routing**: Provider / Riverpod / GoRouter

---

## ⚙️ Core Architecture & Methodologies

1. **Solar Plant Domain Modeling**: We model the plant hierarchy exactly as it functions:
   `PV Panels ➔ Strings ➔ Monitoring Sensors (Temp/Irradiation) ➔ Inverters ➔ Transformer ➔ Grid`
2. **LLM Command Intention Parsing**:
   - The user speaks -> `speech_to_text` captures the string.
   - The string and current app state are passed to the LLM.
   - LLM returns a structured JSON containing the `targetRoute`, `parameters` (e.g., `inverterId: 3`), and `suggestedFollowUps`.
3. **Dynamic Deep Linking**: Flutter dynamically navigates to the nested component without traversing intermediate screens.

---

## 🚀 Installation & Setup Instructions

Follow these steps to build and run the application on your local machine or a physical device.

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.x or higher)
- Android Studio / Xcode (for emulators or device deployment)
- An active IDE (VS Code, IntelliJ)

### 1. Clone & Install Dependencies
Open your terminal and run the following commands:
```bash
# Clone the repository (if applicable)
git clone https://github.com/shrey416/SolarSpeech.git
cd SolarSpeech

# Install all required Flutter packages
flutter pub get
```

### 2. Run the Application
Ensure you have a device connected (or an emulator running). You can check your connected devices with:
```bash
flutter devices
```
If you are deploying to a new physical Android or iOS device:
```bash
# Run the app
flutter run
```

*Note: For Speech-to-Text functionalities, testing on a physical device is highly recommended over an emulator to ensure microphone hardware access.*

---
*Built by Team Neural Ninjas 🐱‍👤*
