<p align="center">
  <img src="https://img.icons8.com/3d-fluency/94/guitar.png" width="100" alt="MusicTuner Logo"/>
</p>

<h1 align="center">🎸 Ultimate Music App</h1>

<p align="center">
  <strong>Your all-in-one musical companion for iOS</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17.0+-blue?style=for-the-badge&logo=apple" alt="iOS 17+"/>
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=for-the-badge&logo=swift" alt="Swift 5.9"/>
  <img src="https://img.shields.io/badge/SwiftUI-Framework-purple?style=for-the-badge&logo=swift" alt="SwiftUI"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT License"/>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/tunisoprano/UltimateMusicApp?style=social" alt="Stars"/>
  <img src="https://img.shields.io/github/forks/tunisoprano/UltimateMusicApp?style=social" alt="Forks"/>
</p>

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎵 Chromatic Tuner
- Real-time FFT pitch detection
- Ultra-smooth needle with exponential smoothing
- **Tuning Lock** - Visual, haptic & audio feedback
- Multiple instruments support

</td>
<td width="50%">

### 🎓 Chord Mastery
- **Interactive Lessons** - Tap to play, swipe to learn
- **Gamified Quizzes** - Test your knowledge
- **Level System** - Unlock progressive difficulty
- **High Quality Audio** - Realistic guitar samples

</td>
</tr>
<tr>
<td width="50%">

### 🌍 Localization
- **Multi-language Support** - English & Turkish
- **Instant Switching** - Change language inside app
- Does not depend on system language

</td>
<td width="50%">

### 🥁 Metronome & Tools
- 40-240 BPM Metronome
- **Chord Library** - Comprehensive diagram reference
- **Fretboard Trainer** - Learn notes on the neck
- Custom "Cozy" & Dark themes

</td>
</tr>
</table>

---

## 🎼 Supported Instruments

| Instrument | Tuning | Strings |
|:----------:|:------:|:-------:|
| 🎸 Guitar | E A D G B E | 6 |
| 🪕 Ukulele | G C E A | 4 |
| 🎸 Bass | E A D G | 4 |
| 🎻 Violin | G D A E | 4 |

---

## 🛠 Tech Stack

```
┌─────────────────────────────────────────────────────┐
│                    SwiftUI                          │
├─────────────────────────────────────────────────────┤
│  AVFoundation  │  Accelerate  │  StoreKit 2        │
├─────────────────────────────────────────────────────┤
│      Combine   │  Core Audio  │  Core Vibrations   │
└─────────────────────────────────────────────────────┘
```

| Technology | Purpose |
|------------|---------|
| **SwiftUI** | Modern declarative UI with glassmorphism |
| **AVFoundation** | Audio capture, playback & sampling |
| **Accelerate** | High-performance FFT for tuner |
| **StoreKit 2** | In-app purchases (Premium) |
| **Google AdMob** | Monetization strategy |

---

## 📁 Architecture

```
MusicTuner/
├── 🔊 Audio/
│   ├── ChordEngine.swift        # Sampler & Playback
│   ├── AudioEngine.swift        # Core audio logic
│   └── PitchDetector.swift      # FFT processing
│
├── 🎨 Components/
│   ├── HeroCard.swift           # Dashboard components
│   ├── ChordDiagramView.swift   # Dynamic SVG drawing
│   └── ThemeManager.swift       # Theming system
│
├── 💼 Managers/
│   ├── LanguageManager.swift    # Localization logic
│   ├── StoreKitManager.swift    # IAP handling
│   └── AdsManager.swift         # AdMob integration
│
├── 📦 Models/
│   ├── Chord.swift              # Chord definitions
│   ├── Curriculum.swift         # Learning path data
│   └── Note.swift               # Music theory models
│
├── 🧠 ViewModels/
│   ├── ChordMasteryViewModel.swift # Gamification logic
│   └── TunerViewModel.swift        # Tuner state
│
└── 📱 Views/
    ├── MainMenuView.swift       # Dashboard
    ├── ChordMastery/            # Learning module
    ├── TunerView.swift          # Tuner UI
    └── SettingsView.swift       # Preferences
```

---

## 🚀 Getting Started

### Prerequisites
- macOS 14.0+ with Xcode 15+
- iOS 17.0+ device or simulator
- Apple Developer account (for device testing)

### Installation

```bash
# Clone the repository
git clone https://github.com/tunisoprano/UltimateMusicApp.git

# Open in Xcode
cd UltimateMusicApp
open MusicTuner.xcodeproj

# Build and run (⌘ + R)
```

> ⚠️ **Note**: Microphone permission is required for tuner functionality.

---

## 🎯 Key Algorithms

### Pitch Detection
```
Audio Input → FFT → Peak Detection → Frequency → Note Mapping
                         ↓
              Exponential Smoothing → Smooth Display
```

### Tuning Lock
When pitch stays within **±5 cents** for **1.5 seconds**:
- ✅ Green visual confirmation
- 🔔 Pleasant ding sound
- 📳 Success haptic feedback

---

## 📸 Screenshots

<p align="center">
  <i>Coming soon...</i>
</p>

---

## 🗺 Roadmap

- [ ] Apple Watch companion app
- [ ] Chord detection
- [ ] Recording & playback
- [ ] Custom tuning presets
- [ ] Widget support

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

<p align="center">
  <strong>Tunahan Sarı</strong><br>
  <a href="https://github.com/tunisoprano">@tunisoprano</a>
</p>

---

<p align="center">
  Made with ❤️ and 🎵 in Turkey
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square" alt="PRs Welcome"/>
</p>
