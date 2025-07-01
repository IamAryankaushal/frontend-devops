@echo off
setlocal enabledelayedexpansion

:: Generate a timestamp-based tag like v20250701_1922
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do (
    set TODAY=%%c%%a%%b
)
for /f "tokens=1-2 delims=: " %%a in ('time /t') do (
    set NOW=%%a%%b
)
set IMAGETAG=v%TODAY%_%NOW%
set FULL_IMAGE=aryankaushal7/portfolio-frontend:%IMAGETAG%

echo ===============================
echo Cleaning up old Kubernetes objects...
kubectl delete deployment portfolio-frontend --ignore-not-found
kubectl delete service portfolio-service --ignore-not-found
kubectl delete configmap portfolio-config --ignore-not-found
kubectl delete ingress portfolio-ingress --ignore-not-found

echo.
echo [1/7] Building Docker image with tag: %IMAGETAG%
docker build --no-cache -t %FULL_IMAGE% -f dockerstuff/Dockerfile .
IF %ERRORLEVEL% NEQ 0 (
    echo Docker build failed. Exiting.
    pause
    exit /b
)

echo.
echo [2/7] Loading image into Minikube...
minikube image load %FULL_IMAGE%
IF %ERRORLEVEL% NEQ 0 (
    echo Minikube image load failed. Exiting.
    pause
    exit /b
)

echo.
echo [3/7] Applying Kubernetes configmap...
kubectl apply -f kbstuff\configmap.yml

echo.
echo [4/7] Applying Kubernetes deployment...
kubectl apply -f kbstuff\deployment.yaml

echo.
echo [5/7] Setting new image in deployment...
kubectl set image deployment/portfolio-frontend portfolio-frontend=%FULL_IMAGE%

echo.
echo [6/7] Applying service and ingress...
kubectl apply -f kbstuff\service.yaml
kubectl apply -f kbstuff\ingress.yaml

echo.
echo [7/7] Restarting deployment and waiting...
kubectl rollout restart deployment portfolio-frontend
kubectl rollout status deployment portfolio-frontend

echo.
echo Deployment complete with image: %FULL_IMAGE%
echo Now run: minikube service portfolio-service
pause
