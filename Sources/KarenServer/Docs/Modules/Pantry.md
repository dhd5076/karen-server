# Pantry Module

## Purpose

What this module is responsible for.

## Current MVP

What currently works end-to-end.

## Core Concepts

- Pantry
- Product
- Batch
- Transaction

Short explanation of each.

## User Flows

- Create pantry
- Create product
- Add item to pantry
- Consume batch

## Backend Actions

- `POST /pantry/pantries/:id/add`
- `POST /pantry/batches/:id/consume`
- etc.

## Design Decisions

Short notes like:
- Batches reference products instead of copying unit/name.
- Transactions are append-only-ish history records.
- Direct batch delete exists for MVP/admin convenience but may become adjustment/correction later.

## Deferred

Things intentionally not done yet.

## Future Ideas

Summaries, calories, recipes, LLM tools, barcode scanning, etc.
