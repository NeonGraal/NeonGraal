# Tool Definition Templates

Annotated template versions of the tooling configuration files used across the
NeonGraal / graphql-plus ecosystem. Copy the relevant files to a new repository
root and adjust the two substitutions described below.

## Required substitutions

| Placeholder | Replace with |
|---|---|
| `MyProject` | Your root namespace / assembly name prefix (e.g. `GqlPlus`, `DependGraph`) |

## Files in this directory

| File | Purpose | Used by |
|---|---|---|
| `.config/dotnet-tools.json` | .NET local tool manifest | `dotnet tool restore`; required before `dotnet coverage`, `reportgenerator`, `dotnet-tools-outdated` |
| `coverage.runsettings` | Code coverage settings (production assemblies only) | `coverage.ps1`, `unit-coverage.ps1`, `int-coverage.ps1` |
| `tests-coverage.runsettings` | Code coverage settings (includes test assemblies) | `coverage.ps1 -IncludeTests` |
| `.prettierrc.yml` | Prettier formatting options | `format.ps1` via `npx prettier` |
| `.prettierignore` | Files/dirs excluded from Prettier | `format.ps1` |
| `Directory.Build.props` | MSBuild solution-wide property defaults | Picked up automatically by MSBuild for all projects |
| `Directory.Packages.props` | Central Package Management version pins | Picked up automatically when `ManagePackageVersionsCentrally=true` |
| `.editorconfig` | Editor behaviour + C# style rules (file-glob scoped) | Editors + `dotnet format` + build (`EnforceCodeStyleInBuild=true`) |
| `.globalconfig` | C# analyzer rules applied globally (no file-glob) | Build only, via `AnalysisLevel` in `Directory.Build.props` |

## Minimal setup for a new .NET repo

```powershell
# 1. Copy files
Copy-Item llm-practices\templates\.config\dotnet-tools.json  .config\dotnet-tools.json
Copy-Item llm-practices\templates\coverage.runsettings       coverage.runsettings
Copy-Item llm-practices\templates\tests-coverage.runsettings tests-coverage.runsettings
Copy-Item llm-practices\templates\.prettierrc.yml            .prettierrc.yml
Copy-Item llm-practices\templates\.prettierignore            .prettierignore
Copy-Item llm-practices\templates\Directory.Build.props      Directory.Build.props
Copy-Item llm-practices\templates\Directory.Packages.props   Directory.Packages.props
Copy-Item llm-practices\templates\.editorconfig              .editorconfig
Copy-Item llm-practices\templates\.globalconfig              .globalconfig

# 2. Replace 'MyProject' with your namespace prefix (e.g. GqlPlus)
$prefix = "GqlPlus"
Get-ChildItem -Recurse -File | ForEach-Object {
    (Get-Content $_) -replace 'MyProject', $prefix | Set-Content $_
}

# 3. Restore tools and verify
dotnet tool restore
dotnet build
```

## Relationship between files

```
Directory.Build.props          ← sets TreatWarningsAsErrors, AnalysisLevel, enables CPM
  └─ Directory.Packages.props  ← version pins for every NuGet package
  └─ .globalconfig             ← C# analyzer/style rules for build enforcement
  └─ .editorconfig             ← editor hints + per-file-glob overrides

format.ps1
  └─ .prettierrc.yml / .prettierignore  ← non-C# formatting
  └─ dotnet format whitespace/style/analyzers  ← uses .editorconfig rules

coverage.ps1
  └─ .config/dotnet-tools.json  ← dotnet-coverage tool
  └─ coverage.runsettings        ← which assemblies to instrument

report.ps1
  └─ .config/dotnet-tools.json  ← reportgenerator tool
```

## Notes on updating tool versions

Run `update.ps1` to check for newer versions. When bumping `.config/dotnet-tools.json`:
- Change the version number.
- Run `dotnet tool restore` to install the new version locally.
- Run `dotnet tool list` to confirm.

When bumping `Directory.Packages.props`:
- `dotnet outdated` (used inside `update.ps1`) shows outdated packages and applies updates.
- After bumping, run `dotnet build` and `./test.ps1` to confirm nothing broke.
