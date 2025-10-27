# ReadRight

## Overview

ReadRight allows students to record themselves reading target words, receive automated pronunciation feedback, and view their progress.  
Teachers can assign custom word lists, review results, and optionally access student recordings.

---

## Features

### Student
- Practice reading from word lists (sight words, phonics, minimal pairs)
- Record speech and receive pronunciation scores
- Instant visual feedback and phoneme-level hints
- Track progress with scores, averages, and streaks

### Teacher
- Create or upload custom word lists (CSV)
- View student performance and top struggled words
- Export class progress as CSV
- Optional access to short retained recordings (privacy-controlled)

---

## Architecture

| Layer | Description |
|-------|--------------|
| **UI / Screens** | Flutter widgets (FeedbackPage, PracticePage, ProgressPage, WordListPage) |
| **Logic / State** | BLoC, Provider, or Riverpod for managing app state |
| **Data Layer** | Firebase or local SQLite for user data and attempts |
| **Audio Layer** | `flutter_sound` for recording and playback |
| **Assessment** | Pluggable `PronunciationAssessor` interface for scoring |
| **Export** | `csv` + `share_plus` for sharing progress data |

---

## Data Model (simplified)

```json
{
  "users": {
    "uid": "...",
    "role": "student|teacher"
  },
  "attempts": [{
    "uid": "...",
    "wordText": "ship",
    "score": 92,
    "feedback": "Great /ʃ/ sound!",
    "createdAt": "ISO8601"
  }]
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

3. **Configure environment**
    - Add your Firebase or Supabase config in `lib/config/config.dart`.
    - Ensure audio permissions are enabled for Android and iOS.

4. **Run the app**
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

- Adaptive difficulty and minimal-pair drills
- Teacher dashboard with class metrics
- Voice model exemplars (TTS)
- Accessibility improvements (dark mode, haptic feedback)
- Retention policy UI and auto-purge job

---

## Credits

Developed by **Business Logic** (Max Koon, Ben Curry, Dawson Moon, Connor Cromer)
Clemson University — CPSC 4150 / 6150  
Instructor: Professor Wooster  
Semester: Fall 2025
