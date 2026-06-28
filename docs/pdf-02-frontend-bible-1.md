# PDF 02 - Frontend Bible Part 1

## 1. UI Architecture

### Tech Stack
- Framework: React 18 + TypeScript
- Build Tool: Vite
- Styling: TailwindCSS
- State: Zustand
- Server State: React Query
- Router: React Router v6
- Charts: Recharts
- Icons: Lucide React
- Animations: Framer Motion

### Folder Structure
src/
  components/ui/       # Base UI components
  components/layout/   # Sidebar, TopBar, Layout
  components/dashboard/# Dashboard widgets
  components/chat/     # Chat components
  pages/               # All page components
  store/               # Zustand stores
  types/               # TypeScript types
  lib/                 # Utils & mock data
  hooks/               # Custom hooks
  i18n/                # Translations
  styles/              # Global CSS

## 2. Design System

### Colors
- Background Primary: #0a0b0f
- Background Secondary: #0f1117
- Background Tertiary: #14161e
- Accent Purple: #7c6af7
- Accent Blue: #38bdf8
- Accent Green: #34d399
- Accent Red: #f87171
- Accent Yellow: #fbbf24
- Text Primary: #e2e8f0
- Text Muted: #64748b

### Typography
- Font: Inter (sans), JetBrains Mono (code)
- Sizes: xs(12), sm(13), base(15), lg(17), xl(20), 2xl(24), 3xl(32)

### Base Components
- Button (primary, secondary, ghost, danger)
- Card (default, hover)
- Badge (purple, blue, green, red, yellow)
- Input (with label, error, icon)
- StatusDot (online, offline, error, warning)
- Spinner

## 3. Navigation

### Sidebar Sections
Core: Dashboard, Chat/Tasks, Memory, Tools, Analytics, Cost
Build: Workflow Builder, Plugin Marketplace
AI Studio: Voice Studio, Vision Studio
Backend: Overview, Logs, Memory Inspector, Queue
Enterprise: Team, Security, Testing, Backup, Integrations
System: Notifications, Settings

### Sidebar Features
- Collapsible (icon-only mode)
- Active state highlight
- Agent status indicator
- Unread notification badge

### TopBar
- Search bar (Cmd+K)
- Budget progress indicator
- Notification bell

## 4. Dashboard Page

### Stat Cards
- Total Tasks
- Completed Tasks
- Session Cost
- LLM Calls

### Charts
- Task Performance (7 days) - AreaChart
- Provider Health - status list

### Lists
- Recent Tasks feed
- Top Tools usage

## 5. Chat Workspace

### Modes
- Run Mode: Autonomous task execution
- Chat Mode: Simple conversation
- Think Mode: Deep chain-of-thought reasoning

### Features
- Task list sidebar
- Step-by-step execution display
- Tool call visualization
- Result rendering
- Voice input button
- File attachment
- Cost display per task

### Step Display
- Step number
- Tool badge
- Duration
- Success/Failure indicator
- Result or Error text
