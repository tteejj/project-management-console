# PMC Query Language Reference

## Overview

The PMC Query Language provides a powerful, intuitive way to filter, sort, and display your tasks, projects, and time logs. Access it through the `pmc q` command.

## Basic Syntax

```
pmc q <domain> [filters...] [directives...]
```

### Domains
- `tasks` or `task` - Query task data
- `projects` or `project` - Query project data
- `timelogs` or `timelog` - Query time log data

## Filters

### Project Filters
```bash
@webapp           # Tasks/timelogs for project "webapp"
@"project name"   # Projects with spaces in names
```

### Priority Filters
```bash
p1                # Priority 1 (highest)
p2                # Priority 2 (medium)
p3                # Priority 3 (lowest)
p<=2              # Priority 2 or higher
p1..3             # Priority range 1 to 3
```

### Date Filters
```bash
due:today         # Due today
due:tomorrow      # Due tomorrow
due:+7            # Due in 7 days
due:eow           # Due end of week (Sunday)
due:eom           # Due end of month
due:1m            # Due in 1 month
due:20251225      # Due December 25, 2025 (yyyymmdd)
due:1225          # Due December 25 (current year)
overdue           # Overdue tasks
```

### Status Filters
```bash
status:pending    # Pending tasks
status:done       # Completed tasks
```

### Tag Filters
```bash
#urgent           # Has "urgent" tag
#web #api         # Has both "web" and "api" tags
-#blocked         # Does NOT have "blocked" tag
```

### Text Search
```bash
"database"        # Contains "database" in text
refactor api      # Contains "refactor" and "api"
```

## Directives

### Column Selection
```bash
cols:id,text,due               # Show only specified columns
cols:id,text,due,priority      # Include priority column
```

### Sorting
```bash
sort:due+                      # Sort by due date ascending
sort:priority-                 # Sort by priority descending
sort:due+,priority-            # Multi-column sort
```

### Metrics (Computed Fields)
```bash
metrics:time_week              # Add time logged this week
metrics:time_today             # Add time logged today
metrics:overdue_days           # Add days overdue
metrics:time_week,time_today   # Multiple metrics
```

### Relations
```bash
with:project                   # Include related project data
with:time                      # Include related time data
with:tasks                     # Include related tasks (for projects)
```

### Grouping and Views
```bash
group:status                   # Group by status
group:project                  # Group by project
view:kanban                    # Display as Kanban board
view:list                      # Display as list (default)
```

### Query Management
```bash
save:myquery                   # Save current query as "myquery"
load:myquery                   # Load and execute saved query
```

## Smart Defaults

The query system includes intelligent defaults:

- **Auto-sort by due date** when filtering by due dates
- **Auto-sort by priority** when filtering by priority
- **Auto-kanban view** when grouping by status

## Examples

### Basic Queries
```bash
# Show all high-priority tasks
pmc q tasks p1

# Show tasks due this week
pmc q tasks due:eow

# Show overdue tasks for webapp project
pmc q tasks @webapp overdue
```

### Advanced Queries
```bash
# High-priority tasks due soon with time tracking
pmc q tasks p<=2 due:+7 metrics:time_week cols:id,text,due,priority,time_week

# Kanban board of webapp tasks by status
pmc q tasks @webapp group:status view:kanban

# Project overview with task counts and time
pmc q projects with:tasks metrics:task_count,time_week sort:time_week-
```

### Query Management
```bash
# Save a complex query
pmc q tasks @webapp p<=2 due:+7 group:status save:urgent_webapp

# Load saved query
pmc q load:urgent_webapp

# View query history
pmc q --history
```

## Available Metrics

### Task Metrics
- `time_week` - Minutes logged this week
- `time_today` - Minutes logged today
- `time_month` - Minutes logged this month
- `overdue_days` - Days overdue (0 if not overdue)

### Project Metrics
- `task_count` - Number of tasks in project
- `time_week` - Total minutes logged this week
- `time_month` - Total minutes logged this month
- `overdue_task_count` - Number of overdue tasks

## Tips

1. **Use tab completion** - Press Tab to see available options
2. **Combine filters** - Mix project, priority, and date filters
3. **Save complex queries** - Use `save:` for frequently used queries
4. **Use smart defaults** - Filter by due date for auto-sorting
5. **Interactive results** - All queries launch in interactive mode by default

## Error Handling

The system provides helpful error messages:
- Invalid columns suggest available options
- Invalid metrics list domain-specific metrics
- Invalid dates show supported formats
- Malformed queries explain syntax

## Integration

Query results automatically launch in PMC's interactive grid with:
- ✅ Arrow key navigation
- ✅ Cell-level editing
- ✅ Multi-select support
- ✅ Real-time filtering
- ✅ Professional keyboard shortcuts

The query language is fully integrated with PMC's theming, field schemas, and data validation systems.