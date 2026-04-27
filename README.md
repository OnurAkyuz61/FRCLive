# FRCLive

FRCLive is an iOS application built with Swift and Apple Live Activities to track FRC match countdowns using the FRC Nexus API.

## Features

- Track FRC match timing in a focused mobile experience.
- Surface countdown information through Live Activities.
- Lightweight onboarding flow for quick team setup.
- Foundation for multilingual UI support (TR/EN).

## Prerequisites

- macOS with the latest stable Xcode installed.
- iOS Simulator or a physical iPhone running a supported iOS version.
- Apple Developer account (recommended for on-device testing and signing).

## Installation

1. Clone the repository:

   ```bash
   git clone <repository-url>
   ```

2. Open the project in Xcode:

   ```bash
   open FRCLive.xcodeproj
   ```

3. Configure signing in Xcode:
   - Select the project in the navigator.
   - Open **Signing & Capabilities**.
   - Choose your team and bundle identifier setup.

4. Build and run:
   - Select an iOS Simulator or connected device.
   - Press **Run** in Xcode (`Cmd + R`).

## Project Structure

- `FRCLive/`: Main app source code and assets.
- `FRCLive/Assets.xcassets/`: Image and color assets.
- `FRCLive/OnboardingView.swift`: Entry onboarding experience.

## Credits

Developed by Onur Akyüz  
[https://onurakyuz.com](https://onurakyuz.com)
