-- Maya 2.0 D1 Database Schema

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY,
  goal TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  result TEXT,
  error TEXT,
  steps TEXT,
  created_at TEXT,
  completed_at TEXT
);

-- Memories table
CREATE TABLE IF NOT EXISTS memories (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  memory_type TEXT DEFAULT 'general',
  metadata TEXT,
  created_at TEXT
);

-- Episodes table (past task runs)
CREATE TABLE IF NOT EXISTS episodes (
  id TEXT PRIMARY KEY,
  goal TEXT NOT NULL,
  steps TEXT,
  result TEXT,
  success INTEGER DEFAULT 0,
  created_at TEXT
);

-- Experiences table (lessons learned)
CREATE TABLE IF NOT EXISTS experiences (
  id TEXT PRIMARY KEY,
  task TEXT NOT NULL,
  lesson TEXT,
  pattern TEXT,
  future_tip TEXT,
  success INTEGER DEFAULT 0,
  created_at TEXT
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_memories_type ON memories(memory_type);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_episodes_success ON episodes(success);
