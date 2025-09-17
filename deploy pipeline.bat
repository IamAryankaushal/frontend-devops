@echo off
setlocal enabledelayedexpansion

echo ===============================
echo LOCAL MINIKUBE DEPLOYMENT SCRIPT
echo ===============================

:: Check Minikube status
echo Checking Minikube status...
minikube status >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Minikube is not running. Please start it first with: minikube start
    pause
    exit /b
)
echo Minikube is running
echo.

:: Clean old resources
echo [1/6] Cleaning old resources...
kubectl delete deployment portfolio-frontend --ignore-not-found=true
kubectl delete service portfolio-service --ignore-not-found=true
kubectl delete ingress portfolio-ingress --ignore-not-found=true
kubectl delete configmap portfolio-config --ignore-not-found=true
echo Cleanup done
echo.

:: Switch Docker env
echo [2/6] Switching Docker env...
FOR /f "tokens=*" %%i IN ('minikube docker-env --shell cmd') DO %%i
echo Docker env switched
echo.

:: Generate unique tag (timestamp-based)
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set datetime=%%a
set IMAGETAG=v%datetime:~0,8%_%datetime:~8,6%

echo Using image tag: %IMAGETAG%
echo.

:: Build new image
echo [3/6] Building Docker image...
docker build --no-cache -t aryankaushal7/portfolio-frontend:%IMAGETAG% -f dockerstuff/Dockerfile .
IF %ERRORLEVEL% NEQ 0 (
    echo Build failed
    pause
    exit /b
)
echo Image built
echo.

:: Create temp deployment
echo [4/6] Updating deployment manifest...
copy kbstuff\deployment.yaml kbstuff\deployment-temp.yaml >nul
powershell -Command "(Get-Content kbstuff\deployment-temp.yaml) -replace 'image: aryankaushal7/portfolio-frontend.*', 'image: aryankaushal7/portfolio-frontend:%IMAGETAG%' -replace 'imagePullPolicy: IfNotPresent', 'imagePullPolicy: Never' | Set-Content kbstuff\deployment-temp.yaml"
echo Deployment updated with tag %IMAGETAG%
echo.

:: Apply resources
echo [5/6] Applying resources...
kubectl apply -f kbstuff\configmap.yml
kubectl apply -f kbstuff\deployment-temp.yaml
kubectl apply -f kbstuff\service.yaml
kubectl apply -f kbstuff\ingress.yaml
echo Resources applied
echo.

:: Wait for rollout
echo [6/6] Waiting for rollout...
kubectl rollout status deployment portfolio-frontend --timeout=60s
IF %ERRORLEVEL% NEQ 0 (
    echo Rollout failed
    kubectl describe pod -l app=portfolio-frontend
    pause
    exit /b
)
echo Rollout successful
echo.

:: Cleanup temp
del kbstuff\deployment-temp.yaml >nul 2>&1

:: Final status
echo ===============================
echo DEPLOYMENT SUCCESSFUL! 
echo ===============================
kubectl get pods -l app=portfolio-frontend
echo.
echo Opening service in browser...
minikube service portfolio-service
pause
