@echo off
echo === Starting Portfolio Deployment ===

:: Step 1: Point Docker CLI to Minikube's Docker daemon
echo Setting Docker environment to Minikube...
for /f "tokens=*" %%i in ('minikube docker-env --shell cmd') do %%i

:: Step 2: Build a fresh Docker image inside Minikube
echo Building Docker image for Portfolio...
docker build --no-cache -t portfolio-frontend:latest -f dockerstuff/Dockerfile .

:: Step 3: Apply Kubernetes manifests
echo Applying Kubernetes Configurations...

kubectl apply -f kbstuff/configmap.yml
kubectl apply -f kbstuff/service.yaml
kubectl apply -f kbstuff/deployment.yaml
kubectl apply -f kbstuff/ingress.yaml

:: Step 4: Restart pods so they use the new image
echo Restarting portfolio pods...
kubectl delete pods -l app=portfolio-frontend

:: Step 5: Confirm rollout status
echo Waiting for rollout to complete...
kubectl rollout status deployment/portfolio-frontend

:: Step 6: Launch browser
echo Opening website in your browser...
start http://portfolio.local

echo === Deployment Finished! ===
pause
