# **SmartCloset v1.0**

![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![Platform](https://img.shields.io/badge/Platform-iOS%2017.0%2B-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Development-yellow)

*ITEL315 – Elective iOS Development*

SmartCloset is a modern iOS app built with SwiftUI that helps users manage their wardrobe, plan outfits, and maintain a style diary. With features like virtual closet management, outfit planning, and smart image processing, SmartCloset makes wardrobe management simple and intuitive.

> **Note:** This is a **development-level project** designed for learning SwiftUI, exploring Core Data persistence, and building advanced image processing features.

## **Key Features**

- **Virtual Closet Management**
  - Add clothing items with photos
  - Categorize items by type
  - Track usage and last worn dates
  - Search and filter capabilities
  - Smart color analysis

- **Outfit Planner**
  - Calendar-based planning
  - Drag and drop interface
  - Event-based organization
  - Visual outfit preview
  - Smart outfit suggestions

- **Style Diary**
  - Document daily outfits
  - Add mood and notes
  - Track outfit history
  - Visual timeline
  - Filter by mood/occasion

- **Smart Features**
  - Background removal
  - Color analysis
  - Image enhancement
  - Automatic suggestions
  - Thumbnail generation

- **User Experience**
  - Clean, modern interface
  - Intuitive gestures
  - Smooth animations
  - Dark mode support
  - Accessibility features

## **Tech Stack**

- **Framework:** SwiftUI
- **Data Persistence:** Core Data
- **Image Processing:** Vision, CoreImage
- **Architecture Pattern:** MVVM
- **Notifications:** UserNotifications Framework
- **Design:** SF Symbols, Custom Color Palette

## **App Screenshots**

<div align="center">
  [Screenshots will be added in future updates]
</div>

## **Project Structure**

```
SmartCloset/
├── SmartCloset/
│   ├── Models/
│   │   └── Core Data Models
│   ├── ViewModels/
│   │   ├── ClosetViewModel
│   │   ├── OutfitPlannerViewModel
│   │   └── DiaryViewModel
│   ├── Views/
│   │   ├── MainTabView
│   │   ├── HomeView
│   │   ├── ClosetView
│   │   ├── OutfitPlannerView
│   │   ├── StyleDiaryView
│   │   └── SettingsView
│   ├── Utilities/
│   │   ├── ImageProcessor
│   │   └── NotificationManager
│   └── Assets.xcassets
```

## **Requirements**

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## **Installation**

1. Clone the repository:
   ```bash
   git clone https://github.com/Eissxs/SmartCloset.git
   ```

2. Open `SmartCloset.xcodeproj` in Xcode

3. Build and run the project

## **Features in Detail**

### Virtual Closet Management
- Intuitive item entry with photos
- Smart categorization system
- Usage tracking and statistics
- Advanced search and filtering
- Color-based organization

### Outfit Planning
- Interactive calendar interface
- Drag-and-drop outfit creation
- Event-based organization
- Visual outfit preview
- Smart suggestions

### Style Diary
- Daily outfit documentation
- Mood and occasion tracking
- Visual timeline
- Searchable entries
- Export capabilities

### Smart Features
- Vision-powered background removal
- Accurate color analysis
- Professional image enhancement
- Intelligent outfit suggestions
- Efficient thumbnail generation

## **Privacy Permissions**

The app requires the following permissions:
- Camera (for adding items)
- Photo Library (for importing items)
- Notifications (for reminders)

## **Contributing**

Feel free to submit issues and enhancement requests!

## **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## **Documentation**

- [**UI Flow Diagram**](docs/UI_Flow_Diagram.png)
- [**Architecture Overview**](docs/Architecture_Overview.png)
- [**Developer Setup Guide**](docs/DEV_SETUP.md)

## **Areas for Improvement**

### Architecture & Code Quality
- Implement comprehensive unit tests
- Add CI/CD pipeline
- Enhance error handling
- Implement proper dependency injection
- Add comprehensive documentation
- Optimize Core Data queries

### Image Processing
- Enhance background removal accuracy
- Optimize color analysis
- Improve image enhancement algorithms
- Add more filter options
- Implement batch processing

### Features & UX
- Add data backup/restore
- Implement cloud sync
- Add social sharing
- Enhance accessibility
- Add localization support
- Implement AI-powered suggestions
- Add wardrobe analytics

### Infrastructure
- Set up crash reporting
- Implement analytics
- Add proper versioning
- Prepare for App Store submission

## **Author**

Developed by **Eissxs**

## **Acknowledgments**

- Apple SwiftUI Framework
- Vision Framework
- Core Image Framework
- Core Data Framework

---

*"Organize, plan, and style with SmartCloset!"*

--- 
