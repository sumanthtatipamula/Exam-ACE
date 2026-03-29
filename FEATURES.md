# Exam Ace - Features Documentation

Complete guide to all features and functionality in Exam Ace, the exam preparation tracker for competitive exams.

---

## Table of Contents

1. [Home Dashboard](#home-dashboard)
2. [Syllabus Management](#syllabus-management)
3. [Mock Tests](#mock-tests)
4. [Exam Tracking](#exam-tracking)
5. [Calendar View](#calendar-view)
6. [Profile & Settings](#profile--settings)
7. [Week Completion Metrics](#week-completion-metrics)
8. [Visual Features](#visual-features)

---

## Home Dashboard

The Home screen is your command center for daily exam preparation tracking.

### Weekly Tracker (Surf Chart)

An innovative visual representation of your weekly progress:

- **Building Visualization**: Each day of the week is represented as a building
  - Building height corresponds to task completion percentage
  - Taller buildings = more tasks completed
  - Color-coded: Selected day, today, and regular days have distinct colors

- **Dynamic States**:
  - **No Tasks**: Small dot indicator
  - **In Progress**: Building under construction with workers on the roof
  - **Completed**: Full building with patrol sentinels on the rooftop
  - **Devastated**: Collapsed building (when incomplete tasks > completed tasks on past days)
  - **Cracked**: Structural damage (when some tasks incomplete on past days)

- **Surveillance Drones**: 
  - Appear above completed days
  - Patrol horizontally across their column
  - Vertical bobbing motion for realistic flight
  - Never overlap with buildings (35px minimum clearance)
  - Searchlight beam that scans the ground

### Week Summary Ribbon

- **Week Completion %**: Headline metric showing overall weekly progress
- **Week-over-Week Comparison**: 
  - Shows percentage change vs. previous week
  - Trending indicators (up/down arrows)
  - Color-coded: green for improvement, red for decline

- **Progress Counter**: `completed/total` tasks for the week
- **Streak Badge**: 
  - Fire icon with consecutive days count
  - Pops animation when streak increases
  - Shake + flash animation when streak breaks

### Daily Task Board

- **Add Tasks**: Floating action button to create new tasks
- **Task Progress**: Slider (0-100%) for each task
- **Task Completion**: Visual checkmark when reaching 100%
- **Date Selection**: Tap any day in the week to view/edit tasks for that date

---

## Syllabus Management

Organize your study material in a hierarchical structure.

### Subject Level

- **Create Subjects**: 
  - Name your subject (e.g., "Mathematics", "General Knowledge")
  - Optional image upload from gallery
  - Optional exam date
  - Automatic creation timestamp

- **Subject Cards**:
  - Display subject name and image
  - Show exam date if set
  - Tap to view chapters

### Chapter Level

- **Add Chapters**: Organize topics within each subject
- **Chapter Progress**: Visual indicator of completion
- **Notes Support**: Add detailed notes for each chapter
- **Topic Management**: Create and track individual topics

### Topic Level

- **Topic Creation**: Break down chapters into specific topics
- **Markdown Notes**: 
  - Rich text formatting support
  - Preview mode for reading
  - Edit mode for writing
  - Syntax highlighting

- **Progress Tracking**: Mark topics as complete/incomplete

### Sorting Options

Customize how your syllabus is displayed:
- **Date (Newest First)**: Most recently added items first
- **Date (Oldest First)**: Oldest items first
- **Alphabetical (A-Z)**: Sort by name ascending
- **Alphabetical (Z-A)**: Sort by name descending

---

## Mock Tests

Track practice test performance and link to syllabus topics.

### Test Entry

- **Test Details**:
  - Test title/name
  - Marks obtained
  - Total marks
  - Test date
  - Automatic percentage calculation

### Syllabus Linking

Link mock tests to specific syllabus areas:
- **None**: Standalone test
- **Subject**: Link to entire subject
- **Chapter**: Link to specific chapter
- **Topic**: Link to individual topic

### Performance Tracking

- **Score Display**: Shows marks and percentage
- **Trend Analysis**: View performance over time
- **Linked Content**: Quick access to related syllabus material

---

## Exam Tracking

Manage real competitive exam attempts and schedules.

### Exam Status

Two types of exam entries:
- **Taken**: Completed exams with scores
- **Yet to Take**: Upcoming scheduled exams

### Exam Details

- **Exam Name**: Official exam title (e.g., "SSC CGL 2026")
- **Exam Date**: When the exam is/was held
- **Scores** (for taken exams):
  - Marks obtained
  - Total marks
  - Percentage calculation

### Exam Management

- **Add Exam**: Create new exam entry
- **Edit Exam**: Update details or scores
- **Delete Exam**: Remove exam records
- **Status Toggle**: Change between "Taken" and "Yet to Take"

---

## Calendar View

Historical view of your preparation journey.

### Features

- **Monthly Calendar**: Navigate through months
- **Task Indicators**: Visual markers on dates with tasks
- **Completion Status**: Color-coded by completion level
- **Quick Navigation**: Jump to specific dates
- **History Review**: See what you accomplished on any past date

---

## Profile & Settings

Customize your experience and manage preferences.

### Theme Settings

- **Theme Mode**:
  - Light mode
  - Dark mode
  - System default (follows device settings)

- **Color Presets**: Multiple accent color options
  - Blue (default)
  - Purple
  - Green
  - Orange
  - Red
  - Teal
  - Pink

### Week Completion Formula

Choose how your weekly percentage is calculated:

#### Balanced Mode
- **Formula**: Harmonic mean of task progress
- **Best For**: Encouraging even distribution of effort
- **How It Works**: Penalizes extremes - having one task at 10% and another at 90% scores lower than both at 50%
- **Example**: Tasks at [20%, 80%] = 32% vs [50%, 50%] = 50%
- **Effect**: Rewards working evenly across all tasks

#### Momentum Mode
- **Formula**: Exponential weighted average (recent days count more)
- **Best For**: Building consistent study habits and finishing strong
- **How It Works**: Monday gets 1.0x weight, Sunday gets 2.7x weight (e^1)
- **Example**: Improving week [50%, 60%, 70%, 80%, 90%, 95%, 100%] = 84.2%
- **Effect**: Rewards upward trends and strong finishes

#### Consistent Mode
- **Formula**: Average with consistency bonus
- **Best For**: Maintaining steady daily performance
- **How It Works**: Base average + bonus for low variance (up to 15% boost)
- **Example**: Steady [70%, 72%, 71%, 70%, 73%] gets bonus vs [50%, 90%, 50%, 90%, 50%]
- **Effect**: Rewards regular, predictable progress

### Notifications

- **Daily Reminders**: Set time for daily task notifications
- **Exam Alerts**: Reminders for upcoming exams
- **Streak Notifications**: Alerts when streak is at risk

### Account Management

- **Profile Information**: Display name and email
- **Sign Out**: Log out of your account
- **Data Sync**: Automatic cloud backup via Firebase

### Legal & Info

- **About**: App version and information
- **Privacy Policy**: Link to privacy documentation
- **Week Score Explanation**: Detailed formula breakdowns

---

## Week Completion Metrics

Understanding how your weekly percentage is calculated.

### Metric Components

1. **Daily Task Completion**: Each task has 0-100% progress
2. **Daily Average**: Average of all tasks for that day
3. **Weekly Calculation**: Depends on selected formula mode

### Formula Comparison

Example week with improving performance:
- Mon 50%, Tue 60%, Wed 70%, Thu 80%, Fri 90%, Sat 95%, Sun 100%

**Results:**
- **Balanced**: 72.4% (harmonic mean penalizes the low start)
- **Momentum**: 84.2% (rewards the upward trend)
- **Consistent**: 78.9% (average with small bonus for improving pattern)

Example week with inconsistent performance:
- Mon 90%, Tue 50%, Wed 90%, Thu 50%, Fri 90%, Sat 50%, Sun 90%

**Results:**
- **Balanced**: 64.3% (heavily penalizes the extremes)
- **Momentum**: 70.0% (recent 90% helps)
- **Consistent**: 70.0% (no bonus due to high variance)

See the **About** section in the app for:
- Mathematical formulas
- Example calculations
- Visual comparisons
- When to use each mode

---

## Visual Features

### Animations

- **Entrance Animations**: Smooth chart appearance
- **Streak Celebrations**: Pop effect on streak increase
- **Streak Break**: Shake + flash on streak loss
- **Building Construction**: Animated workers on today's building
- **Patrol Sentinels**: Walking guards on completed buildings
- **Surveillance Drones**: Flying drones with searchlight beams

### Building States

1. **Empty Day**: Small dot indicator
2. **In Progress**: 
   - Building under construction
   - Hammer-wielding workers
   - Construction phase animation

3. **Completed**:
   - Full building with windows
   - Rooftop patrol sentinels
   - Surveillance drones overhead

4. **Devastated** (past days with poor performance):
   - Collapsed structure
   - Rubble pile
   - Dust and shadow effects
   - Broken windows
   - Structural fractures

5. **Cracked** (past days with some incomplete tasks):
   - Visible stress cracks
   - Facade damage
   - Warning indicators

### Color Coding

- **Primary Color**: Your selected accent color
- **Today**: Highlighted with distinct color
- **Selected Day**: Emphasized selection color
- **Past Days**: Standard fill color
- **Devastated**: Grayscale with damage effects

---

## Data Management

### Cloud Sync

- **Firebase Integration**: All data synced to cloud
- **Real-time Updates**: Changes sync across devices
- **Offline Support**: Local caching with SharedPreferences

### Data Structure

```
users/{userId}/
  ├── tasks/
  │   └── {taskId}: { title, progress, date }
  ├── subjects/
  │   └── {subjectId}: { name, imageUrl, date, createdAt }
  ├── chapters/
  │   └── {chapterId}: { subjectId, name, notes }
  ├── topics/
  │   └── {topicId}: { chapterId, name, notes, completed }
  ├── mockTests/
  │   └── {testId}: { title, marks, total, date, linkType, linkedIds }
  └── exams/
      └── {examId}: { examName, date, status, marks, total }
```

### Security

- **User-scoped Data**: Each user can only access their own data
- **Firestore Rules**: Server-side security enforcement
- **Document Size Limit**: 1 MiB per document
- **Authentication Required**: All operations require sign-in

---

## Tips & Best Practices

### Maximize Your Streak

1. Set daily reminders in Profile → Notifications
2. Complete at least one task every day
3. Use the "Simple" formula for easier streak maintenance

### Effective Syllabus Organization

1. Create subjects first (one per exam section)
2. Break subjects into chapters (logical groupings)
3. Add topics for granular tracking
4. Use notes to capture key points

### Mock Test Strategy

1. Link tests to specific topics you're practicing
2. Review linked syllabus after poor performance
3. Track improvement trends over time

### Week Planning

1. Add tasks at the start of each week
2. Distribute workload evenly across days
3. Use "Strict" mode to ensure balanced effort
4. Review calendar weekly to identify patterns

---

## Keyboard Shortcuts & Gestures

### Navigation

- **Tap Day**: Select day in weekly tracker
- **Swipe**: Navigate between weeks (if implemented)
- **Pull to Refresh**: Reload data

### Task Management

- **Tap Task**: Edit task details
- **Slide Progress**: Adjust completion percentage
- **Long Press**: Delete task (if implemented)

---

## Troubleshooting

### Common Issues

**Drones not moving?**
- Fixed in latest version - drones now patrol horizontally

**Drones overlapping buildings?**
- Fixed in latest version - 35px minimum clearance enforced

**Data not syncing?**
- Check internet connection
- Verify you're signed in
- Check Firebase configuration

**Theme not changing?**
- Restart the app
- Check system theme settings (if using "System" mode)

---

## Future Enhancements

Potential features under consideration:
- Export data to PDF/CSV
- Study time tracking
- Pomodoro timer integration
- Collaborative study groups
- AI-powered study recommendations
- Spaced repetition reminders
- Performance analytics dashboard

---

## Support & Feedback

For issues, feature requests, or feedback:
- Check [SECURITY.md](SECURITY.md) for security concerns
- Review [PRIVACY.md](PRIVACY.md) for privacy information
- See [README.md](README.md) for setup and development info

---

**Version**: 1.0.2+3  
**Last Updated**: March 2026  
**License**: MIT
