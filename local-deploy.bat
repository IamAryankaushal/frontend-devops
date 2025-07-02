@echo off
setlocal enabledelayedexpansion

echo ===============================
echo LOCAL MINIKUBE DEPLOYMENT SCRIPT
echo ===============================

:: Check if Minikube is running
echo Checking Minikube status...
minikube status >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Minikube is not running. Please start it first with: minikube start
    pause
    exit /b
)

echo ✓ Minikube is running
echo.

:: Clean up existing resources
echo [1/6] Cleaning up existing Kubernetes resources...
kubectl delete deployment portfolio-frontend --ignore-not-found=true
kubectl delete service portfolio-service --ignore-not-found=true
kubectl delete configmap portfolio-config --ignore-not-found=true
kubectl delete ingress portfolio-ingress --ignore-not-found=true

echo ✓ Cleanup completed
echo.

:: Switch to Minikube's Docker environment
echo [2/6] Switching to Minikube's Docker environment...
FOR /f "tokens=*" %%i IN ('minikube docker-env --shell cmd') DO %%i

echo ✓ Switched to Minikube Docker environment
echo.

:: Build image directly in Minikube's Docker
echo [3/6] Building Docker image in Minikube...
set IMAGETAG=v%TODAY%_%NOW%
docker build --no-cache -t aryankaushal7/portfolio-frontend:%IMAGETAG% -f dockerstuff/Dockerfile .

IF %ERRORLEVEL% NEQ 0 (
    echo ❌ Docker build failed
    pause
    exit /b
)

echo ✓ Docker image built successfully
echo.

:: Verify image exists
echo Verifying image exists in Minikube...
docker images | findstr portfolio-frontend
IF %ERRORLEVEL% NEQ 0 (
    echo ❌ Image not found in Minikube Docker
    pause
    exit /b
)

echo ✓ Image verified in Minikube Docker
echo.

:: Create temporary deployment file with correct settings
echo [4/6] Creating deployment configuration...
copy kbstuff\deployment.yaml kbstuff\deployment-temp.yaml >nul

:: Update the deployment file with latest tag and Never pull policy
powershell -Command "(Get-Content kbstuff\deployment-temp.yaml) -replace 'image: aryankaushal7/portfolio-frontend.*', 'image: aryankaushal7/portfolio-frontend:latest' -replace 'imagePullPolicy: IfNotPresent', 'imagePullPolicy: Never' | Set-Content kbstuff\deployment-temp.yaml"

echo ✓ Deployment configuration ready
echo.

:: Apply all Kubernetes resources
echo [5/6] Applying Kubernetes resources...

echo   → Applying ConfigMap...
kubectl apply -f kbstuff\configmap.yml

echo   → Applying Deployment...
kubectl apply -f kbstuff\deployment-temp.yaml

echo   → Applying Service...
kubectl apply -f kbstuff\service.yaml

echo   → Applying Ingress...
kubectl apply -f kbstuff\ingress.yaml

echo ✓ All resources applied
echo.

:: Wait for deployment to be ready
echo [6/6] Waiting for deployment to be ready...
kubectl rollout status deployment portfolio-frontend --timeout=60s

IF %ERRORLEVEL% NEQ 0 (
    echo ❌ Deployment failed to become ready
    echo Checking pod status...
    kubectl get pods -l app=portfolio-frontend
    echo.
    echo Describing pod for troubleshooting...
    kubectl describe pod -l app=portfolio-frontend
    pause
    exit /b
)

echo ✓ Deployment is ready!
echo.

:: Clean up temporary file
del kbstuff\deployment-temp.yaml >nul 2>&1

:: Show final status
echo ===============================
echo DEPLOYMENT SUCCESSFUL! 🎉
echo ===============================
echo.
echo Resources created:
kubectl get all -l app=portfolio-frontend
echo.
echo ===============================
echo Opening service in browser...
echo ===============================

:: Open the service
minikube service portfolio-service

echo.
echo Deployment completed successfully!
echo Your portfolio is now running on Minikube.
echo.
pause