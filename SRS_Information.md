# ExamSprint - Software Requirements Specification (SRS) Information

## 1. Project Overview
**Name:** ExamSprint
**Tagline:** Student Resource Sharing App
**Description:** A cross-platform mobile application built to facilitate seamless resource sharing, class management, and intelligent study aids for students and educators. It leverages AI to generate interactive quizzes, study plans, and document summaries to enhance learning efficiency.

## 2. Technology Stack
- **Frontend Framework:** Flutter (Cross-Platform compatibility - iOS/Android)
- **State Management:** Provider
- **Routing:** Go_Router
- **Backend-as-a-Service (BaaS):** Supabase (Handles Authentication, Database, and Storage)
- **AI/ML Engine:** Google Generative AI (Gemini APIs)
- **Push Notifications:** Firebase Cloud Messaging (FCM)
- **Document Processing:** Syncfusion Flutter PDF for extracting text and managing documents.
- **UI Libraries:** Google Fonts, Shimmer (loading animations), Flutter Staggered Animations.

## 3. Core Features & Capabilities

### 3.1 User & Class Management
- **Authentication:** Secure sign-up/login managed via Supabase.
- **Roles:** Hierarchy setup within classes: `admin`, `co_admin`, and `member`.
- **Class Organization:** Users can create or join specific classes (identified by tracking fields like class code, semester, department, and university).
- **Profile Management:** Dynamic user profiles including avatars and bios.

### 3.2 Resource Sharing
- **Subject Categorization:** Classes contain subjects acting as folders/categories.
- **Resource Uploads:** Members can upload study materials to subjects.
- **Supported Formats:** PDFs, Docs, PPTs, Images, and direct external Web Links.
- **Tagging:** Resources can be tagged for easier discovery.

### 3.3 Collaboration
- **Discussion Forums:** Integrated chat/discussion boards associated with classes or subjects mimicking threaded communication.
- **Push Notifications:** Real-time push updates for messages, new resources, or class updates.

### 3.4 AI Playground (Core USP)
The app integrates deeply with GenAI to provide specialized educational tools:
- **AI Chat Agent:** Conversational interface allowing users to "talk to their documents" and ask questions directly related to uploaded study materials.
- **Smart Quizzes:** Generates interactive, context-aware quizzes from uploaded text/documents with granular filtering capabilities (e.g., specific chapters or topics focus).
- **AI Summary Engine:** Summarizes large documents to create bite-sized, easily digestible study notes.
- **AI Study Planner:** Automatically formulates structured study plans based on the subject and required learning modules.
- **Text Extraction Services:** Extracts text from PDFs/images on-device to feed the AI models accurately.

## 4. System Architecture & Data Schema (High Level)

### Core Data Models
1. **Profile (`profile.dart`):** Core user details (`id`, `fullName`, `username`, `avatarUrl`, `bio`).
2. **ClassModel (`class_model.dart`):** Defines a learning group (`id`, `name`, `code`, `semester`, `department`, `university`). Tracks member and subject counts.
3. **ClassMember (`class_member.dart`):** Relational linking of Profile to ClassModel, determining explicit role permissions (`admin`, `co_admin`, `member`).
4. **Subject (`subject.dart`):** Academic subjects tied strictly to a specific `classId`.
5. **Resource (`resource.dart`):** Study material objects tied to a `subjectId`. Details include `fileUrl`, `linkUrl`, `fileType`, tags, and the uploader's Profile.
6. **Discussion/Notification (`discussion.dart`, `notification_model.dart`):** Communication logs and user alert schemas.

### Service Layer Design (MVVM-like Architecture)
- **Providers:** Intermediary layer managing UI state (`auth_provider`, `class_provider`, `resource_provider`, `ai_provider`).
- **Services:** Handles direct external API/BaaS communication logic (`auth_service`, `ai_service`, `class_service`, `text_extraction_service`).

## 5. Non-Functional Requirements (Inferred to be derived in SRS)
- **Cross-Platform Consistency:** Should render equivalently on both iOS and Android.
- **Performance:** As AI requires API requests and text extraction processing, background processing with loading animators (Shimmer) is standard to maintain high fidelity UX.
- **Scalability:** Real-time database updates and remote blob storage heavily reliant on Supabase infrastructure constraints. 
- **Security:** Requires Role Based Access Control (RBAC) ensuring only `admins` or `co_admins` possess specific elevated privileges within the context of a class.
