# How Project Specialists Work — A Plain-English Guide

## What This Does

When your project gets big enough that Claude starts forgetting things or mixing up
conventions, this system splits the work into specialists. Each specialist handles
one part of your project and remembers how YOU do things in that area.

You don't need to understand how it works. You just keep building.

## Getting Started

Say something like "help me organize this project" or "this is getting messy."

The system looks at your project files and figures out what specialists you need.
It shows you a one-sentence description of each specialist and asks "Want me to set
this up?" You say yes. That's it.

## What Happens After Setup

Nothing changes about how you work. You still ask Claude to do things the same way
you always have. The difference is that behind the scenes, the right specialist picks
up each task. Your frontend specialist builds pages. Your API specialist handles the
backend. Your tester catches bugs.

Each specialist remembers your patterns. The first time you build a component, the
frontend specialist learns your naming style, your preferred libraries, and where
you put things. Next time, it already knows.

## Checking On Your Specialists

Type `/agents` to see a quick list of your specialists and their status.

If you want more detail, just ask: "how are my agents doing?" or "what does my
frontend specialist know?"

## When Something Goes Wrong

If quality drops, or a specialist seems confused, just say what's happening:
"the frontend isn't matching my style anymore" or "something feels off."

The system diagnoses the issue and offers three choices: **fix it**, **start over**,
or **explain what happened**. These are always the same three options.

## Adding and Removing Specialists

"Add a specialist for deployment" — adds one.
"Remove the tester" — removes one (after confirming).

The system asks before deleting anything.

## The Demo

If you're curious about what specialists actually do differently, say "show me how
this works." The system picks a small task in your actual project, runs it through
the appropriate specialist, and shows you what happened. Takes about 30 seconds.

## What Specialists DON'T Do

They don't change how Claude works for simple questions. If you ask "what's a
for loop?" or "fix this typo," that goes straight to Claude like it always does.
Specialists only activate for project work that falls into their domain.

They don't see each other's work. Your frontend specialist doesn't know what your
API specialist is doing. They're independent.

They don't require maintenance. The system checks their health automatically and
fixes problems before you notice them. If a specialist hasn't been used in 3 months,
it gets cleaned up automatically.
