# 🌱 FutureYou  
### An Intelligent Health Reasoning System

FutureYou is a **future-focused health reasoning platform** that helps users understand how their **daily lifestyle habits compound into long-term health outcomes**, while also organizing scattered medical records into a clear, usable timeline.

This project is **not** a tracker, chatbot, or medical diagnosis tool.  
It is a **decision-support system** designed to make *cause → effect → future impact* visible and understandable.

---

## 📌 Problem Statement

Most people struggle with health decisions not because they lack data, but because they lack **clarity**.

- Daily habits feel small and disconnected  
- Long-term consequences are invisible  
- Medical records are fragmented and unreadable  
- Existing apps track the past but do not explain the future  

**Core problem:**  
> People cannot reason about their future health using their own data.

---

## 💡 Solution Overview

**FutureYou** is an **intelligent health reasoning system** that:

- Simulates future health outcomes (5, 10, 20 years)
- Detects compound lifestyle patterns
- Organizes medical records automatically using AI
- Suggests small, high-impact behavior experiments
- Works with minimal user effort (30-second daily input)

The AI operates **invisibly**—users interact with **tools**, not chatbots.

---

## 🧠 Core Features

### 🔮 Future Simulator
- Interactive sliders for sleep, exercise, diet, and stress
- Visualizes future health trajectories
- Identifies the **highest-leverage lifestyle change**
- Focuses on *relative improvement*, not diagnosis

### 📆 Daily Rhythms
- Ultra-low friction habit logging
- Tap-based inputs (no typing)
- Designed to finish in **under 30 seconds**
- Prioritizes consistency over detail

### 😌 Stress Zones
- 3-tap stress check-ins
- Optional grounding exercises
- Detects stress correlations with sleep, food, and activity
- No journaling or forced meditation

### 🧾 Medical Timeline
- Upload medical PDFs from **any hospital or lab**
- AI extracts events and builds a chronological timeline
- Plain-language summaries with **clickable source citations**
- Medical data enhances predictions but is not required

### 🧪 Action Lab
- Personalized micro-experiments (7–14 days)
- Before/after comparisons
- Impact estimation on future health metrics
- Learns from user behavior (no repeated failed suggestions)

---

## 🧬 AI Reasoning Engine (What Makes This Different)

FutureYou does not simply track data—it **reasons about interactions**.

### Key Capabilities
- **Compound pattern detection**  
  Example loop: poor sleep → higher stress → poorer eating → worse sleep

- **Context-aware modeling**  
  Uses habit trends + stress signals + medical history to adjust projections

- **Leverage-point discovery**  
  Finds which *single* change can break a negative cycle

- **Adaptive suggestions**  
  Experiments evolve based on what works for the user

> This is a **systems-thinking approach** to personal health.

---

## 🆚 Market Differentiation

- **Not a tracker:** unlike Apple Health / Fitbit, FutureYou is **future-looking**, not just historical tracking  
- **Not a mental health content app:** unlike Calm / Headspace, it doesn’t require long sessions or journaling  
- **Not a hospital portal:** it unifies PDFs across providers and explains them  
- **Not a chatbot:** the AI is invisible—users interact with tools (sliders, timelines, experiments)

> **We didn’t copy features — we built a different mental model.**

---

## ✅ What Makes FutureYou Unique

- Predicts future health interactively  
- Detects compound effects across habits  
- Integrates medical history into predictions  
- Works even without medical data  
- Organizes medical records with AI + citations  
- Suggests personalized experiments (not generic advice)  
- No chatbot, no journaling, no gamification  

---

## 🛠️ Tech Stack

### Frontend
- **Flutter**

### Backend
- **Firebase Authentication**
- **Cloud Firestore**
- **Firebase Storage**
- **Firebase Cloud Functions (Gen 2)**

### AI & Infrastructure
- **Google Cloud Run** (custom AI wrapper service)
- **Google Secret Manager** (secure secret handling)
- Async document processing pipeline
- Secure proxy architecture (no API keys in the client)

---

## 🔐 Security & Architecture Highlights

- No secrets stored in the mobile app
- AI calls routed through authenticated Cloud Functions
- Per-user storage paths and controlled access
- Signed URLs for document downloads (when needed)

---

## 🎯 Target Users

- Students and young adults (20–35)
- Users with messy medical records
- Stress-aware but time-poor individuals
- People who want clarity, not motivation hacks
- India-focused, cost-sensitive users

---

## 🚀 Project Status

- ✅ Core UI flows implemented
- ✅ Secure backend architecture deployed
- ✅ AI medical document processing pipeline working
- 🔄 Data wiring and refinement in progress
- 🔜 Simulator calibration and testing

---

## ⚠️ Disclaimer

FutureYou is an **educational and decision-support tool**.  
It is **not** intended to provide medical diagnosis or treatment advice.  
For medical decisions, consult a qualified healthcare professional.

---

## 📄 License

Released for **academic, demonstration, and evaluation purposes**.  
Commercial licensing to be defined.

---

## ✨ Vision

FutureYou aims to **democratize health reasoning**—helping ordinary people understand how daily habits shape their future health, *before* serious problems appear.

> **We don’t tell people what to do. We help them see clearly.**

## 🌐 Live Demo

**Live Demo:** https://futureyou-v21.vercel.app

