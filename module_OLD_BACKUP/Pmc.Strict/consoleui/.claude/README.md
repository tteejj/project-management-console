# PMC TUI - AI Assistant Configuration

This directory contains documentation, skills, and agent configurations designed to help AI assistants maintain the PMC TUI codebase effectively and prevent regressions.

## Directory Structure

```
.claude/
├── README.md                    # This file
├── docs/                        # Comprehensive documentation
│   ├── README.md               # Documentation index
│   ├── ARCHITECTURE.md         # System architecture overview
│   ├── SCREEN_PATTERNS.md      # Implementation patterns for screens
│   ├── COMMON_FIXES.md         # Recurring issues and solutions
│   ├── WIDGET_CONTRACTS.md     # Widget API reference
│   ├── INTEGRATION_POINTS.md   # Service integration patterns
│   └── REGRESSION_CHECKLIST.md # Testing and validation checklists
├── skills/                      # Skills for specific tasks
│   ├── tui-fix-validator.md    # Validate fixes before applying
│   └── tui-screen-analyzer.md  # Analyze screen implementations
└── agents/                      # Autonomous agent configurations
    ├── tui-regression-checker.md  # Find regressions after changes
    ├── tui-pattern-enforcer.md    # Validate against patterns
    └── tui-impact-analyzer.md     # Trace dependency impacts
```

## Problem Statement

The PMC TUI codebase suffers from frequent regressions where:
1. Fixing one screen breaks another similar screen
2. Changes to base classes or widgets have unintended side effects
3. Patterns are inconsistently applied across screens
4. AI assistants lack context about the architecture and patterns

## Solution

This configuration provides:
1. **Documentation** - Comprehensive reference for architecture and patterns
2. **Skills** - Executable procedures for common maintenance tasks
3. **Agents** - Autonomous tools for analysis, validation, and impact assessment

## Workflow for AI Assistants

### When User Reports a Bug

```
1. User: "Fix cursor in XScreen"
   ↓
2. Invoke skill: tui-fix-validator
   - Input: File path, issue description
   - Output: Validation report with fix recommendations
   ↓
3. Review validation report
   - Understand screen type and patterns
   - Identify similar screens
   - Note verification checklist
   ↓
4. Apply fix to target screen
   ↓
5. Invoke agent: tui-regression-checker
   - Input: Fixed file, fix description
   - Output: List of similar screens with risk assessment
   ↓
6. Check similar screens from report
   - Apply same fix if needed
   - Test each screen
   ↓
7. Invoke agent: tui-pattern-enforcer (after fix)
   - Input: Fixed file, pattern type
   - Output: Pattern compliance report
   ↓
8. If violations: fix them
   If compliant: mark complete
   ↓
9. Run verification checklist from step 2
   ↓
10. Report completion to user with summary
```

### When Making Architecture Changes

```
1. User: "Modify PmcScreen base class"
   ↓
2. Invoke agent: tui-impact-analyzer
   - Input: Component to change, change type
   - Output: Dependency graph + risk assessment
   ↓
3. Review impact report
   - Assess risk level
   - Note required actions
   - Plan testing strategy
   ↓
4. If CRITICAL/HIGH risk:
   - Discuss alternatives with user
   - Consider backward compatibility
   - Plan migration strategy
   ↓
5. Make change
   ↓
6. Execute required actions from impact report
   - Update dependent files
   - Run tests
   - Update documentation
   ↓
7. Invoke agent: tui-regression-checker
   - Verify no unintended breakage
   ↓
8. Report completion with test results
```

### When Learning Codebase

```
1. User: "How do menu screens work?"
   ↓
2. Read docs/SCREEN_PATTERNS.md
   - Find menu screen pattern
   ↓
3. Invoke skill: tui-screen-analyzer
   - Input: Example menu screen file
   - Output: Detailed analysis
   ↓
4. Review analysis report
   - Understand implementation
   - Note patterns and conventions
   ↓
5. Summarize findings for user
```

## Skills Reference

### tui-fix-validator
**Purpose**: Validate fix approach before applying changes

**When**: Before any bug fix

**Inputs**:
- File path of screen to fix
- Description of the issue
- Proposed fix approach

**Outputs**:
- Screen type and pattern
- Current issues found
- Recommended fix approach
- Similar screens to check
- Verification checklist
- Risk assessment

**Usage**:
```
Before applying fix to screens/KanbanScreen.ps1 for menu cursor issue:
1. Read skills/tui-fix-validator.md
2. Follow execution steps
3. Review output report
4. Use recommendations to guide fix
```

### tui-screen-analyzer
**Purpose**: Deep analysis of screen implementation

**When**: When understanding code, refactoring, or documenting

**Inputs**:
- File path to screen file

**Outputs**:
- Class structure analysis
- Lifecycle method analysis
- Rendering analysis
- Input handling analysis
- Widget integration analysis
- Data operation analysis
- Pattern adherence assessment
- Issues and recommendations

**Usage**:
```
To understand TaskListScreen implementation:
1. Read skills/tui-screen-analyzer.md
2. Follow execution steps on screens/TaskListScreen.ps1
3. Review analysis report
4. Use findings to guide work
```

## Agents Reference

### tui-regression-checker
**Agent Type**: Explore (medium thoroughness)

**Purpose**: Find potential regressions after a fix

**When**: After applying any fix to screens, widgets, or services

**Inputs**:
- Fixed file path
- Fix description
- Fix type (menu/form/list/widget/data/rendering/input)

**Outputs**:
- Similar files checked (count)
- Risk assessment by file (HIGH/MEDIUM/LOW/NONE)
- Recommended actions
- Testing scenarios

**Invocation**:
```
After fixing screens/KanbanScreen.ps1:

Use Task tool with:
- subagent_type: "Explore"
- prompt: [content from agents/tui-regression-checker.md]
- description: "Check for regressions after KanbanScreen fix"
```

### tui-pattern-enforcer
**Agent Type**: Explore (quick thoroughness)

**Purpose**: Validate screen against established patterns

**When**: Before and after fixes, during code review

**Inputs**:
- Screen file path
- Expected pattern type

**Outputs**:
- Pattern compliance score
- Violations (CRITICAL/WARNING/SUGGESTION)
- Correct patterns found
- Code examples for fixes

**Invocation**:
```
To validate TaskListScreen against list pattern:

Use Task tool with:
- subagent_type: "Explore"
- prompt: [content from agents/tui-pattern-enforcer.md]
- description: "Validate TaskListScreen pattern compliance"
```

### tui-impact-analyzer
**Agent Type**: Explore (medium thoroughness)

**Purpose**: Trace dependencies and assess change impact

**When**: Before modifying base classes, widgets, or services

**Inputs**:
- Component to analyze
- Component type (base-class/widget/service/screen)

**Outputs**:
- Dependency graph
- Direct and indirect dependents
- Risk summary
- Required actions
- Testing recommendations
- Safety assessment

**Invocation**:
```
Before modifying PmcScreen:

Use Task tool with:
- subagent_type: "Explore"
- prompt: [content from agents/tui-impact-analyzer.md]
- description: "Analyze impact of PmcScreen changes"
```

## Documentation Reference

### ARCHITECTURE.md
High-level system overview covering:
- Core components (PmcScreen, PmcApplication)
- Screen types (Menu, Form, List, Detail)
- Widget system
- Service layer
- Rendering flow
- Navigation patterns

### SCREEN_PATTERNS.md
Implementation patterns for:
- Menu screens
- Form screens
- List screens
- Parent method call patterns
- State passing patterns
- Anti-patterns to avoid

### COMMON_FIXES.md
Catalog of recurring issues:
- Menu cursor issues
- Form input issues
- Data persistence issues
- Navigation issues
- Rendering issues
- List/widget issues
- Regression prevention checklist

### WIDGET_CONTRACTS.md
Widget API reference for:
- UniversalList
- TextInput
- FilterPanel
- ProjectPicker
- InlineEditor
- Integration patterns
- Common mistakes

### INTEGRATION_POINTS.md
Service integration patterns for:
- TaskStore service
- PreferencesService
- ExcelComReader
- Application state
- Screen communication
- Integration patterns

### REGRESSION_CHECKLIST.md
Testing and validation:
- Change impact matrix
- Screen groupings for testing
- Pre-commit checklist
- Regression test scenarios
- Known fragile areas

## Important Notes for AI Assistants

### Always Do
1. **Read before writing** - Understand current code before changing it
2. **Use skills first** - Validate approach before applying fixes
3. **Invoke agents** - Let specialized agents handle complex analysis
4. **Check similar screens** - Regressions happen in related code
5. **Verify patterns** - Ensure changes follow established patterns
6. **Test comprehensively** - Use checklists to guide testing
7. **Update docs** - Keep documentation synchronized with code

### Never Do
1. **Assume patterns** - Always verify from actual code
2. **Skip validation** - Always use fix-validator before changing code
3. **Ignore similar screens** - Always check for same issues elsewhere
4. **Forget regression checks** - Always invoke regression-checker after fixes
5. **Skip parent calls** - Base class methods must be called
6. **Forget .Save()** - TaskStore mutations must be saved
7. **Ignore closure issues** - Event callbacks must use .GetNewClosure()

### Common Pitfalls
1. **Shallow reading** - AI assistants often skim code and miss details
2. **Pattern assumptions** - Assuming patterns without verifying
3. **Regression blindness** - Fixing X breaks Y without noticing
4. **Documentation drift** - Code changes but docs don't
5. **Over-confidence** - Applying fixes without validation

### Success Criteria
A fix is complete when:
- [ ] Fix-validator ran before changes
- [ ] Fix applied to target screen
- [ ] Pattern-enforcer validates compliance
- [ ] Regression-checker found no high-risk issues
- [ ] Similar screens checked and fixed if needed
- [ ] Verification checklist completed
- [ ] User tested and confirmed fix works
- [ ] Documentation updated if patterns changed

## Maintenance

This configuration should be maintained as the codebase evolves:

### When to Update Documentation
- Patterns change or new patterns emerge
- Base classes or widgets are refactored
- Services are added or changed
- Common fixes are discovered

### When to Update Skills
- New types of issues emerge
- Validation procedures improve
- New analysis techniques are needed

### When to Update Agents
- Agent prompts need refinement
- New agent types are needed
- Agent performance needs tuning

### How to Identify Issues
If AI assistants:
- Consistently misunderstand patterns → Update docs
- Apply wrong fixes → Update skills
- Miss regressions → Update agents
- Report outdated information → Update all

## Feedback Loop

Track effectiveness by monitoring:
1. **Regression rate** - Are regressions decreasing?
2. **Fix accuracy** - Are first fixes more often correct?
3. **Pattern compliance** - Are new screens following patterns?
4. **AI confusion** - Are assistants asking fewer clarifying questions?

If metrics aren't improving, investigate and update configuration.

## Version

**Initial Version**: Created 2025-11-12

**Status**: Beta - Needs real-world validation

**Next Steps**:
1. Use configuration on actual bug fixes
2. Measure effectiveness
3. Refine based on results
4. Update documentation with findings
5. Add more skills/agents as needed

## Support

For questions about this configuration:
1. Read this README
2. Check relevant documentation
3. Review skill/agent descriptions
4. Analyze example code
5. Update configuration if patterns have changed
