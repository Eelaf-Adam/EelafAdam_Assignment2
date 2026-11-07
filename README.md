# Rapport: Campus Incident Reporting App

Rapport is a Flutter mobile app that lets ALU students report campus issues (broken facilities, water shortages, power cuts, damaged furniture, sanitation and safety concerns) and lets campus staff review those reports and update their status until they are resolved.

Built for **Mobile Application Development: Formative Assignment 2** by **Eelaf Adam**.

---

## Features

### Students
- Sign up with an `@alustudent.com` email and verify it before using the app
- Report an incident: type (with icons), description, campus location, and an optional photo taken with the camera or picked from the gallery
- "Others" option for type and location with a text box to describe it
- Receive an **Incident ID** (e.g. `INC-4F7K2A`) after submitting
- Browse their own reports, search them, and filter by status or "Today"
- Track progress on an **incident tracker timeline** (Submitted → Under Review → In Progress → Resolved) with notes from staff
- Edit or delete a report while it is still pending

### Staff
- **Report Portal** with every report on campus, searchable and filterable
- Submit status updates with an optional note that the student sees on their timeline
- Cannot create, edit or delete reports, and can only change the status

### Both roles
- Home dashboard with summary cards, search with highlighted matches, and recent reports
- Report cards show the evidence photo, status, and how long ago they were submitted
- Profile page and sign out
- Works offline: changes made without a connection are saved on the device and synced automatically

---

## Tech stack

| Area | Choice |
|---|---|
| Framework | Flutter (Dart) |
| State management | Riverpod 3 |
| Authentication | Firebase Authentication (email/password + email verification) |
| Database | Cloud Firestore (real-time streams) |
| Image storage | Cloudinary (unsigned uploads); only the image URL is stored in Firestore |
| Access control | Firestore Security Rules ([`firestore.rules`](incident_report_app/firestore.rules)) |

> **Why Cloudinary instead of Firebase Storage?** New Firebase Storage buckets require the paid Blaze plan. Using Cloudinary was approved for this assignment. Photos are uploaded with an unsigned preset, so no secret key is stored in the app.

---

## Project structure

```
incident_report_app/lib/
├── main.dart              App entry point, Firebase + ProviderScope
├── models/                AppUser, UserRole, Incident, StatusUpdate
├── services/              Firebase Auth, Firestore and Cloudinary calls
├── providers/             Riverpod providers that connect services to the UI
├── screens/               Splash, auth screens, main shell and tabs, form, details
├── widgets/               Reusable UI pieces (cards, chips, timeline, fields)
├── theme/                 Colours and app-wide theme
└── utils/                 Validators, filters, date formatting, helpers
```

Screens never call Firebase directly. They read data through **providers**, and providers use **services**. This keeps UI, state and data access separate.

---

## Firestore data model

**`users/{uid}`**
```
fullName, email, role ("student" | "staff"), createdAt
```

**`incidents/{id}`**
```
code            "INC-4F7K2A"
type            facilities | water | electricity | furniture | sanitation | safety | others
otherType       text when type is "others"
description
location        socialCommons | enterpriseCommons | learningCommons | foodCourt | leadershipCenter | others
otherLocation   text when location is "others"
photoUrl        Cloudinary URL or null
status          pending | underReview | inProgress | resolved
reporterId, reporterName, reporterEmail
createdAt, updatedAt
history         [ { status, note, byId, byName, at } ]   timeline entries
```

---

## Roles and access control

Access is enforced on the server by Firestore Security Rules, not only in the UI:

- A user can only read **their own** profile, and the role must match the email domain at sign-up (`@alustudent.com` → student, `@alueducation.com` → staff).
- **Nobody can change their own role** from the app. Roles can only be changed by an admin in the Firebase console.
- Only **verified students** can create reports, only as themselves, and every new report starts as `pending`.
- Students can only read their own reports, and can only edit or delete them while they are `pending`.
- Staff can read all reports but can **only** change `status` and add to `history`.

**Testing the staff role:** a verified student account was promoted to `staff` by changing its `role` field in the Firebase console, the same way a real admin would grant staff access.

---

## Getting started

### Requirements
- Flutter SDK (3.x) and Android Studio, or Xcode for iOS
- An Android or iOS device or emulator

### Run
```bash
cd incident_report_app
flutter pub get
flutter run
```

The app is already connected to its Firebase project (`lib/firebase_options.dart` and `android/app/google-services.json`). These are client configuration files and are safe to commit. Access to data is protected by the security rules.

### Use your own Firebase project (optional)
1. Create a Firebase project and enable **Email/Password** sign-in.
2. Create a **Cloud Firestore** database.
3. Run `flutterfire configure` inside `incident_report_app/`.
4. Paste [`firestore.rules`](incident_report_app/firestore.rules) into **Firestore → Rules** and publish.
5. Replace the Cloudinary cloud name and upload preset in `lib/services/cloudinary_service.dart`.

---

## Testing

```bash
cd incident_report_app
flutter test
```

- **Unit tests:** email/password validation, role-to-domain rules, search and filters, timeline history parsing, relative time formatting
- **Widget tests:** report form validation and the "Others" field, loading button, password visibility toggle, search highlighting, report cards, incident tracker timeline
- **Manual testing** on a physical Android phone (Samsung Galaxy S22 Ultra) for the full student and staff workflows, including offline behaviour

---

## Known limitations

- Photos stay on Cloudinary when a report is deleted, because unsigned uploads cannot be deleted from the app.
- There is no limit on how many reports a student can submit.
- Staff roles are assigned manually in the Firebase console.
