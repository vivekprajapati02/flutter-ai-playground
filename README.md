# AI Playground

A Flutter playground app demonstrating modern AI capabilities: streaming chat with function calling, retrieval-augmented document Q&A backed by a FastAPI service, on-device OCR, and local chat history — all wired together with GetX and Hive.

## Features

### 🏠 Home
- Quick actions to jump into Chat, Document Chat, OCR, and Product Detection
- Recent chats and recent documents at a glance
- Usage statistics (documents, chats, questions)

### 💬 AI Chat
- Streaming responses from OpenAI GPT
- Markdown rendering
- Conversation history with regenerate, copy, and stop-generation controls
- Typing indicator
- **Function calling** with built-in tools:
  - Open camera / gallery (image capture)
  - BMI calculator
  - QR code generator
  - Currency conversion (via [Frankfurter](https://www.frankfurter.app/) — free, no API key)
  - GitHub profile lookup (via the public GitHub API)

### 📄 Document Chat (RAG)
- Upload PDFs and ask questions grounded in their content
- Cited sources returned alongside answers
- In-app PDF viewer
- Talks to a configurable FastAPI backend (base URL set in Settings, with a connection test)

### 📷 OCR Scanner
- Capture an image or pick one from the gallery
- Extract text on-device with Google ML Kit
- Copy or share extracted text

### 🕘 History
- Persistent chat and document-chat history stored locally with Hive

### ⚙️ Settings
- Configure the RAG backend base URL
- Test connectivity to the backend

## Tech Stack

- **Flutter** with **GetX** for state management and navigation
- **Hive** for local persistence (conversations, RAG history, settings)
- **Dio** for networking
- **google_mlkit_text_recognition** for OCR
- **speech_to_text** for voice input
- **syncfusion_flutter_pdfviewer** for in-app PDF viewing
- **image_picker** / **file_picker** for media and document selection
- **qr_flutter** for QR code generation

## AI & Backend

The app talks to two independent AI surfaces:

### OpenAI (direct, in-app)
`AI Chat` and image generation call the OpenAI REST API directly from Flutter using the key in `.env` — no backend server required for this part:
- **Chat**: `gpt-5.4-mini` via `/v1/chat/completions`, with streaming (SSE) and function calling (`tool_choice: auto`, up to 4 tool round trips)
- **Image generation**: `dall-e-3` via `/v1/images/generations`

### FastAPI backend (Document Chat / RAG)
`Document Chat` sends requests to your own FastAPI service instead of calling OpenAI directly. The base URL is configured from the **Settings** tab (default `http://192.168.1.3:8000`, saved locally via Hive). Expected endpoints:
- `GET /documents` — list uploaded documents
- `POST /documents/upload` — multipart file upload
- `DELETE /documents/{id}` — remove a document
- `POST /chat` — `{"question", "document_id"?}` → `{"answer", "sources"}`
- `GET /health` — used by "Test Connection" in Settings

This backend (FastAPI + Python, typically with a vector database and embeddings for retrieval) is not included in this repo — you run it separately and point the app at it. The AI provider it uses internally (Gemini, OpenAI, etc.) is up to your backend implementation.

## Getting Started

1. Copy `.env.example` to `.env` and fill in your OpenAI API key (used for AI Chat and image generation):
   ```
   OPENAI_API_KEY=your-openai-api-key-here
   ```
2. Install dependencies:
   ```
   flutter pub get
   ```
3. Run the app:
   ```
   flutter run
   ```
4. For Document Chat (RAG), point the app at your FastAPI backend from the **Settings** tab and verify the connection.

## Project Structure

```
lib/
├── controllers/   # GetX controllers (chat, RAG, OCR, history, settings, home)
├── models/        # Data models + Hive adapters
├── pages/         # Screens (home, chat, documents, RAG chat, OCR, history, settings)
├── services/      # API/backend integration (chat, RAG, OCR, tools, history, settings)
├── widgets/       # Reusable UI components
└── main.dart      # App entry point, Hive setup
```
