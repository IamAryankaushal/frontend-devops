@echo off
setlocal enabledelayedexpansion

echo [1/6] Building latest Docker image...
docker build -t aryankaushal7/portfolio-frontend:latest .
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
kubectl apply -f k8s\configmap.yaml

echo [4/6] Restarting Kubernetes deployment...
kubectl rollout restart deployment portfolio-frontend

echo [5/6] Applying service and ingress...
kubectl apply -f k8s\service.yaml
kubectl apply -f k8s\ingress.yaml

echo [6/6] Checking deployment status...
kubectl rollout status deployment portfolio-frontend

echo Done! Your latest frontend code is deployed to Minikube.
pause
