# Common Practices Guide for Coding LLMs (NeonGraal / graphql-plus ecosystem)

## Scope and source baseline
This guide is derived from repository patterns found under `C:\Dev` (depth <= 2), with emphasis on:
- `graphql-plus`
- `DependGraph`
- `NeonGraal`
- `graphql-plus.github.io`
- `kete-kopaki` (frontend script shape)

## Core operating practices

1. **Treat repo docs as authoritative**
   - Read `README.md` first for build/test/format commands.
   - If present, read `AGENTS.md`, `Style-Guide.md`, `Conventions.md`, and `.github/copilot-instructions.md`.
   - Prefer local repo conventions over global defaults.

2. **Plan first, then change narrowly**
   - Establish scope before edits.
   - Keep edits focused and avoid unrelated cleanup.
   - Group related changes logically.

3. **Use script-first workflows**
   - Prefer checked-in scripts (`*.ps1`) over ad-hoc commands.
   - Respect command ordering patterns already used by the repo.

4. **Prefer strict validation**
   - Run format + tests + coverage/report where scripts exist.
   - Treat warnings as errors where repo conventions indicate strictness.

5. **Honor generated-content boundaries**
   - Edit source-of-truth files, not generated outputs.
   - Regenerate artifacts using repo scripts before finalizing.

## Script conventions discovered

### Most common script filenames across local repos
- `update.ps1`
- `format.ps1`
- `coverage.ps1`
- `report.ps1`

### Standardized workflow shape
`update -> format -> test -> coverage -> summary/report`

### Best-practice script samples
Annotated reference implementations for each script archetype are in
**[`common-scripts-best-practices.md`](./common-scripts-best-practices.md)**.  
They document the conventions encoded by each script and are intended as starting
points when adding a script to a new repository.

### Tool definition templates
Annotated, copy-ready tooling configuration files are in **[`templates/`](./templates/)**:

| File | Purpose |
|---|---|
| `.config/dotnet-tools.json` | dotnet local tool manifest (coverage, reportgenerator, tools-outdated) |
| `coverage.runsettings` | Coverage scope + attribute exclusions for production assemblies |
| `tests-coverage.runsettings` | Broader coverage scope including test assemblies |
| `.prettierrc.yml` | Prettier options (printWidth 150, trailingComma all, etc.) |
| `.prettierignore` | Exclude build output and Verify snapshots from formatting |
| `Directory.Build.props` | Solution-wide MSBuild defaults (nullable, analyzers, TreatWarningsAsErrors) |
| `Directory.Packages.props` | Central Package Management version pins |
| `.editorconfig` | Editor + build style rules, naming conventions, diagnostic severities |
| `.globalconfig` | Global C# analyzer/style rules (no file-glob scoping) |

See [`templates/README.md`](./templates/README.md) for the minimal setup steps and file relationship diagram.

## Repo-family playbooks

### A) `graphql-plus` (.NET + test/coverage automation)

**Typical commands**
```powershell
.\format.ps1
.\test.ps1
.\coverage.ps1
```

**Observed practices**
- `dotnet build` gate before tests/coverage.
- PowerShell wrappers compose frontend and backend checks.
- Link integrity (`check-links.ps1`) is part of testing for non-class tests.
- Coverage/report scripts are first-class and should be used instead of handcrafted alternatives.

### B) `DependGraph` (mixed .NET + frontend)

**Typical commands**
```powershell
.\format.ps1
.\unit-tests.ps1
.\int-tests.ps1
.\coverage.ps1
```

**Observed practices**
- Frontend checks run from `app\depend-graph` (`npm test`, `npm run e2e`).
- Backend tests run via solution filters (`test\UnitTests.slnf`, `test\IntegrationTests.slnf`).
- Integration behavior is explicitly gated (`INTEGRATION_TESTS=true`) in scripts.

### C) `graphql-plus.github.io` (DocFX docs pipeline)

**Typical commands**
```powershell
.\convert.ps1
.\build-local.ps1
```

**Observed practices**
- `convert.ps1` is the key regeneration/validation step for generated docs and samples.
- `npm test` is not a meaningful validation signal in this repo.
- Prefer editing source docs and regenerating derived content.

### D) `kete-kopaki` frontend pattern

**Typical commands**
```powershell
npm run build:web
npm run test:functional
```

**Observed practices**
- Scripted frontend build and Playwright functional checks.
- Explicit unit/functional script naming even when unit tests are placeholders.

## Decision framework for coding LLMs

1. Discover and read local guidance docs.
2. Detect available scripts and infer expected workflow.
3. Use the smallest relevant script set for the changed surface.
4. Escalate from targeted to broader validation only when needed.
5. Report outcome with exact scripts used and unresolved risks.

## Recommended script priority order

1. Repo-owned PowerShell scripts (`*.ps1`)
2. Repo-owned `npm run <script>` commands
3. Native tool commands (`dotnet`, `npm`, etc.) only when scripts are absent

## Minimal completion checklist for LLM agents

- Relevant guidance docs read
- Scope and assumptions stated
- Changes localized
- Appropriate scripts executed in repo-native order
- Generated outputs refreshed when required
- Result summarized with any explicit follow-up constraints
