# 📱 Feature Catalog

Everything App includes **200+ features** organized into 10 categories. Each feature has a dedicated screen, service, and local persistence — **204 services, 201 screens, 81 data models, 4,000+ tests**.

> **For developers:** Features are registered in [`lib/core/utils/feature_registry.dart`](lib/core/utils/feature_registry.dart). Adding a new feature requires only a single `FeatureEntry` — the navigation drawer picks it up automatically.

---

## 📅 Planning & Views (12 features)

| Feature | Description |
|---------|-------------|
| **Daily Agenda** | Timeline view of today's events with priority indicators |
| **Daily Timeline** | Hour-by-hour visual timeline of scheduled activities |
| **Calendar** | Monthly/weekly calendar with Microsoft Graph sync support |
| **Weekly Planner** | Plan your week with drag-and-drop time blocks |
| **Weekly Report** | Auto-generated summary of weekly productivity and accomplishments |
| **Weekly Reflection** | Guided end-of-week review with goal tracking and lessons learned |
| **Countdowns** | Track days remaining until important events |
| **Daily Review** | End-of-day reflection prompts with scoring |
| **Morning Briefing** | Auto-generated daily briefing combining calendar, weather, and priorities |
| **Free Slot Finder** | Automatically detect open time slots in your schedule |
| **Life Dashboard** | At-a-glance view combining key metrics across all trackers |
| **Agenda Digest** | Smart digest of upcoming events and deadlines |

## ⚡ Productivity (28 features)

| Feature | Description |
|---------|-------------|
| **Pomodoro Timer** | Focus sessions with configurable work/break intervals |
| **Focus Time** | Distraction-free deep work timer with session logging |
| **Interval Timer** | Custom interval training timer with configurable rounds |
| **Habit Tracker** | Build and maintain daily habits with streak tracking |
| **Habit Insights** | Analytics and pattern detection across habit data |
| **Goals** | Set, track, and measure progress on personal goals |
| **Goal Autopilot** | Autonomous goal monitoring with adaptive milestone suggestions |
| **Routine Builder** | Design morning/evening routines with step-by-step guides |
| **Eisenhower Matrix** | Prioritize tasks by urgency and importance (4-quadrant view) |
| **Decision Matrix** | Weighted criteria evaluation for complex decisions |
| **Kanban Board** | Visual task management with customizable columns |
| **Project Planner** | Multi-phase project planning with dependency tracking |
| **Time Tracker** | Log time spent on projects and activities |
| **Time Budget** | Allocate and monitor time across categories |
| **Time Audit** | Analyze where your time actually goes vs. intentions |
| **Stopwatch** | Precision stopwatch with lap tracking |
| **Chess Clock** | Two-player chess clock with multiple time control modes |
| **Skill Tracker** | Track skill development with practice hours and milestones |
| **Learning Tracker** | Manage courses, tutorials, and learning resources |
| **Flash Cards** | Spaced-repetition flash cards for memorization |
| **GPA Calculator** | Calculate GPA from course grades and credit hours |
| **Grade Calculator** | Weighted grade calculation for courses and assignments |
| **Productivity Score** | Daily productivity rating with trend analysis |
| **Activity Heatmap** | GitHub-style heatmap of daily activity |
| **Daily Challenge** | Auto-generated daily productivity challenges |
| **Daily Standup** | Structured standup notes (yesterday/today/blockers) |
| **Speed Reader** | Speed reading trainer with adjustable WPM |
| **Typing Speed** | Typing speed test with WPM and accuracy tracking |

## ❤️ Health & Wellness (27 features)

| Feature | Description |
|---------|-------------|
| **Mood Journal** | Track daily moods with notes and pattern detection |
| **Sleep Tracker** | Log sleep duration and quality with trend graphs |
| **Sleep Calculator** | Optimal bedtime/wake-up calculator based on sleep cycles |
| **Symptom Tracker** | Record health symptoms with severity and triggers |
| **Allergy Tracker** | Log allergic reactions with allergens, severity, symptoms & treatment |
| **Meditation** | Guided and timed meditation sessions with history |
| **Water Tracker** | Daily water intake tracking with reminders |
| **Caffeine Tracker** | Monitor caffeine consumption and timing |
| **Fasting Tracker** | Intermittent fasting timer with fasting window tracking |
| **Workout Tracker** | Log exercises, sets, reps, and workout routines |
| **Meal Tracker** | Track meals and nutritional intake |
| **Energy Tracker** | Monitor energy levels throughout the day |
| **Medication Tracker** | Medication schedules with dosage and refill tracking |
| **Screen Time** | Track and limit device screen time |
| **Eye Break** | Timed reminders for the 20-20-20 rule to reduce eye strain |
| **Gratitude Journal** | Daily gratitude entries to build positive habits |
| **Dream Journal** | Record and analyze dream patterns |
| **BMI Calculator** | Body Mass Index calculator with health ranges |
| **Body Measurements** | Track body measurements over time |
| **Weight Tracker** | Daily weight logging with trend graphs and goal tracking |
| **Blood Pressure** | Log and chart blood pressure readings |
| **Blood Sugar** | Monitor blood glucose levels with trend analysis |
| **SpO2 Tracker** | Blood oxygen saturation logging and trend monitoring |
| **Breathing Exercise** | Guided breathing patterns (box breathing, 4-7-8, etc.) |
| **Pace Calculator** | Running/walking pace and distance calculator |
| **Digital Detox** | Structured screen-free periods with tracking |
| **Sobriety Counter** | Track sobriety milestones and streaks |

## 💰 Finance (19 features)

| Feature | Description |
|---------|-------------|
| **Expense Tracker** | Categorize and track daily expenses |
| **Expense Forecast** | AI-powered expense prediction based on spending patterns |
| **Budget Planner** | Set monthly budgets by category with overspend alerts |
| **Savings Goals** | Visual progress toward savings targets |
| **Debt Payoff** | Debt reduction planner with snowball/avalanche strategies |
| **Net Worth** | Track assets and liabilities over time |
| **Subscriptions** | Monitor recurring subscriptions and total monthly cost |
| **Bill Reminders** | Track upcoming bills with due date notifications |
| **Loyalty Cards** | Store loyalty program cards and points |
| **Coupon Tracker** | Save and track coupon codes with expiration dates |
| **Tip Calculator** | Calculate tips and split bills |
| **Loan Calculator** | Amortization schedules for loans and mortgages |
| **Mortgage Calculator** | Detailed mortgage payment and amortization calculator |
| **Compound Interest** | Visualize compound interest growth over time |
| **Expense Splitter** | Split group expenses fairly among participants |
| **Currency Converter** | Real-time currency conversion |
| **Invoice Generator** | Create and manage professional invoices |
| **Tax Calculator** | Income tax estimation with bracket breakdown |
| **Salary Calculator** | Salary breakdown (hourly/weekly/monthly/annual conversions) |

## 🎨 Lifestyle (27 features)

| Feature | Description |
|---------|-------------|
| **Travel Log** | Document trips with locations, photos, and memories |
| **Travel Time Estimator** | Estimate travel duration between locations |
| **Commute Tracker** | Track daily commute times and routes |
| **Parking Spot** | Save your parking location for easy retrieval |
| **Contacts** | Personal CRM — track interactions with important contacts |
| **Pet Care** | Vet visits, feeding schedules, and pet health records |
| **Plant Care** | Watering schedules and plant health tracking |
| **Recipe Book** | Save and organize favorite recipes |
| **Pantry Tracker** | Track pantry inventory with expiration dates |
| **Quote Collection** | Curate inspirational quotes with tags |
| **Affirmations** | Daily positive affirmation prompts and custom collections |
| **Music Practice** | Log practice sessions for instruments |
| **Metronome** | Adjustable-tempo metronome for music practice |
| **Morse Code** | Morse code translator and practice tool |
| **Vocabulary Builder** | Learn new words with definitions and usage examples |
| **Decision Journal** | Record decisions and review outcomes over time |
| **Daily Journal** | Free-form daily journaling with search |
| **Reading List** | Track books to read, currently reading, and completed |
| **Library Book** | Track borrowed library books with due dates |
| **Movie Tracker** | Log movies watched with ratings and reviews |
| **Time Capsules** | Write messages to your future self |
| **Random Decision Maker** | Spin the wheel or flip options for decisions |
| **World Clock** | Track time across multiple time zones |
| **Sun & Moon** | Sunrise, sunset, and moon phase information |
| **Score Keeper** | Track scores for games and competitions |
| **Age Calculator** | Calculate exact age with days, months, and years |
| **Date Calculator** | Calculate days between dates, add/subtract durations |

## 📁 Organization (13 features)

| Feature | Description |
|---------|-------------|
| **Quick Capture** | Rapid inbox for capturing thoughts and ideas |
| **Bucket List** | Life goals and experiences you want to achieve |
| **Wishlist** | Items you want to buy or receive |
| **Watchlist** | Movies, shows, and media to watch |
| **Grocery Lists** | Shopping lists with categories and check-off |
| **Packing Lists** | Travel packing lists with templates |
| **Gift Tracker** | Track gift ideas and budgets for people |
| **Birthdays & Anniversaries** | Never forget important dates |
| **Bookmarks** | Save and organize web links and resources |
| **Password Generator** | Generate secure passwords with customizable rules |
| **Password Strength** | Analyze password strength with entropy scoring |
| **Data Backup** | Export and import all app data |
| **ICS Export** | Export events to standard ICS calendar format |

## 📊 Tracking (10 features)

| Feature | Description |
|---------|-------------|
| **Home Inventory** | Catalog household items with values for insurance |
| **Home Maintenance** | Schedule and track home repair and maintenance tasks |
| **Warranty Tracker** | Track warranty expiration dates and coverage |
| **Document Expiry** | Passport, license, and document expiration alerts |
| **Emergency Card** | Store emergency contacts and medical info |
| **Vehicle Maintenance** | Service schedules and maintenance history |
| **Fuel Log** | Track fuel purchases, mileage, and efficiency |
| **Fuel Gauge** | Visual fuel level indicator with range estimation |
| **Meeting Cost** | Calculate real-time cost of meetings based on attendees |
| **Streak Tracker** | Track and visualize streaks across all app features |

## 🎮 Games & Puzzles (12 features)

| Feature | Description |
|---------|-------------|
| **2048** | Classic sliding-tile number puzzle |
| **Snake** | Classic snake game with score tracking |
| **Minesweeper** | Classic minesweeper with multiple grid sizes |
| **Sudoku** | Sudoku puzzles with hint system |
| **Tetris** | Classic block-stacking game |
| **Tic-Tac-Toe** | Two-player tic-tac-toe with AI opponent |
| **Hangman** | Word guessing game with themed categories |
| **Memory Game** | Card-matching memory game with difficulty levels |
| **Simon Says** | Pattern memory game with increasing difficulty |
| **Game of Life** | Conway's Game of Life cellular automaton simulator |
| **Rock Paper Scissors** | RPS with statistics and streak tracking |
| **Reaction Time** | Reaction speed test with history and percentile ranking |

## 🛠️ Developer & Utility Tools (22 features)

| Feature | Description |
|---------|-------------|
| **Unit Converter** | Convert between units (length, weight, temperature, etc.) |
| **Unit Price** | Compare unit prices across different package sizes |
| **Base Converter** | Convert numbers between binary, octal, decimal, and hex |
| **Roman Numerals** | Convert between Roman numerals and decimal |
| **Percentage Calculator** | Percentage, increase/decrease, and ratio calculations |
| **Scientific Calculator** | Full scientific calculator with trig, log, and constants |
| **Matrix Calculator** | Matrix operations (multiply, invert, determinant, eigenvalues) |
| **Subnet Calculator** | IPv4 subnet calculator with CIDR notation |
| **Cron Expression** | Build and parse cron expressions with human-readable output |
| **JSON Formatter** | Format, validate, and minify JSON data |
| **Regex Tester** | Test regular expressions with live matching |
| **Hash Generator** | Generate MD5, SHA-1, SHA-256, and other hash digests |
| **Lorem Ipsum** | Generate placeholder text in various lengths |
| **Markdown Preview** | Live Markdown rendering and preview |
| **ASCII Art** | Text-to-ASCII art generator |
| **Cipher Tool** | Encrypt/decrypt text with Caesar, Vigenère, and other ciphers |
| **Color Palette** | Generate and save color palettes |
| **Color Mixer** | Mix colors interactively and get exact values |
| **Color Contrast** | WCAG accessibility contrast ratio checker |
| **Color Blindness** | Simulate color blindness modes for accessibility testing |
| **Gradient Generator** | Create CSS/Flutter gradient definitions visually |
| **Aspect Ratio** | Calculate and convert aspect ratios |

## 🧠 Autonomous Intelligence (16 features)

| Feature | Description |
|---------|-------------|
| **Context Switcher** | Autonomous life-context detection (work/personal/fitness/social) with proactive tool suggestions |
| **Streak Guardian** | Smart streak risk monitoring with proactive warnings and rescue strategies |
| **Experiment Engine** | Design and run self-experiments with hypothesis testing, Welch's t-test, and effect-size analysis |
| **Burnout Detector** | Multi-signal burnout risk detection with proactive wellness suggestions |
| **Energy Optimizer** | Analyze energy patterns and suggest optimal scheduling |
| **Correlation Analyzer** | Discover correlations between tracked metrics (sleep vs. mood, caffeine vs. focus, etc.) |
| **Pattern Detector** | Machine learning–style pattern detection across all tracked data |
| **Conflict Detector** | Detect scheduling conflicts and suggest resolutions |
| **Event Deduplication** | Detect and merge duplicate events across calendars |
| **Event Pattern** | Identify recurring patterns in event scheduling |
| **Life Coach** | AI-driven life coaching with personalized suggestions |
| **Life Score** | Composite life quality score across health, productivity, finance, and social dimensions |
| **Social Battery** | Track social energy levels with context-aware suggestions |
| **Accountability** | Accountability partner features with check-ins and goal tracking |
| **Achievement** | Gamified achievement system with unlockable badges across all features |
| **FIRE Calculator** | Financial Independence / Retire Early calculator with projections |

## 🔧 Infrastructure Services

These services support the app's core architecture rather than user-facing features:

| Service | Role |
|---------|------|
| **Auth** | Firebase email/password authentication |
| **Event** | Core event CRUD and coordination |
| **Event Search** | Full-text event search with filtering |
| **Event Sharing** | Share events across platforms |
| **Snooze** | Event and reminder snooze management |
| **CRUD** | Generic CRUD operations for feature data |
| **Secure Storage** | Platform keychain/keystore abstraction |
| **Encrypted Backup** | End-to-end encrypted data export |
| **Encrypted Preferences** | Encrypted SharedPreferences wrapper |
| **Storage Backend** | Pluggable storage backend abstraction |
| **Persistent State Mixin** | Mixin for automatic state persistence |
| **Screen Persistence** | Save and restore screen state across sessions |
| **Service Persistence** | Service-level state persistence |
| **Template** | Feature template for scaffolding new features |
| **Command Palette** | App-wide command palette (Ctrl+K) for quick navigation |
| **Dependency Tracker** | Track inter-feature dependencies |
| **Quick Poll** | In-app polling for feature feedback |
| **Spin Wheel** | Randomization engine for decision features |
| **Tally Counter** | Quick tap counter for anything that needs counting |
| **Text Analyzer** | Word count, readability score, and text statistics |
| **Wiki** | In-app knowledge base and documentation viewer |
| **Ambient Sounds** | Background sounds for focus and relaxation |
| **Pixel Art** | Pixel art drawing canvas |
| **Sketch Pad** | Freeform drawing and annotation tool |
| **Sort Visualizer** | Visual sorting algorithm demonstrations |
| **Dice Roller** | Configurable dice roller for tabletop games |
| **QR Code Generator** | Generate QR codes from text or URLs |
| **Coin Flip** | Virtual coin flip for quick decisions |
| **NATO Phonetic** | NATO phonetic alphabet converter |
| **Periodic Table** | Interactive periodic table of elements |

---

## Architecture Overview

```
lib/                             # 522 files · 172K+ lines
├── core/
│   ├── constants/       # App-wide constants
│   ├── data/            # Sample data generators
│   ├── services/        # 204 business-logic modules
│   └── utils/           # Feature registry, date/formatting helpers
├── data/
│   ├── local_storage.dart      # SharedPreferences wrapper
│   └── repositories/           # Data access layer
├── models/              # 81 data models
├── state/
│   ├── blocs/           # BLoC pattern for events
│   └── providers/       # ChangeNotifier providers
└── views/
    ├── home/            # 201 feature screens
    ├── login/           # Authentication screens
    └── widgets/         # Shared UI components
```

### Adding a New Feature

1. Create a service in `lib/core/services/`
2. Create a model in `lib/models/` (if needed)
3. Create a screen in `lib/views/home/`
4. Add a `FeatureEntry` to `FeatureRegistry.features` in `lib/core/utils/feature_registry.dart`

The feature automatically appears in the navigation drawer under the specified category.
