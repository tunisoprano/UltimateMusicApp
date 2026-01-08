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

### 🥁 Metronome
- 40-240 BPM range
- Multiple time signatures
- Visual beat indicator
- Tap tempo

</td>
</tr>
<tr>
<td width="50%">

### 📚 Practice Mode
- Note recognition exercises
- Progressive difficulty levels
- Track your improvement

</td>
<td width="50%">

### 🎨 Premium Design
- Custom "Cozy" warm theme
- Glassmorphism effects
- Smooth animations
- Dark mode optimized

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
│           Core Audio / FFT Processing              │
└─────────────────────────────────────────────────────┘
```

| Technology | Purpose |
|------------|---------|
| **SwiftUI** | Modern declarative UI |
| **AVFoundation** | Audio capture & playback |
| **Accelerate** | High-performance FFT |
| **StoreKit 2** | In-app purchases |
| **Google AdMob** | Monetization |

---

## 📁 Architecture

```
MusicTuner/
├── 🔊 Audio/
│   ├── AudioManager.swift       # Audio session
│   ├── PitchDetector.swift      # FFT pitch detection
│   └── MetronomeEngine.swift    # Beat generator
│
├── 🎨 Components/
│   ├── CozyTheme.swift          # Color palette
│   ├── ThemeManager.swift       # Theme state
│   ├── TunerGaugeView.swift     # Needle display
│   └── NoteDisplayView.swift    # Note indicator
│
├── 💼 Managers/
│   ├── StoreKitManager.swift    # Purchases
│   └── AdsManager.swift         # AdMob
│
├── 📦 Models/
│   ├── Note.swift               # Note model
│   ├── Instrument.swift         # Instruments
│   └── ExerciseLevel.swift      # Difficulty
│
├── 🧠 ViewModels/
│   ├── TunerViewModel.swift     # Tuner logic
│   └── ExerciseViewModel.swift  # Exercise logic
│
└── 📱 Views/
    ├── MainMenuView.swift       # Home
    ├── TunerView.swift          # Tuner UI
    ├── MetronomeView.swift      # Metronome UI
    ├── ExerciseView.swift       # Exercises
    └── SettingsView.swift       # Settings
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
