# Common Scripts – Best Practice Samples

Each section covers one script archetype found across the NeonGraal/graphql-plus ecosystem.
Samples are annotated with the conventions they encode, and notes explain why each convention matters.

---

## 1. `format.ps1`

**Purpose:** Apply all code formatting in the correct, deterministic order.

**Key conventions:**
- `$ErrorActionPreference = "Stop"` — any tool failure aborts immediately; formatting errors are never silently swallowed.
- `Set-StrictMode -Version Latest` — prevents use of uninitialized variables, unset properties, and other subtle bugs in the script itself.
- Prettier runs first on non-language files (JSON, YAML, Markdown, HTML), then `dotnet format` on C# in three passes matching the order of strictness: whitespace → style → analyzers.
- `-Verify` mode re-uses the same logic for CI checks without duplicating the argument list.
- Reports are written to a `format/` directory so failures can be inspected without re-running.

```powershell
<#
.SYNOPSIS
    Format all source files.
.PARAMETER Verify
    Fail if files are not already formatted (CI mode).
.PARAMETER OnlyPrettier
    Run Prettier only; skip dotnet format.
#>
[CmdletBinding()]
param(
    [switch]$Verify,
    [switch]$OnlyPrettier
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Ensure the report directory exists before writing into it.
New-Item -ItemType Directory -Path "format" -Force | Out-Null

# Prettier handles all non-C# files (JSON, YAML, Markdown, *.md, HTML, etc.).
# -c (check) vs -w (write) is the only difference between verify and fix modes.
$prettierArgs = if ($Verify) { @("-c", ".") } else { @("-w", ".") }
& npx --yes prettier @prettierArgs

if ($OnlyPrettier) { exit }

# dotnet format is split into three passes so that each report is independently actionable.
# --verify-no-changes is the CI equivalent of -c for Prettier.
$dotnetVerifyArgs = if ($Verify) { @("--verify-no-changes") } else { @() }

dotnet format whitespace  --verbosity detailed --severity info @dotnetVerifyArgs `
    --report format/whitespace-report.json  MyProject.slnx

dotnet format style       --verbosity detailed --severity info @dotnetVerifyArgs `
    --report format/style-report.json       MyProject.slnx

dotnet format analyzers   --verbosity detailed --severity info @dotnetVerifyArgs `
    --report format/analyzers-report.json   MyProject.slnx
```

---

## 2. `test.ps1` (build-gated test runner)

**Purpose:** Build then run tests, failing fast on a build error rather than running against stale output.

**Key conventions:**
- `dotnet build` runs first; `$LASTEXITCODE -ne 0` exits early with the real exit code so CI picks up a build failure rather than mysterious test failures.
- Old `TestResults/` directories are removed before each run so result files are never silently stale.
- Filter parameters (`-Section`, `-Filter`) delegate directly to `--filter` without reinventing the syntax.
- `make-summary.ps1` is called at the end so the same human-readable summary is produced locally and in CI.

```powershell
<#
.SYNOPSIS
    Build then run tests.
.PARAMETER Section
    Run only tests whose name contains this string (maps to dotnet --filter .<Section>.).
.PARAMETER Filter
    Pass a raw dotnet test --filter expression.
.PARAMETER Framework
    Target framework moniker suffix (e.g. "10.0" → net10.0).
.PARAMETER ClassTests
    Use the ClassTests solution filter instead of the default one.
#>
[CmdletBinding()]
param(
    [string]$Section   = "",
    [string]$Filter    = "",
    [string]$Framework = "10.0",
    [switch]$ClassTests
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Always build first; never run tests against a stale binary.
dotnet build
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed – aborting tests."
    exit $LASTEXITCODE
}

# Remove stale TRX result files so summary and CI steps read fresh results.
Get-ChildItem test -Filter TestResults -Recurse -Directory |
    Remove-Item -Recurse -Force -ErrorAction Ignore

# Compose the dotnet test argument list.
$testArgs = @(
    "test", "--no-build",
    "--logger", "trx;LogFileName=TestResults-$Framework.trx",
    "--framework", "net$Framework"
)

if ($Section) {
    $testArgs += "--filter", ".$Section."
} elseif ($Filter) {
    $testArgs += "--filter", $Filter
}

$solutionFilter = if ($ClassTests) { "MyProject.ClassTests.slnf" } else { "MyProject.slnx" }
$testArgs += $solutionFilter

dotnet @testArgs

# Always produce a human-readable summary (also written to GITHUB_STEP_SUMMARY in CI).
./make-summary.ps1 -NoCoverage -Framework $Framework -ClassTests:$ClassTests -ShowFailures
```

---

## 3. `unit-tests.ps1` / `int-tests.ps1` (split test scripts)

**Purpose:** Run one test tier (unit or integration) with diagnostics logging.  
Used in repos that separate unit and integration tests into different solution filters.

**Key conventions:**
- Frontend checks run first (fast feedback) before slower backend tests.
- Integration tests pass `-e INTEGRATION_TESTS=true` as an environment variable so tests can self-skip via `[SkippableFact]`.
- `-d` (diagnostics log) is included in the backend invocation so failures have supporting detail without making the default output verbose.

```powershell
# unit-tests.ps1
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Run frontend tests first (fast, fail-fast).
Push-Location app/frontend
try {
    npm test
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}

# Run backend unit tests via the solution filter; diagnostics log aids debugging.
dotnet test --no-build `
    -d logs/unit-diagnostics.log `
    --logger "trx;LogFileName=TestResults-Unit.trx" `
    test/UnitTests.slnf
```

```powershell
# int-tests.ps1
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Frontend E2E checks (Playwright) run first.
Push-Location app/frontend
try {
    npm run e2e
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}

# Integration tests require the gate variable; tests self-skip if it is absent.
dotnet test -e INTEGRATION_TESTS=true --no-build `
    -d logs/int-diagnostics.log `
    --logger "trx;LogFileName=TestResults-Int.trx" `
    test/IntegrationTests.slnf
```

---

## 4. `coverage.ps1` (coverage collection)

**Purpose:** Collect code coverage using `dotnet-coverage` into a Cobertura XML file for later reporting.

**Key conventions:**
- `dotnet tool restore` runs before `dotnet coverage` so the local tool manifest is always satisfied.
- `dotnet build` is gated before coverage collection; stale coverage from a broken build is misleading.
- Old coverage and TRX result files are removed first so reports never blend old and new runs.
- Coverage settings are externalised to a `.runsettings` file rather than inlined so they can be changed without editing the script.
- The coverage file naming convention (`Coverage-<Framework>.xml`) lets `report.ps1` and `make-summary.ps1` use a glob pattern without needing to know what tiers were run.

```powershell
<#
.SYNOPSIS
    Collect code coverage and emit a Cobertura XML file.
.PARAMETER Framework
    Target framework moniker suffix.
.PARAMETER IncludeTests
    Use the tests-inclusive runsettings file.
.PARAMETER ClassTests
    Run class tests instead of the default solution.
#>
[CmdletBinding()]
param(
    [string]$Framework   = "10.0",
    [switch]$IncludeTests,
    [switch]$ClassTests
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Clean previous results so reports are always fresh.
Get-ChildItem coverage -File   -ErrorAction Ignore | Remove-Item -Force -ErrorAction Ignore
Get-ChildItem test -Filter TestResults -Recurse -Directory | Remove-Item -Recurse -Force -ErrorAction Ignore

# Ensure local dotnet tools (dotnet-coverage, reportgenerator) are installed.
dotnet tool restore

dotnet build
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed – aborting coverage collection."
    exit $LASTEXITCODE
}

$coverageFile = "$PWD/coverage/Coverage-$Framework.xml"
$settings     = if ($IncludeTests) { "tests-coverage.runsettings" } else { "coverage.runsettings" }
$solutionFilter = if ($ClassTests) { "MyProject.ClassTests.slnf" } else { "MyProject.slnx" }

$collectArgs = @(
    "collect", "-o", $coverageFile, "-f", "cobertura", "-s", $settings
)
$testArgs = @(
    "test", "--no-build",
    "--logger", "trx;LogFileName=TestResults-$Framework.trx",
    "--framework", "net$Framework",
    $solutionFilter
)

dotnet coverage @collectArgs -- dotnet @testArgs

# Emit a human-readable summary immediately after collection.
./make-summary.ps1 -Framework $Framework -ClassTests:$ClassTests
```

---

## 5. `report.ps1` (coverage HTML report + live preview)

**Purpose:** Turn collected Cobertura XML into an HTML report and open a live-reload server for local review.

**Key conventions:**
- Uses both `MarkdownSummaryGithub` and `Html` report types so the same invocation serves both CI badge markdown and local inspection.
- Risk hotspot thresholds (cyclomatic complexity and CRAP score) are parameterised with sensible defaults so they can be tightened per-project.
- `livereloadserver` is invoked last so the script is non-blocking in normal usage but immediately useful for local review.

```powershell
<#
.SYNOPSIS
    Generate an HTML coverage report and serve it locally.
.PARAMETER Threshold
    Risk hotspot complexity/CRAP threshold (default: 20).
.PARAMETER Framework
    Framework used to select coverage XML files.
#>
[CmdletBinding()]
param(
    [int]$Threshold    = 20,
    [string]$Framework = "10.0"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

dotnet tool restore

$coverageGlob = "$PWD/coverage/Coverage-$Framework*.xml"

$reportArgs = @(
    "-reporttypes:MarkdownSummaryGithub;Html",
    "-reports:$coverageGlob",
    "-targetdir:./coverage",
    "settings:rawMode=true",
    "-title:MyProject Coverage Report ($Framework)",
    "riskHotspotsAnalysisThresholds:metricThresholdForCyclomaticComplexity=$Threshold",
    "riskHotspotsAnalysisThresholds:metricThresholdForCrapScore=$Threshold"
)

dotnet reportgenerator @reportArgs

# Serve the report with live-reload for comfortable local review.
dotnet livereloadserver coverage --port 5300
```

---

## 6. `make-summary.ps1` (test + coverage summary)

**Purpose:** Parse TRX and Cobertura XML files into human-readable output and GitHub-flavoured Markdown badge lines; write to `GITHUB_STEP_SUMMARY` when running in CI.

**Key conventions:**
- Badge generation and plain-text summary share the same data so there is a single source of truth for numbers.
- `GITHUB_STEP_SUMMARY` is populated when the env variable is set; the script does not need to know whether it is running in CI.
- `GITHUB_OUTPUT` receives a `coverage_badge=` line so downstream workflow steps can embed the badge without re-parsing.
- Functions are named `Convert-*` (badge Markdown) and `Write-*` (console text) to make the distinction clear.
- A `$NoCoverage` guard is used when coverage XML is absent so the script is safe to call from `test.ps1` (which does not collect coverage).

```powershell
<#
.SYNOPSIS
    Summarise test results and coverage from TRX and Cobertura XML files.
.PARAMETER NoCoverage
    Skip coverage summary even if XML files are present.
.PARAMETER ShowFailures
    Print individual test failure messages when tests fail.
.PARAMETER Framework
    Framework suffix to filter TRX and XML files.
#>
[CmdletBinding()]
param(
    [switch]$NoCoverage,
    [switch]$ShowFailures,
    [string]$Framework = "10.0"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# --- Badge helpers -----------------------------------------------------------

function Get-Badge([object[]]$Params, [string]$Label, [string]$Body, [string]$Colour, [string]$Prefix = "") {
    $labelText = $Label -f $Params
    $bodyText  = ($Body  -f $Params) -replace " ", "_"
    "$Prefix![$labelText](https://img.shields.io/badge/$bodyText-$Colour)"
}

function Convert-Tests([hashtable]$Test, [string]$Prefix = "") {
    $p = ($Test.label -replace " ", "_"), $Test.failed, $Test.error, $Test.passed, $Test.skipped
    if (($Test.failed + $Test.error) -eq 0) {
        Get-Badge $p "$($Test.label) successful" "{0}-{3:d}_passed%2C_{4:d}_skipped"           "6F6" $Prefix
    } else {
        Get-Badge $p "$($Test.label) FAILED"     "{0}-{1:d}_failed%2C{2:d}_errored%2C{3:d}_passed" "F66" $Prefix
    }
}

function Write-Tests([hashtable]$Test, [string]$Prefix = "") {
    $p = $Test.label, $Test.failed, $Test.error, $Test.passed, $Test.skipped
    $msg = if (($Test.failed + $Test.error) -eq 0) {
        "{0} successful: {3:d} passed, {4:d} skipped" -f $p
    } else {
        "{0} FAILED: {1:d} failed, {2:d} errored, {3:d} passed, {4:d} skipped" -f $p
    }
    Write-Host "$Prefix$msg"
}

function Convert-Coverage([hashtable]$Cover, [string]$Prefix = "") {
    $pct = if ($Cover.linesValid -gt 0) { $Cover.linesCovered * 100.0 / $Cover.linesValid } else { 0.0 }
    $p   = $pct, $Cover.linesCovered, $Cover.linesValid, $Cover.label
    $col = if ($pct -gt 80) { "ACF" } else { "CAF" }
    Get-Badge $p "{3} Coverage" "{3}_Coverage-{0:f2}%25_covered_{1:d}_of_{2:d}" $col $Prefix
}

function Write-Coverage([hashtable]$Cover, [string]$Prefix = "") {
    $pct = if ($Cover.linesValid -gt 0) { $Cover.linesCovered * 100.0 / $Cover.linesValid } else { 0.0 }
    $p   = $pct, $Cover.linesCovered, $Cover.linesValid, ($Cover.label -replace "_", " ")
    Write-Host ("$Prefix{3} Coverage: {0:f2}% covered – {1:d} of {2:d} lines" -f $p)
}

# --- Aggregate test results --------------------------------------------------

[hashtable]$allTests = @{ label = "All Tests"; total = 0; skipped = 0; passed = 0; failed = 0; error = 0 }

$tests = Get-ChildItem . -Recurse -Filter "TestResults-$Framework*.trx" | ForEach-Object {
    [xml]$trx   = Get-Content $_.FullName
    $counts     = $trx.TestRun.ResultSummary.Counters
    $total      = [int]$counts.total
    $skipped    = $total - [int]$counts.executed
    $name       = $_.Directory.Parent.Name -replace "MyProject\.", "" -replace "\.", " "

    $allTests.total   += $total
    $allTests.skipped += $skipped
    $allTests.passed  += [int]$counts.passed
    $allTests.failed  += [int]$counts.failed
    $allTests.error   += [int]$counts.error

    @{ label = $name; total = $total; skipped = $skipped
       passed = [int]$counts.passed; failed = [int]$counts.failed; error = [int]$counts.error }
} | Sort-Object { $_['label'] }

# --- Aggregate coverage (optional) ------------------------------------------

$NoCoverage = $NoCoverage -or -not (Test-Path "coverage/Coverage-$Framework*.xml")

[hashtable]$allCoverage = @{ label = "All"; linesCovered = 0; linesValid = 0 }

$coverage = if (-not $NoCoverage) {
    Get-ChildItem coverage -Filter "Coverage-$Framework*.xml" | ForEach-Object {
        [xml]$xml   = Get-Content $_.FullName
        $lines      = $xml.coverage
        $allCoverage.linesCovered += [int]$lines."lines-covered"
        $allCoverage.linesValid   += [int]$lines."lines-valid"
        $label = $_.BaseName -replace "Coverage-", "" -replace "-", " "
        @{ label = $label; linesCovered = [int]$lines."lines-covered"; linesValid = [int]$lines."lines-valid" }
    } | Sort-Object { $_['label'] }
}

# --- Write console summary ---------------------------------------------------

Write-Tests $allTests
$tests | ForEach-Object { Write-Tests $_ "- " }

if (-not $NoCoverage) {
    Write-Coverage $allCoverage
    $coverage | ForEach-Object { Write-Coverage $_ "- " }
}

# --- Write Markdown summary (local file) ------------------------------------

Set-Content summary.md "# Summary"
Convert-Tests $allTests "`n"        | Add-Content summary.md
$tests    | ForEach-Object { Convert-Tests    $_ "- " | Add-Content summary.md }
if (-not $NoCoverage) {
    Convert-Coverage $allCoverage "`n" | Add-Content summary.md
    $coverage | ForEach-Object { Convert-Coverage $_ "- " | Add-Content summary.md }
}

# --- CI integration ---------------------------------------------------------

# Populate GitHub Actions step summary when running in CI.
if ($env:GITHUB_STEP_SUMMARY) {
    Convert-Tests $allTests "`n"     | Set-Content  $env:GITHUB_STEP_SUMMARY
    $tests    | ForEach-Object { Convert-Tests    $_ "- " | Add-Content $env:GITHUB_STEP_SUMMARY }
    if (-not $NoCoverage) {
        Convert-Coverage $allCoverage "`n" | Add-Content $env:GITHUB_STEP_SUMMARY
        $coverage | ForEach-Object { Convert-Coverage $_ "- " | Add-Content $env:GITHUB_STEP_SUMMARY }
    }
}

# Provide the coverage badge as a workflow output.
if ($env:GITHUB_OUTPUT -and -not $NoCoverage) {
    Convert-Coverage $allCoverage "coverage_badge=" | Set-Content $env:GITHUB_OUTPUT
}
```

---

## 7. `update.ps1` (dependency updater)

**Purpose:** Update all package ecosystems in the repository to their latest compatible versions.

**Key conventions:**
- GitHub Actions pin versions are updated first (minor-only by default) using `actions-up` before source dependencies so CI stays compatible.
- `dotnet outdated` is run in two passes: minor patch (auto-updated) and then major (auto-updated with exclusions) so breaking upgrades are visible but still automated.
- `dotnet list package --deprecated --vulnerable` is always run at the end as a security hygiene check.
- `dotnet tools-outdated` checks the local tool manifest and prints actionable instructions if tools are behind.
- NPM dependencies are updated with `npm-check-updates` minor-first, then `npm install` so the lockfile is refreshed before reporting remaining majors.

```powershell
<#
.SYNOPSIS
    Update all package ecosystems to latest compatible versions.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# --- GitHub Actions: update pinned versions to latest minor ------------------
Write-Host "=== GitHub Actions ===" -ForegroundColor Cyan
npx --yes actions-up --mode minor --style preserve --yes

# --- NPM (if a frontend exists) ---------------------------------------------
$frontendPath = "app/frontend"
if (Test-Path $frontendPath) {
    Write-Host "`n=== NPM ($frontendPath) ===" -ForegroundColor Cyan
    Push-Location $frontendPath
    try {
        npx npm-check-updates -t minor -u   # update package.json to minor
        npm install                          # refresh lockfile
        npx npm-check-updates               # report remaining majors
    } finally {
        Pop-Location
    }
}

# --- NuGet ------------------------------------------------------------------
Write-Host "`n=== NuGet ===" -ForegroundColor Cyan
dotnet tool restore

# Packages excluded from major upgrades because they require coordinated changes.
$excludeArgs = "-exc", "Basic.Reference.Assemblies", "-exc", "Microsoft.CodeAnalysis.CSharp"

dotnet outdated .\ -vl minor -u                        # update patch/minor automatically
dotnet outdated .\ -vl major -u @excludeArgs           # update major (with exclusions)
dotnet outdated .\ @excludeArgs                        # report remaining outdated packages

# Security / deprecation audit.
dotnet list package --deprecated
dotnet list package --vulnerable --include-transitive

# --- .NET local tools -------------------------------------------------------
Write-Host "`n=== .NET Local Tools ===" -ForegroundColor Cyan
dotnet tools-outdated
if ($LASTEXITCODE -ne 0) {
    Write-Host "  → Update with: dotnet tool update (<tool> | --all)" -ForegroundColor Yellow
}

# --- GitHub Actions: dry-run to confirm no further updates ------------------
Write-Host "`n=== GitHub Actions (dry-run check) ===" -ForegroundColor Cyan
npx actions-up --style preserve --dry-run
if ($LASTEXITCODE -ne 0) {
    Write-Host "  → Update with: npx actions-up --style preserve" -ForegroundColor Yellow
}
```

---

## 8. `build.ps1` (multi-stage build orchestration)

**Purpose:** Install frontend dependencies and build all parts of a mixed solution in the correct dependency order.

**Key conventions:**
- `npm install` is scoped to its directory with `Push-Location`/`Pop-Location` + `try/finally` so the working directory is always restored even on failure.
- Build order is explicit: frontend dependencies first, then dependent test fixtures, then the main solution (which embeds the frontend output).

```powershell
<#
.SYNOPSIS
    Install dependencies and build all projects.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Install frontend dependencies first so the backend build can embed the output.
Push-Location app/frontend
try {
    npm install
} finally {
    Pop-Location
}

# Build in dependency order.
dotnet build test/sample/MyProject.Sample.sln    # sample data used by integration tests
dotnet build test/fixtures/MyProject.Fixtures.sln
dotnet build                                      # main solution (embeds frontend)
```

---

## Conventions Reference

| Convention | Explanation |
|---|---|
| `$ErrorActionPreference = "Stop"` | Turns all cmdlet errors into terminating errors; prevents silent partial failures. |
| `Set-StrictMode -Version Latest` | Prevents use of uninitialised variables and non-existent properties in scripts themselves. |
| `Push-Location`/`Pop-Location` + `try/finally` | Guarantees working directory is restored even when a command inside fails. |
| Exit code propagation `exit $LASTEXITCODE` | Preserves the native tool's exit code so CI sees the real failure signal. |
| `dotnet build` gate before test/coverage | Avoids cryptic test failures caused by stale or missing compiled output. |
| `dotnet tool restore` before tool invocations | Ensures all `.config/dotnet-tools.json` tools are installed without requiring global state. |
| Clean coverage/TRX before each run | Prevents reports from blending stale and fresh data. |
| Framework-tagged output files (`Coverage-10.0.xml`) | Allows multiple framework runs without overwriting each other; glob patterns in report scripts pick all of them up automatically. |
| Externalized `.runsettings` | Keeps coverage exclusion rules separate from automation scripts; both scripts and CI reference the same file. |
| `GITHUB_STEP_SUMMARY` / `GITHUB_OUTPUT` population | Makes scripts CI-native without needing separate CI-only scripts. |
