# --- Resolve ECR registry URL from current AWS identity ---
$AccountId = (aws sts get-caller-identity --query Account --output text)
$Region    = (aws configure get region)
$EcrBase   = "$AccountId.dkr.ecr.$Region.amazonaws.com"

Write-Host "ECR registry: $EcrBase" -ForegroundColor Green

# --- Authenticate Docker to ECR ---
Write-Host "Logging in to ECR..." -ForegroundColor Cyan
$token = aws ecr get-login-password --region $Region
docker login --username AWS --password $token $EcrBase
if ($LASTEXITCODE -ne 0) {
    Write-Host "ECR login failed" -ForegroundColor Red
    exit 1
}

# --- Worker list ---
$workers = @(
    "summaries-worker"
    "classify-worker"
    "extract-worker"
    "redact-worker"
    "translate-worker"
)

Write-Host "=== Building and pushing worker images ===" -ForegroundColor Cyan

foreach ($worker in $workers) {
    $path  = "workers/$worker"
    $image = "$EcrBase/secure-agent-dev-${worker}:latest"

    Write-Host "`n--- $worker ---" -ForegroundColor Yellow
    Write-Host "Image: $image" -ForegroundColor DarkGray

    if (-Not (Test-Path $path)) {
        Write-Host "Directory not found: $path" -ForegroundColor Red
        exit 1
    }

    # Ensure start.sh is executable
    $startScript = Join-Path $path "start.sh"
    if (Test-Path $startScript) {
        git update-index --chmod=+x $startScript
    }

    docker build -t $image $path
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed for $worker" -ForegroundColor Red
        exit 1
    }

    docker push $image
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Push failed for $worker" -ForegroundColor Red
        exit 1
    }

    Write-Host "$worker done." -ForegroundColor Green
}

# --- Orchestrator ---
Write-Host "`n=== Building and pushing orchestrator image ===" -ForegroundColor Cyan

$orchImage = "$EcrBase/secure-agent-dev-orchestrator:v7"
Write-Host "Image: $orchImage" -ForegroundColor DarkGray

if (-Not (Test-Path "orchestrator")) {
    Write-Host "Directory not found: orchestrator" -ForegroundColor Red
    exit 1
}

$orchStart = "orchestrator/start.sh"
if (Test-Path $orchStart) {
    git update-index --chmod=+x $orchStart
}

docker build -t $orchImage orchestrator
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed for orchestrator" -ForegroundColor Red
    exit 1
}

docker push $orchImage
if ($LASTEXITCODE -ne 0) {
    Write-Host "Push failed for orchestrator" -ForegroundColor Red
    exit 1
}

Write-Host "orchestrator done." -ForegroundColor Green

Write-Host "`n=== All images built and pushed successfully ===" -ForegroundColor Green
