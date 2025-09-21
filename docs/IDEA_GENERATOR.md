# IDEA Macro/Function Generator (PMC-integrated)

This scaffold helps you generate CaseWare IDEA 12 artifacts:
- Custom Functions: `.ideafunc` (VBScript, UTF-16 LE)
- Macros: `.iss` (IDEAScript)

It aims to let you declaratively compose multi-step macros where later steps
can reference virtual fields or databases created in earlier steps.

## Quick Start (Standalone)

- TUI Builder:
  - `pwsh -NoLogo -File ./tools/idea-builder.ps1`
  - Add steps interactively and Finish to generate `.iss` + save a `.spec.json`.

- Scripted usage (generator only):
  - `pwsh -NoLogo`
  - `. ./tools/idea-gen.ps1`
  - `New-IdeaDemo` → creates `regf.ideafunc` and `PMC_Demo_Macro.iss`

Artifacts are placed under your IDEA Local Library (EN/FR folders autodetected):
- Custom Functions: `<Local Library>/Custom Functions`
- Macros: `<Local Library>/Macros.ILB`

If the Local Library folders are missing, the generator creates them.

## Generate a Custom Function

```
$vb = @'
Option Explicit
Function mytrim(s As String) As String
  mytrim = Trim(s)
End Function
'@
$params = @(
  @{ Type='Character'; Name='s'; Help='Input text' }
)
New-IdeaCustomFunction -Name 'mytrim' -OutputType 'Character' -Parameters $params -Body $vb -Category 'Text'
```

Notes:
- OutputType: `Character|Numeric|Date`
- Body is VBScript; keep it free of IDEA-only COM calls.
- The generator writes UTF-16 LE (as IDEA expects).

## Generate a Macro from Spec

```
$spec = @{ Name='GL_Audit_Flow'; Language='EN'; Steps=@(
  @{ Type='CreateVirtualField'; Name='NET'; DataType='NUM'; Decimals=2; Equation='DEBIT-CREDIT' },
  @{ Type='Extraction'; Keys=@('BATCH','ENTRY'); OutputSuffix='Indexed' },
  @{ Type='Summarize'; GroupBy=@('BATCH'); Sum=@('NET'); OutputSuffix='ByBatch' }
)}
New-IdeaMacroFromSpec -Spec $spec
```

Supported steps (initial set):
- `CreateVirtualField`: `Name`, `DataType` (`NUM|CHAR|DATE`), `Equation`, `Decimals` (NUM only)
- `Extraction`: `Keys` (array), `OutputSuffix` (suffix for new DB name)
- `Summarize`: `GroupBy` (array), `Sum` (array), `OutputSuffix`

The macro template keeps the current database as input, opens it, runs your steps,
and sets `db` to the latest output so subsequent steps can reference prior creations.

## Roadmap (next iterations)

- Add more steps: `FillDown`, `GetNextValue`, `GetPreviousValue`, `IndexOnly`, `FieldDelete`, `FieldRename`, `FilterExtract`.
- EN/FR labels and dialog scaffolds (bring in your “Blank Template Menu” UI to drive params).
- Parameter defaults, validators, and a simple JSON DSL (so specs can be stored in files).
- Install/update commands, versioning, and categories.
- Function library (VB equivalents of IDEA functions not allowed in `.ideafunc`).

## Conventions & Assumptions

- Macros operate on the active database (`Client.CurrentDatabase`); they abort if none is open.
- Names for new DBs are based on the source name plus an `OutputSuffix` (made unique).
- Virtual fields are created using standard TableManagement task patterns.
- You can safely chain steps; `db` is reassigned to the last output DB.

## Troubleshooting

- If IDEA doesn’t see artifacts, open `Local Library` in IDEA and click Refresh.
- If your environment uses non-standard Local Library paths, update `Get-IdeaLocalLibraryPath` in `tools/idea-gen.ps1`.
- If a step is missing from the generator, file an issue or extend `New-IdeaMacroFromSpec` with your pattern.
