# Design Document: PMC Query Engine (`q` command)

## 1. Introduction & Motivation (The "Why")

**Problem:**
Your PMC application manages a wealth of interconnected data: tasks, projects, and timelogs. Currently, accessing this data is limited to predefined commands (`task list`, `project view`, etc.). This makes it difficult to answer complex, ad-hoc questions or to visualize your data in different ways.

For example, you can't easily ask:
*   "Show me all high-priority tasks for the `@webapp` project that are due in the next week, sorted by due date."
*   "Which of my projects had the most time logged against them last month?"
*   "Let me see my pending tasks as a Kanban board grouped by status."

To answer these questions today, you would need to manually export data or write custom scripts, which is inefficient.

**Solution:**
We will build a powerful, unified query engine accessible via a new `pmc q` command. This feature will allow you to slice, dice, aggregate, and view your data on the fly, directly from the command line, using a simple and intuitive syntax. It's designed to feel like a natural extension of PMC's existing "strict and typed" philosophy.

---

## 2. Core Concepts (The "What")

This engine is built on a few key concepts:

*   **The `q` Command:** A new, top-level command, `pmc q`, is the exclusive entry point for this feature. This creates a clear boundary; when you type `pmc q`, you are entering "query mode." This separation prevents confusion with existing commands and simplifies development.

*   **A Simple, Composable Language:** We are deliberately avoiding a complex language like SQL. Instead, the `q` command uses a sequence of simple, space-separated **tokens**. Each token is either a **filter** or a **directive**. This makes queries easy to read, write, and, most importantly, **tab-complete**.

*   **Domains:** The first token after `q` is the primary **domain** you are querying. This is the "noun" of your query.
    *   `tasks` (or `task`)
    *   `projects` (or `project`)
    *   `timelogs` (or `timelog`)

*   **Filters:** These are tokens that narrow down your result set. They are designed to be identical to the tokens you already use in PMC, preserving muscle memory.
    *   `@project`: Filters by project.
    *   `p1`, `p2`, `p<=2`: Filters by priority.
    *   `due:today`, `due:<+7`: Filters by due date.
    *   `#tag`, `-#wip`: Includes or excludes tags.
    *   `"some text"`: A quoted string performs a full-text search.

*   **Directives:** These are special, colon-terminated keywords that shape the data and the final output. They are the "verbs" of your query.
    *   `with:[domain]`: Attaches related data (e.g., show project info on a task row).
    *   `metrics:[name,...]`: Calculates new, computed columns (e.g., `time_week`).
    *   `cols:[field,...]`: Selects which columns to display.
    *   `sort:[field]±,...`: Specifies sorting order (`+` for ascending, `-` for descending).
    *   `group:[field]`: Groups results by a specific field.
    *   `view:[type]`: Chooses the renderer (e.g., `list` or `kanban`).
    *   `save:[alias]`: Saves the current query for future use.
    *   `load:[alias]`: Executes a saved query.

*   **History and Aliases:** To avoid re-typing common queries, the engine will feature:
    *   **History:** All executed queries will be automatically logged. A new command or flag will allow you to view and re-run previous queries.
    *   **Aliases:** Using the `save:` directive, you can name a complex query. You can then re-run it instantly using the `load:` directive.

---

## 3. User Guide & Examples (The "How")

The best way to understand the `q` command is to see it in action, from simple to complex.

**A. Basic Filtering (Finding Your Data)**
```powershell
# Show all tasks containing the text "refactor"
pmc q tasks "refactor"

# Show all high-priority tasks for the @webapp project
pmc q tasks @webapp p1
```

**B. Shaping the Output (`cols:` and `sort:`)**
```powershell
# Show tasks for @webapp, sorted with the nearest due dates first
pmc q tasks @webapp sort:due+

# Show only the ID, Text, and Due date columns
pmc q tasks @webapp sort:due+ cols:id,text,due
```

**C. Combining Data (`with:` and `metrics:`)**
```powershell
# For each task, show the time logged against it today.
pmc q tasks with:time metrics:time_today cols:id,text,time_today

# Show all projects, with a count of their tasks and total time logged this week.
pmc q projects with:tasks with:time metrics:task_count,time_week sort:time_week-
```

**D. Changing the View (`group:` and `view:`)**
```powershell
# Show tasks grouped by their status. This will render as a list with headers.
pmc q tasks group:status

# Render tasks as a Kanban board, with a column for each status.
pmc q tasks group:status view:kanban
```

**E. Saving and Reusing Queries (`save:`, `load:`, and History)**

This is key for efficiency.

```powershell
# 1. Run a complex query and save it with the alias "my_kanban"
pmc q tasks @webapp p<=1 due:<+8 with:time metrics:time_week group:status view:kanban save:my_kanban

# 2. Later, you can instantly run that exact same query
pmc q load:my_kanban

# 3. View your query history
pmc q --history 
# Output:
# -5: q tasks "refactor"
# -4: q tasks @webapp p1
# -3: q tasks @webapp sort:due+
# -2: q projects with:tasks metrics:task_count
# -1: q load:my_kanban

# 4. Re-run the 4th query from your history
pmc q --rerun -4 
```

---

## 4. Implementation Details

**A. New Files**

*   `module/Pmc.Strict/src/Query.ps1`: Contains the `Invoke-PmcQuery` function (`q` command), parser, and tab-completion logic.
*   `module/Pmc.Strict/src/QuerySpec.ps1`: Defines the `PmcQuerySpec` class, the contract between parser and evaluator.
*   `module/Pmc.Strict/src/ComputedFields.ps1`: A registry for all allowed `with` relations and `metrics`.
*   `module/Pmc.Strict/src/QueryEvaluator.ps1`: The engine that executes a `QuerySpec`.
*   `~/.pmc/query_aliases.json`: A file to store named query aliases created with `save:`.
*   `~/.pmc/query_history.log`: A simple text file appending every query executed.

**B. Data Flow**

1.  A user runs `pmc q ...`.
2.  The **Argument Completer** in `Query.ps1` provides suggestions.
3.  If `load:my_alias` is used, the system reads `query_aliases.json`, replaces the arguments with the saved query, and proceeds.
4.  The **Parser** in `Query.ps1` builds a `PmcQuerySpec` object from the tokens.
5.  The full query is logged to `query_history.log`.
6.  If `save:my_alias` is used, the query string is written to `query_aliases.json`.
7.  The `QuerySpec` is passed to the **Query Evaluator**.
8.  The Evaluator loads data, consults `ComputedFields.ps1` to resolve relations and metrics, and applies filters.
9.  The final data set is passed to `Show-PmcDataGrid` for rendering.

**C. Phased Implementation Plan**

*   **Phase 1: The Walking Skeleton:** Get the basic `q` command, `QuerySpec` class, parser, and renderer path working.
*   **Phase 2: The Registry:** Build `ComputedFields.ps1` and define the initial metrics/relations.
*   **Phase 3: The Evaluator Engine:** Implement the core logic for filtering, `with`, and `metrics`.
*   **Phase 4: Advanced Views:** Build the `view:kanban` renderer.
*   **Phase 5: Persistence and UX:** Implement `save:`, `load:`, and the history mechanism. Finally, build the interactive query bar in the grid UI.
