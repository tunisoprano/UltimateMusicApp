# 🎸 MusicTuner

A beautiful and feature-rich instrument tuner app for iOS, built with SwiftUI.

## ✨ Features

### 🎵 Chromatic Tuner
- **Real-time pitch detection** with ultra-smooth needle movement
- **Exponential smoothing algorithm** for stable readings
- **Tuning Lock** feature with visual, audio (ding), and haptic feedback
- **Multiple instrument support**: Guitar, Ukulele, Bass, Violin
- **Headstock visualization** showing string positions

### 🥁 Metronome
- Adjustable BPM (40-240)
- Multiple time signatures
- Visual beat indicator
- Tap tempo support

### 📚 Practice Exercises
- Note recognition exercises
- Progressive difficulty levels
- Track your learning progress

### 🎨 Beautiful Design
- Custom "Cozy" theme with warm colors
- Dark mode optimized
- Smooth animations throughout
- Modern glassmorphism effects

## 📱 Screenshots

*Coming soon*

## 🛠 Tech Stack

- **SwiftUI** - Modern declarative UI framework
- **AVFoundation** - Audio capture and playback
- **Accelerate** - High-performance FFT for pitch detection
- **StoreKit 2** - In-app purchases for premium features
- **Google AdMob** - Monetization

## 📋 Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## 🚀 Getting Started

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/MusicTuner.git
```

2. Open `MusicTuner.xcodeproj` in Xcode

3. Build and run on your device or simulator

> **Note**: Microphone access is required for tuner functionality. The app will request permission on first launch.

## 📁 Project Structure

```
MusicTuner/
├── Audio/
│   ├── AudioManager.swift      # Audio session management
│   ├── PitchDetector.swift     # FFT-based pitch detection
│   └── MetronomeEngine.swift   # Metronome audio engine
├── Components/
│   ├── CozyTheme.swift         # Custom theme colors
│   ├── ThemeManager.swift      # Theme state management
│   ├── TunerGaugeView.swift    # Tuner needle display
│   └── NoteDisplayView.swift   # Note name display
├── Managers/
│   ├── StoreKitManager.swift   # In-app purchase handling
│   └── AdsManager.swift        # Google AdMob integration
├── Models/
│   ├── Note.swift              # Musical note model
│   ├── Instrument.swift        # Instrument definitions
│   ├── ExerciseLevel.swift     # Exercise difficulty levels
│   └── NoteFormatter.swift     # Note formatting utilities
├── ViewModels/
│   ├── TunerViewModel.swift    # Tuner business logic
│   └── ExerciseViewModel.swift # Exercise logic
└── Views/
    ├── MainMenuView.swift      # Home screen
    ├── TunerView.swift         # Main tuner interface
    ├── MetronomeView.swift     # Metronome interface
    ├── ExerciseView.swift      # Practice exercises
    ├── HeadstockView.swift     # Instrument headstock
    └── SettingsView.swift      # App settings
```

## 🎯 Key Features in Detail

### Pitch Detection
The app uses Fast Fourier Transform (FFT) via Apple's Accelerate framework to detect pitch in real-time. The detected frequency is smoothed using an exponential moving average for stable needle movement.

### Tuning Lock
When a note is held in tune (within ±5 cents) for 1.5 seconds, the app provides:
- ✅ Visual confirmation (green glow effect)
- 🔔 Audio feedback (pleasant ding sound)
- 📳 Haptic feedback (success vibration)

## 📄 License

This project is available under the MIT License. See the [LICENSE](LICENSE) file for more info.

## 👨‍💻 Author

**Tunahan Sarı**

---

<p align="center">
  Made with ❤️ and 🎵
</p>
