#!/bin/bash

# Capston Kubernetes Deployment Script
# This script deploys the web application fuzzing project to Kubernetes

set -e

echo "================================="
echo "Capston Kubernetes Deployment"
echo "================================="
echo ""

echo "[1/8] Creating Secrets..."
kubectl apply -f k8s/secrets/mysql-secret.yaml

echo "[2/8] Creating ConfigMaps..."
kubectl apply -f k8s/configmaps/mysql-init-configmap.yaml

echo "[3/8] Creating Storage..."
kubectl apply -f k8s/storage/mysql-pvc.yaml
kubectl apply -f k8s/storage/fuzzer-pvc.yaml

echo "[4/8] Deploying Database..."
kubectl apply -f k8s/database/mysql-statefulset.yaml
kubectl apply -f k8s/database/mysql-service.yaml

echo "[5/8] Waiting for Database to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql --timeout=120s

echo "[6/8] Deploying Web Application..."
kubectl apply -f k8s/web/web-deployment.yaml
kubectl apply -f k8s/web/web-service.yaml

echo "[7/8] Waiting for Web Application to be ready..."
kubectl wait --for=condition=ready pod -l app=web-app --timeout=120s

echo "[8/8] Starting Fuzzer Job..."
kubectl apply -f k8s/fuzzer/fuzzer-job.yaml

echo ""
echo "================================="
echo "Deployment Complete!"
echo "================================="
echo ""
echo "Check pod status:"
echo "  kubectl get pods"
echo ""
echo "Check fuzzer logs:"
echo "  kubectl logs -f job/fuzzer-job"
echo ""
echo "Access web service:"
echo "  kubectl get svc web-service"
echo "================================="
