@echo off
setlocal enabledelayedexpansion

echo [1/6] Building latest Docker image...
docker build -t aryankaushal7/portfolio-frontend:latest -f dockerstuff/Dockerfile .
IF %ERRORLEVEL% NEQ 0 (
    echo Docker build failed. Exiting.
    exit /b
)

echo [2/6] Loading image into Minikube...
minikube image load aryankaushal7/portfolio-frontend:latest
IF %ERRORLEVEL% NEQ 0 (
    echo Minikube image load failed. Exiting.
    exit /b
)

echo [3/6] Applying Kubernetes configmap...
kubectl apply -f kbstuff\configmap.yml
IF %ERRORLEVEL% NEQ 0 (
    echo Configmap apply failed. Exiting.
    exit /b
)

echo [4/6] Applying Kubernetes deployment...
kubectl apply -f kbstuff\deployment.yaml
IF %ERRORLEVEL% NEQ 0 (
    echo Deployment apply failed. Exiting.
    exit /b
)

echo [5/6] Restarting Kubernetes deployment...
kubectl rollout restart deployment portfolio-frontend
IF %ERRORLEVEL% NEQ 0 (
    echo Deployment rollout restart failed. Exiting.
    exit /b
)

echo [6/6] Applying service and ingress...
kubectl apply -f kbstuff\service.yaml
kubectl apply -f kbstuff\ingress.yaml
IF %ERRORLEVEL% NEQ 0 (
    echo Service or ingress apply failed. Exiting.
    exit /b
)

echo [7/6] Checking deployment rollout status...
kubectl rollout status deployment portfolio-frontend

echo Done! Your latest frontend code is deployed to Minikube.
pause
