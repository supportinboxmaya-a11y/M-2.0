-- ═══════════════════════════════════════════════════════════
-- Maya 2.0 — Supabase schema for multi-user support
-- ═══════════════════════════════════════════════════════════
-- HOW TO RUN THIS:
-- 1. Open your Supabase project → SQL Editor → New query
-- 2. Paste this whole file → Run
-- It's safe to re-run (uses IF NOT EXISTS everywhere).

create extension if not exists "pgcrypto";

-- ── Users ──────────────────────────────────────────────────
create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  password_hash text not null,
  name text,
  role text not null default 'user' check (role in ('user', 'admin')),
  budget_usd numeric not null default 5.0,
  budget_used_usd numeric not null default 0,
  banned boolean not null default false,
  created_at timestamptz not null default now()
);

-- ── Chat history (per user, per conversation thread) ────────
-- chat_id is `text`, not `uuid`: the frontend generates conversation IDs as
-- plain timestamp strings (Date.now().toString()), not UUIDs.
create table if not exists chat_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  chat_id text not null,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_chat_messages_user_chat
  on chat_messages(user_id, chat_id, created_at);

-- ── Tasks (per user, persisted — replaces the old in-memory dict) ──
create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  goal text not null,
  status text not null default 'pending',
  steps jsonb not null default '[]',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_tasks_user on tasks(user_id, created_at desc);

-- ── Row Level Security ───────────────────────────────────────
-- The backend talks to Supabase using the SERVICE ROLE key, which bypasses
-- RLS entirely — so the app works with RLS on. We still enable it and add
-- no public policies, so that IF the anon/public key is ever accidentally
-- exposed to the frontend, it gets zero access to this data by default.
alter table users enable row level security;
alter table chat_messages enable row level security;
alter table tasks enable row level security;

-- ── Bootstrap: turn your existing ADMIN_EMAIL into the first admin ──
-- Run this manually AFTER your first successful /auth/register with that
-- email, OR just register normally — the backend auto-assigns the 'admin'
-- role to whichever email matches ADMIN_EMAIL in your backend's env vars.
