# Weight Training Workout Tracker - Minimal Requirements

## 1. Executive Summary

The Weight Training Workout Tracker is a simple application designed to help users record their weight training sessions. The system focuses on basic session tracking with workout details including reps, sets, weight, and weight units.

## 2. System Overview

### 2.1 Purpose
Provide users with a straightforward way to log their weight training workouts without complex analytics or features.

### 2.2 Target Users
- Individuals who want to track their weight training sessions
- Fitness enthusiasts seeking basic workout logging

### 2.3 Platform Support
- **Web Application**: Responsive design for desktop and mobile browsers
- **Mobile Application**: Native apps for iOS and Android with offline capability

---

## 3. Functional Requirements

### 3.1 User Management

#### 3.1.1 User Registration and Authentication
- **FR-001**: Users must be able to register with email and password
- **FR-002**: Users must be able to log in and log out
- **FR-003**: System must maintain user sessions

#### 3.1.2 User Profile
- **FR-004**: Users must have a basic profile with name and email

### 3.2 Session Management

#### 3.2.1 Session Recording
- **FR-005**: Users must be able to create a new workout session
- **FR-006**: Users must be able to record the date and time of the session
- **FR-007**: Users must be able to add optional notes to a session

### 3.3 Workout Management

#### 3.3.1 Workout Types
- **FR-008**: System must maintain a master table of workout types (e.g., Bench Press, Squat, Deadlift)
- **FR-009**: Users must be able to select from predefined workout types

#### 3.3.2 Workout Details
- **FR-010**: For each workout in a session, users must record:
  - Workout type
  - Number of sets
  - Number of reps per set
  - Weight used
  - Weight unit (e.g., kg, lbs)

### 3.4 Data Viewing

#### 3.4.1 Session History
- **FR-011**: Users must be able to view their past workout sessions
- **FR-012**: Users must be able to view workout details for each session

### 3.5 Mobile App Features

#### 3.5.1 Offline Support
- **FR-013**: Mobile app must allow users to record workouts offline
- **FR-014**: Data must sync automatically when device comes online

#### 3.5.2 Cross-Platform Sync
- **FR-015**: Workouts recorded on mobile must sync to web and vice versa

---

## 4. Data Model

### 4.1 User Table
- user_id (primary key)
- name
- email
- password_hash
- created_at

### 4.2 Workout Types Table
- workout_type_id (primary key)
- name
- description (optional)

### 4.3 Session Table
- session_id (primary key)
- user_id (foreign key)
- session_date
- notes (optional)
- created_at

### 4.4 Workout Table
- workout_id (primary key)
- session_id (foreign key)
- workout_type_id (foreign key)
- sets
- reps
- weight
- weight_unit

---

## 5. Non-Functional Requirements

### 5.1 Performance
- **NFR-001**: System should respond to user actions within 2 seconds
- **NFR-007**: Data synchronization between mobile and web should complete within 30 seconds when online

### 5.2 Security
- **NFR-002**: User passwords must be securely hashed
- **NFR-003**: User data must be protected from unauthorized access

### 5.3 Usability
- **NFR-004**: Interface should be intuitive and easy to use on both web and mobile platforms
- **NFR-005**: Web application should work on desktop and mobile browsers
- **NFR-006**: Mobile app should provide native mobile experience with touch-friendly interface