# Skill: Apply Repository Practices and Scripts

## Purpose
Apply consistent, repo-native engineering practices and scripts before, during, and after code changes in the NeonGraal/graphql-plus ecosystem.

## Inputs
- `repo_path`: absolute path to repository root
- `change_scope`: `docs` | `frontend` | `backend` | `mixed`
- `strict_mode`: `true` | `false` (default `true`)
- `prefer_scripts`: `true` | `false` (default `true`)

## Outputs
- Selected practice profile
- Ordered command plan
- Validation summary format
- Escalation path for missing or failing scripts

## Skill workflow

1. **Profile repository**
   - Read: `README.md`, `AGENTS.md`, `Style-Guide.md`, `Conventions.md`, `.github/copilot-instructions.md` (if present).
   - Detect scripts: root `*.ps1`, `package.json` scripts, known repo workflows.

2. **Select command plan**
   - If `prefer_scripts=true`, use repo scripts first.
   - Infer workflow order:
     - maintenance: `update.ps1` (optional by task)
     - formatting: `format.ps1` or `npm run lint/prettier`
     - tests: repo test scripts (`test.ps1`, `unit-tests.ps1`, `int-tests.ps1`, `npm test`, `npm run e2e`)
     - coverage/report: `coverage.ps1`, `report.ps1`, summary scripts

3. **Apply repo-specific rules**
   - `graphql-plus`: run `format.ps1`, `test.ps1`, then coverage where relevant; preserve link-check and generated-test flows.
   - `DependGraph`: run frontend + backend checks appropriate to touched files; honor integration gating patterns.
   - `graphql-plus.github.io`: treat `convert.ps1` as required regeneration; do not rely on `npm test`.
   - `kete-kopaki`: use explicit frontend scripts (`build:web`, `test:functional`).

4. **Enforce strictness**
   - If `strict_mode=true`, fail on warnings and style/test failures aligned with repo policy.
   - Do not bypass failing repo-owned scripts without explicit override.

5. **Return structured completion report**
   - `docs_read`: files used as source of truth
   - `scripts_selected`: ordered list of commands
   - `scripts_executed`: pass/fail outcomes
   - `exceptions`: any deviations and why
   - `next_required_step`: only when task is genuinely incomplete

## Command selection map

### .NET-centric repos
Prefer:
```powershell
.\format.ps1
.\test.ps1
.\coverage.ps1
```
Or for split test repos:
```powershell
.\unit-tests.ps1
.\int-tests.ps1
.\coverage.ps1
```

### Frontend repos
Prefer:
```powershell
npm test
npm run e2e
```
and/or repo-specific scripts (`build:web`, `test:functional`).

### DocFX docs repos
Prefer:
```powershell
.\convert.ps1
.\build-local.ps1
```

## Example invocation contract (pseudo-JSON)
```json
{
  "repo_path": "C:\\Dev\\graphql-plus",
  "change_scope": "backend",
  "strict_mode": true,
  "prefer_scripts": true
}
```

## Example expected output (shape)
```json
{
  "practice_profile": "graphql-plus-dotnet-strict",
  "scripts_selected": [".\\format.ps1", ".\\test.ps1", ".\\coverage.ps1"],
  "rules_applied": ["repo-docs-authoritative", "script-first", "strict-validation"],
  "exceptions": []
}
```
