# PowerShell script to build and test the single-image Docker container locally

Write-Host "🚀 Building single-image Docker container..." -ForegroundColor Cyan

# Build the Docker image
docker build -f Dockerfile.single -t practice-software-testing:single .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To run the container locally, use one of these commands:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "With SQLite (no external database needed):" -ForegroundColor White
    Write-Host "docker run -p 8080:8080 -e DB_CONNECTION=sqlite -e DB_DATABASE=/tmp/database.sqlite -e SEED_DATABASE=true practice-software-testing:single" -ForegroundColor Gray
    Write-Host ""
    Write-Host "With MySQL:" -ForegroundColor White
    Write-Host "docker run -p 8080:8080 -e DB_CONNECTION=mysql -e DB_HOST=your-host -e DB_PORT=3306 -e DB_DATABASE=toolshop -e DB_USERNAME=user -e DB_PASSWORD=pass -e SEED_DATABASE=true practice-software-testing:single" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Then access the application at: http://localhost:8080" -ForegroundColor Green
} else {
    Write-Host "❌ Build failed. Please check the error messages above." -ForegroundColor Red
    exit 1
}
