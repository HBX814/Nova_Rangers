# ==============================================================================
# deploy.ps1 - CommunityPulse Backend Deployment Script (Windows / PowerShell)
# ==============================================================================
# Usage: .\scripts\deploy.ps1
# Requires: Docker Desktop, gcloud CLI (authenticated), .env in project root
# ==============================================================================

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$EnvFile     = Join-Path $ProjectRoot ".env"
$Dockerfile  = Join-Path $ProjectRoot "docker\Dockerfile.backend"

$FullImage = "asia-south1-docker.pkg.dev/communitypulse-nova-rangers/communitypulse/backend:latest"

$CloudRunService  = "communitypulse-api"
$CloudRunRegion   = "asia-south1"
$CloudRunPlatform = "managed"

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
function Log-Info  { param($msg) Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Log-Ok    { param($msg) Write-Host "[ OK ]  $msg" -ForegroundColor Green }
function Log-Step  { param($msg) Write-Host "`n==> $msg" -ForegroundColor Yellow }
function Log-Error {
    param($msg)
    Write-Host "[ERR ]  $msg" -ForegroundColor Red
    throw "Deployment failed: $msg"
}

# ------------------------------------------------------------------------------
# Pre-flight checks
# ------------------------------------------------------------------------------
Log-Step "Running pre-flight checks..."

if (-not (Get-Command docker  -ErrorAction SilentlyContinue)) { Log-Error "docker is not installed or not in PATH." }
if (-not (Get-Command gcloud  -ErrorAction SilentlyContinue)) { Log-Error "gcloud is not installed or not in PATH." }
if (-not (Test-Path $EnvFile))    { Log-Error ".env file not found at: $EnvFile" }
if (-not (Test-Path $Dockerfile)) { Log-Error "Dockerfile not found at: $Dockerfile" }

Log-Ok "All pre-flight checks passed."

# ------------------------------------------------------------------------------
# Load environment variables from .env
# ------------------------------------------------------------------------------
Log-Step "Loading environment variables from .env..."

function Get-EnvVar {
    param([string]$Key)
    $line = Get-Content $EnvFile | Where-Object { $_ -match "^${Key}=" } | Select-Object -First 1
    if (-not $line) { Log-Error "Required variable '$Key' not found or empty in $EnvFile" }
    $val = ($line -replace "^${Key}=", "").Trim()
    $val = $val -replace '^["'']|["'']$', ''
    $val = $val.TrimEnd("`r")
    return $val
}

$GCP_PROJECT_ID          = Get-EnvVar "GCP_PROJECT_ID"
$GEMINI_API_KEY          = Get-EnvVar "GEMINI_API_KEY"
$PUBSUB_TOPIC_SUBMISSION = Get-EnvVar "PUBSUB_TOPIC_SUBMISSION"
$PUBSUB_TOPIC_MATCH      = Get-EnvVar "PUBSUB_TOPIC_MATCH"
$RESEND_API_KEY          = Get-EnvVar "RESEND_API_KEY"

Log-Info "GCP_PROJECT_ID          = $GCP_PROJECT_ID"
Log-Info "PUBSUB_TOPIC_SUBMISSION = $PUBSUB_TOPIC_SUBMISSION"
Log-Info "PUBSUB_TOPIC_MATCH      = $PUBSUB_TOPIC_MATCH"
Log-Info "ENVIRONMENT             = production"
Log-Ok "Environment variables loaded."

# ------------------------------------------------------------------------------
# Step 1/4 - Build the Docker image
# ------------------------------------------------------------------------------
Log-Step "Step 1/4 - Building Docker image..."
Log-Info "Dockerfile : $Dockerfile"
Log-Info "Context    : $ProjectRoot"
Log-Info "Tag        : $FullImage"

& docker build --file "$Dockerfile" --tag "$FullImage" "$ProjectRoot"
if ($LASTEXITCODE -ne 0) { Log-Error "docker build failed." }

Log-Ok "Docker image built successfully: $FullImage"

# ------------------------------------------------------------------------------
# Step 2/4 - Push the image to Google Artifact Registry
# ------------------------------------------------------------------------------
Log-Step "Step 2/4 - Pushing image to Google Artifact Registry..."

& gcloud auth configure-docker "asia-south1-docker.pkg.dev" --quiet
if ($LASTEXITCODE -ne 0) { Log-Error "gcloud auth configure-docker failed. Run: gcloud auth login" }

& docker push "$FullImage"
if ($LASTEXITCODE -ne 0) { Log-Error "docker push failed." }

Log-Ok "Image pushed to Artifact Registry: $FullImage"

# ------------------------------------------------------------------------------
# Step 3/4 - Deploy to Cloud Run
# ------------------------------------------------------------------------------
Log-Step "Step 3/4 - Deploying to Cloud Run..."

$EnvVars = "GCP_PROJECT_ID=$GCP_PROJECT_ID," +
           "GEMINI_API_KEY=$GEMINI_API_KEY," +
           "PUBSUB_TOPIC_SUBMISSION=$PUBSUB_TOPIC_SUBMISSION," +
           "PUBSUB_TOPIC_MATCH=$PUBSUB_TOPIC_MATCH," +
           "RESEND_API_KEY=$RESEND_API_KEY," +
           "ENVIRONMENT=production"

$DeployArgs = @(
    "run", "deploy", $CloudRunService,
    "--image",     $FullImage,
    "--region",    $CloudRunRegion,
    "--platform",  $CloudRunPlatform,
    "--allow-unauthenticated",
    "--project",   $GCP_PROJECT_ID,
    "--set-env-vars", $EnvVars,
    "--cpu", "1",
    "--memory", "2Gi",
    "--timeout", "600s",
    "--concurrency", "80",
    "--min-instances", "0",
    "--max-instances", "10"
)

& gcloud @DeployArgs
if ($LASTEXITCODE -ne 0) { Log-Error "gcloud run deploy failed." }

Log-Ok "Deployment complete!"

# ------------------------------------------------------------------------------
# Step 4/4 - Output Service URL
# ------------------------------------------------------------------------------
Log-Step "Step 4/4 - Service URL:"

$FormatArg = "value(status.url)"
$DescribeArgs = @(
    "run", "services", "describe", $CloudRunService,
    "--region",  $CloudRunRegion,
    "--project", $GCP_PROJECT_ID,
    "--format",  $FormatArg
)
& gcloud @DescribeArgs