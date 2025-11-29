# ReadRight

## Overview

ReadRight allows students to record themselves reading target words, receive automated pronunciation feedback, and view their progress.  
Teachers can assign custom word lists, review results, and optionally access student recordings.

---

## Features

### Student
- Practice reading from word lists (sight words, phonics, minimal pairs)
- Record speech and receive pronunciation scores
- Visual feedback and encouragement
- Track progress with scores, averages, and streaks

### Teacher
- Create or upload custom word lists (CSV)
- View student performance and top struggled words
- Export class progress as CSV
- Optional access to short retained recordings (privacy-controlled)

---

## Project Structure

```
lib/
│
├── data/
│   ├── models/                         # Core data models
│   │   ├── assessment_result.dart
│   │   ├── attempt.dart
│   │   └── word.dart
│   │
│   └── providers/                      # State & backend providers
│       ├── mock_provider.dart
│       ├── provider_interface.dart
│       ├── studentDashboardProvider.dart
│       ├── supabase_provider.dart
│       ├── teacherProvider.dart
│       └── word_provider.dart
│
├── screen/
│   ├── teacher/                        # Teacher-facing screens
│   │   ├── teacherDashboard.dart
│   │   ├── teacherSettings.dart
│   │   ├── teacherStudents.dart
│   │   ├── teacherStudentView.dart
│   │   ├── teacherWordListDetailsPage.dart
│   │   └── teacherWordLists.dart
│   │
│   ├── feedback.dart                   # Feedback after practice
│   ├── login.dart                      # Authentication
│   └── practice.dart                   # Recording/assessment flow
│
├── services/                           # Core business logic
│   ├── databaseHelper.dart
│   ├── offline_queue_service.dart
│   └── sync_service.dart
│
├── widgets/                            # Shared reusable widgets
│   ├── student_base_scaffold.dart
│   ├── student_navbar.dart
│   ├── sync_dialog.dart
│   ├── sync_status_banner.dart
│   ├── teacher_base_scaffold.dart
│   └── teacher_navbar.dart
│
└── main.dart                           # App entry point
```

Other folders:
- **assets/** — Static files (e.g., CSVs, images, etc.)
- **test/** — Unit and widget tests

---

## Architecture

| Layer                        | Description                                                                                                                                                                                                    |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **UI / Screens**             | Flutter screens for student and teacher workflows (Practice, Feedback, Teacher Dashboard, Word List Details, Student View). Handles navigation and user interaction.                                           |
| **State / Providers**        | Custom provider classes (`studentDashboardProvider`, `teacherProvider`, `word_provider`, `supabase_provider`) manage app state, load Supabase data, hold session progress, and trigger UI updates.             |
| **Data Layer (Supabase)**    | All persistent data comes from Supabase: students, teachers, attempts, recorded audio paths, Dolch word lists, and level progression. Communication goes through `supabase_provider.dart` and helper services. |
| **Services Layer**           | `offline_queue_service.dart` stores attempts locally when offline; `sync_service.dart` flushes unsynced attempts and audio uploads; `databaseHelper.dart` handles caching and local lookups.                   |
| **Audio Layer**              | Microphone recording for each word attempt, storing temporary audio locally, then uploading to Supabase storage during sync. Used within the Practice flow.                                                    |
| **Assessment / Feedback**    | App determines correctness (match/mismatch) and generates student-facing encouragement messages and sample sentence playback.                                                                                  |
| **Dolch Progression Engine** | Tracks mastered words, remaining words, 100% completion logic, and automatic advancement through: Pre-Primer → Primer → 1st → 2nd → 3rd.                                                                       |
| **Assets Layer**             | Dolch CSV files parsed into `Word` models; used for list display, sample sentences, and practice sequencing.                                                                                                   |
| **Sync & Resilience**        | Automatic retry logic, online/offline status banners, queued attempts, and background synchronization to ensure reliability in school Wi-Fi environments.                                                      |

---

## Data Model (simplified)

```json
{
  "users": {
    "id": "uuid",
    "email": "text",
    "first_name": "text",
    "last_name": "text",
    "role": "text",
    "locale": "text",
    "current_list_int": "integer",
    "class_id": "uuid",
    "save_audio": "boolean",
    "created_at": "timestamptz"
  },

  "classes": {
    "id": "uuid",
    "name": "text",
    "grade_level": "text",
    "teacher_id": "uuid",
    "created_at": "timestamptz"
  },

  "word_lists": {
    "id": "uuid",
    "title": "text",
    "category": "text",
    "list_order": "integer",
    "created_at": "timestamptz"
  },

  "words": {
    "id": "uuid",
    "list_id": "uuid",
    "text": "text",
    "type": "text",
    "sentences": "text[]",
    "created_at": "timestamptz"
  },

  "attempts": {
    "id": "uuid",
    "user_id": "uuid",
    "word_id": "uuid",
    "word_text": "text",
    "score": "double precision",
    "feedback": "text",
    "duration": "numeric",
    "recording_url": "text",
    "timestamp": "timestamptz",
    "created_at": "timestamptz"
  },

  "mastered_words": {
    "id": "uuid",
    "user_id": "uuid",
    "word_id": "uuid",
    "mastered_at": "timestamptz",
    "last_attempt": "timestamptz",
    "highest_score": "integer",
    "attempt_count": "integer"
  }
}
```

---

## Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/WitherTigher/Capstone-Project-RW.git
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the app**
   ```bash
   flutter run
   ```
---

## Testing

- Minimum 5 unit tests and 3 widget tests required.
- Run tests:
  ```bash
  flutter test
  ```

---

## Future Enhancements

- Accessibility improvements (dark mode, haptic feedback)

---

## Credits

Developed by **Business Logic** (Max Koon, Ben Curry, Dawson Moon, Connor Cromer)
Clemson University — CPSC 4150 / 6150  
Instructor: Professor Wooster  
Semester: Fall 2025
