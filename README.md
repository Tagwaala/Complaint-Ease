# 📋 ComplaintEase - Smart Complaint Management System

A modern, full-featured complaint management system built with **Flutter** and **Supabase**. ComplaintEase enables organizations to efficiently manage, track, and resolve complaints with role-based access for Users, Admins, and Team Members.

---

## 📑 Table of Contents

- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Prerequisites & Required Software](#-prerequisites--required-software)
- [Installation Guide](#-installation-guide-step-by-step)
- [Supabase Database Setup](#-supabase-database-setup)
- [Project Architecture](#-project-architecture)
- [User Roles](#-user-roles)
- [Screenshots](#-screenshots)
- [Troubleshooting](#-troubleshooting)

---

## ✨ Features

| Feature | Description |
|---|---|
| 🔐 **Authentication** | Email-based signup, login, password reset via Supabase Auth |
| 📝 **Complaint Filing** | Users can file complaints with category, title, description & image upload |
| 📊 **Admin Dashboard** | Analytics charts, complaint management, user management |
| 👥 **Team Dashboard** | Team members can view & manage assigned department complaints |
| 💬 **Real-time Chat** | Comment/discussion system on each complaint with live updates |
| 🔔 **Notifications** | In-app notifications for status updates and new complaints |
| ⭐ **Feedback & Rating** | Users can rate resolved complaints (1-5 stars) with reviews |
| 📂 **Category Management** | Admins can add/remove complaint categories dynamically |
| 📈 **Reports & Analytics** | Visual charts for complaint statistics using fl_chart |
| 🏠 **Public Hero Page** | Beautiful landing page showcasing resolved complaints & stats |
| 👤 **Profile Management** | Users can update their name and department |
| 🗑️ **User Management** | Admins can promote/demote users and delete accounts |
| 🌐 **Online Presence** | See who's currently viewing a complaint in real-time |
| 🔒 **Row Level Security** | Secure data access with Supabase RLS policies |

---

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| **Flutter** (Dart) | Cross-platform mobile app framework |
| **Supabase** | Backend-as-a-Service (Auth, Database, Storage, Realtime) |
| **PostgreSQL** | Database (via Supabase) |
| **fl_chart** | Charts and analytics visualization |
| **Provider** | State management |
| **Google Fonts** | Custom typography |

---

## 📦 Prerequisites & Required Software

Before you begin, make sure you have the following software installed on your system:

### 1. Flutter SDK

| Item | Details |
|---|---|
| **Download** | [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) |
| **Minimum Version** | Flutter 3.10+ (Dart 3.0+) |
| **Tested On** | Flutter 3.41.9 / Dart 3.11.5 |

### 2. Android Studio (for Android development)

| Item | Details |
|---|---|
| **Download** | [https://developer.android.com/studio](https://developer.android.com/studio) |
| **Required Components** | Android SDK, Android SDK Command-line Tools, Android Emulator |

### 3. VS Code (Recommended Code Editor)

| Item | Details |
|---|---|
| **Download** | [https://code.visualstudio.com/](https://code.visualstudio.com/) |
| **Required Extensions** | Flutter, Dart |

### 4. Git

| Item | Details |
|---|---|
| **Download** | [https://git-scm.com/downloads](https://git-scm.com/downloads) |

### 5. Supabase Account (Free)

| Item | Details |
|---|---|
| **Sign Up** | [https://supabase.com/](https://supabase.com/) |

### 6. Chrome Browser (for Web testing, optional)

| Item | Details |
|---|---|
| **Download** | [https://www.google.com/chrome/](https://www.google.com/chrome/) |

---

## 🚀 Installation Guide (Step-by-Step)

### Step 1: Install Flutter SDK

1. Download Flutter SDK from [flutter.dev](https://docs.flutter.dev/get-started/install)
2. Extract to a suitable location (e.g., `C:\flutter`)
3. Add Flutter to your system PATH:
   - **Windows**: Add `C:\flutter\bin` to your Environment Variables → System PATH
4. Verify installation:

```bash
flutter --version
```

### Step 2: Install Android Studio

1. Download and install from [developer.android.com/studio](https://developer.android.com/studio)
2. Open Android Studio → Go to **SDK Manager**
3. Install the following:
   - Android SDK Platform (API 34 or latest)
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android Emulator
4. Accept Android licenses:

```bash
flutter doctor --android-licenses
```

### Step 3: Verify Flutter Setup

Run the following command to check if everything is configured:

```bash
flutter doctor
```

> ✅ Make sure all items show a green checkmark (✓). Fix any issues before proceeding.

### Step 4: Clone the Repository

```bash
git clone https://github.com/Tagwaala/Complaint-Ease.git
```

```bash
cd Complaint-Ease
```

### Step 5: Install Dependencies

```bash
flutter pub get
```

### Step 6: Configure Supabase Credentials

Open the file `lib/core/constants.dart` and replace the Supabase URL and Anon Key with your own (if you want to use your own Supabase project):

```dart
class AppConstants {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String appTitle = 'ComplaintEase';
}
```

> 💡 You can find these in your **Supabase Dashboard → Project Settings → API**

### Step 7: Run the App

**On Android Emulator or Physical Device:**

```bash
flutter run
```

**On Chrome (Web):**

```bash
flutter run -d chrome
```

**On Windows Desktop:**

```bash
flutter run -d windows
```

**Build APK (for Android):**

```bash
flutter build apk --release
```

---

## 🗄️ Supabase Database Setup

If you are setting up your **own Supabase project**, follow these steps:

### Step 1: Create a Supabase Project

1. Go to [supabase.com](https://supabase.com/) and sign in
2. Click **"New Project"**
3. Enter a project name and set a database password
4. Select a region closest to you
5. Click **"Create new project"** and wait for it to initialize

### Step 2: Run the SQL Setup Script

1. In your Supabase Dashboard, go to **SQL Editor**
2. Click **"New Query"**
3. Copy the entire contents of the [`supabase_setup.sql`](supabase_setup.sql) file from this repository
4. Paste it into the SQL Editor
5. Click **"Run"** to execute

> ⚠️ **Important:** Run the SQL script in order. It creates tables, enables Row Level Security (RLS), sets up triggers, and configures storage buckets.

### Step 3: Enable Realtime

1. Go to **Database → Replication** in your Supabase Dashboard
2. Enable Realtime for the following tables:
   - `comments`
   - `notifications`

### Step 4: Create Storage Bucket

The SQL script automatically creates a `complaints` storage bucket. Verify it exists:

1. Go to **Storage** in your Supabase Dashboard
2. You should see a `complaints` bucket
3. If not, create one manually with **public access enabled**

### Step 5: Get API Credentials

1. Go to **Project Settings → API**
2. Copy the **Project URL** and **anon/public key**
3. Update `lib/core/constants.dart` with these values

### Database Tables Overview

| Table | Purpose |
|---|---|
| `profiles` | User profiles (name, email, role, department) |
| `complaints` | Complaint records (title, description, status, images) |
| `categories` | Complaint categories (Electricity, IT Support, etc.) |
| `comments` | Discussion comments on complaints |
| `feedback` | User ratings & reviews for resolved complaints |
| `notifications` | In-app notification records |

---

## 📁 Project Architecture

```
lib/
├── main.dart                        # App entry point & route definitions
├── core/
│   ├── constants.dart               # Supabase URL & API keys
│   ├── theme.dart                   # App theme configuration
│   └── widgets/                     # Reusable core widgets
├── models/
│   ├── complaint.dart               # Complaint data model
│   ├── user_profile.dart            # User profile model
│   ├── category.dart                # Category model
│   ├── comment.dart                 # Comment model
│   ├── feedback.dart                # Feedback/rating model
│   └── notification.dart            # Notification model
├── modules/
│   ├── auth/
│   │   ├── splash_screen.dart       # Splash & auto-login check
│   │   ├── login_page.dart          # User login
│   │   ├── signup_page.dart         # User registration
│   │   └── forgot_password_page.dart # Password reset
│   ├── home/
│   │   ├── hero_page.dart           # Public landing page
│   │   ├── public_home_page.dart    # Public dashboard
│   │   ├── notification_list_page.dart # Notifications center
│   │   └── active_discussions_page.dart # Active chats list
│   ├── user/
│   │   ├── home_page.dart           # User dashboard
│   │   ├── create_complaint_page.dart # File new complaint
│   │   ├── complaint_history_page.dart # View past complaints
│   │   └── complaint_detail_page.dart  # Complaint details & chat
│   ├── admin/
│   │   ├── dashboard.dart           # Admin analytics dashboard
│   │   ├── admin_complaint_detail_page.dart # Admin complaint view
│   │   ├── user_list_page.dart      # Manage users & roles
│   │   ├── manage_categories_page.dart # Add/remove categories
│   │   ├── reports_page.dart        # Reports & charts
│   │   └── feedback_list_page.dart  # View all user feedback
│   ├── team/
│   │   ├── team_dashboard.dart      # Team member dashboard
│   │   └── team_complaint_detail_page.dart # Team complaint view
│   └── profile/
│       └── profile_page.dart        # User profile management
├── services/
│   └── supabase_service.dart        # All Supabase API calls
└── widgets/                         # Shared UI widgets
```

---

## 👤 User Roles

| Role | Access |
|---|---|
| **User** | File complaints, view own complaints, chat, rate resolved complaints, manage profile |
| **Admin** | Full access: manage all complaints, users, categories, view reports, analytics, and feedback |
| **Team** | View & manage complaints, update status, chat with users |

### Default Categories

- ⚡ Electricity
- 💻 IT Support
- 🧹 Cleaning
- 🔧 Plumbing
- 🔒 Security

> Admins can add or remove categories at any time from the app.

---

## 🔧 Useful Commands Reference

| Command | Description |
|---|---|
| `flutter --version` | Check Flutter version |
| `flutter doctor` | Verify development setup |
| `flutter pub get` | Install project dependencies |
| `flutter run` | Run app on connected device |
| `flutter run -d chrome` | Run app on Chrome browser |
| `flutter run -d windows` | Run app on Windows desktop |
| `flutter build apk --release` | Build release APK for Android |
| `flutter build web` | Build for web deployment |
| `flutter clean` | Clean build cache |
| `flutter pub upgrade` | Upgrade all dependencies |

---

## 🐛 Troubleshooting

### Common Issues & Solutions

**1. `flutter doctor` shows issues**
```bash
flutter doctor --android-licenses   # Accept Android licenses
```

**2. Dependencies not resolving**
```bash
flutter clean
flutter pub get
```

**3. Android build fails**
- Make sure Android SDK is installed via Android Studio
- Set `ANDROID_HOME` environment variable
- Ensure minimum SDK version is 21 in `android/app/build.gradle`

**4. Supabase connection error**
- Verify your Supabase URL and Anon Key in `lib/core/constants.dart`
- Check your internet connection
- Make sure your Supabase project is active (not paused)

**5. Image upload not working**
- Verify the `complaints` storage bucket exists in Supabase
- Make sure storage policies are set (run the SQL script)

---

## 📄 License

This project is developed as a **Final Year Project (FYP)**.

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

**Made with ❤️ using Flutter & Supabase**
