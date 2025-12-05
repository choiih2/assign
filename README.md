# Capston Kubernetes Deployment

## 프로젝트 개요

이 프로젝트는 웹 애플리케이션 보안 취약점 자동 검사 도구(Fuzzer)를 쿠버네티스 환경에서 실행하는 과제입니다.

## 아키텍처

```
┌─────────────┐      HTTP      ┌──────────────┐      SQL       ┌─────────────┐
│  Fuzzer Job │ ────────────> │  Web Service │ ─────────────> │  DB Service │
└─────────────┘                └──────────────┘                 └─────────────┘
      │                               │                               │
      ▼                               ▼                               ▼
  [결과 저장]                    [Web Pod]                      [MySQL Pod]
  (PVC)                          (Deployment)                   (StatefulSet)
```

## Pod 구성

### 1. MySQL Database Pod
- **역할**: 웹 애플리케이션의 데이터 저장
- **리소스**: StatefulSet, Service (ClusterIP)
- **영속성**: PersistentVolumeClaim 사용

### 2. Web Application Pod
- **역할**: 취약한 웹 애플리케이션 제공
- **리소스**: Deployment (2 replicas), Service (NodePort)
- **통신**: MySQL과 내부 통신

### 3. Fuzzer Job Pod
- **역할**: 웹 애플리케이션 취약점 스캔
- **리소스**: Job (일회성 실행)
- **결과**: PVC에 fuzz_report.txt 저장

## 배포 순서

### 1. Secrets 생성
```bash
kubectl apply -f k8s/secrets/mysql-secret.yaml
```

### 2. ConfigMaps 생성
```bash
kubectl apply -f k8s/configmaps/mysql-init-configmap.yaml
```

### 3. Storage 생성
```bash
kubectl apply -f k8s/storage/mysql-pvc.yaml
kubectl apply -f k8s/storage/fuzzer-pvc.yaml
```

### 4. Database 배포
```bash
kubectl apply -f k8s/database/mysql-statefulset.yaml
kubectl apply -f k8s/database/mysql-service.yaml
```

### 5. Database 준비 대기
```bash
kubectl wait --for=condition=ready pod -l app=mysql --timeout=60s
```

### 6. Web Application 배포
```bash
kubectl apply -f k8s/web/web-deployment.yaml
kubectl apply -f k8s/web/web-service.yaml
```

### 7. Web 준비 대기
```bash
kubectl wait --for=condition=ready pod -l app=web-app --timeout=60s
```

### 8. Fuzzer 실행
```bash
kubectl apply -f k8s/fuzzer/fuzzer-job.yaml
```

## 전체 배포 스크립트

```bash
#!/bin/bash

echo "[1/8] Creating Secrets..."
kubectl apply -f k8s/secrets/

echo "[2/8] Creating ConfigMaps..."
kubectl apply -f k8s/configmaps/

echo "[3/8] Creating Storage..."
kubectl apply -f k8s/storage/

echo "[4/8] Deploying Database..."
kubectl apply -f k8s/database/

echo "[5/8] Waiting for Database..."
kubectl wait --for=condition=ready pod -l app=mysql --timeout=120s

echo "[6/8] Deploying Web Application..."
kubectl apply -f k8s/web/

echo "[7/8] Waiting for Web Application..."
kubectl wait --for=condition=ready pod -l app=web-app --timeout=120s

echo "[8/8] Starting Fuzzer Job..."
kubectl apply -f k8s/fuzzer/

echo "Deployment complete!"
```

## 확인 명령어

### Pod 상태 확인
```bash
kubectl get pods
```

### Fuzzer 로그 확인 (Pod 간 통신 확인)
```bash
kubectl logs -f job/fuzzer-job
```

### Web Pod 로그 확인
```bash
kubectl logs deployment/web-app
```

### 결과 파일 확인
```bash
# Fuzzer Pod 이름 확인
kubectl get pods -l job-name=fuzzer-job

# 결과 파일 복사
kubectl cp <fuzzer-pod-name>:/app/results/fuzz_report.txt ./fuzz_report.txt
```

### Service 확인
```bash
kubectl get svc
```

### 외부 접속 (NodePort)
```bash
# NodePort로 웹 애플리케이션 접속
minikube service web-service --url
# 또는
kubectl get nodes -o wide  # Node IP 확인
# http://<NODE_IP>:30080
```

## 리소스 정리

```bash
# 모든 리소스 삭제
kubectl delete -f k8s/fuzzer/
kubectl delete -f k8s/web/
kubectl delete -f k8s/database/
kubectl delete -f k8s/storage/
kubectl delete -f k8s/configmaps/
kubectl delete -f k8s/secrets/
```

## 과제 시연 포인트

### ✅ 3개 Pod 실행
- mysql-0 (Database)
- web-app-xxx (Web Application, 2 replicas)
- fuzzer-job-xxx (Fuzzer)

### ✅ Pod 간 통신
1. **Fuzzer → Web**: HTTP 요청으로 취약점 스캔
2. **Web → MySQL**: SQL 쿼리 실행
3. **결과 저장**: PVC에 fuzz_report.txt 저장

### ✅ 쿠버네티스 핵심 기능
- **Service Discovery**: DNS 기반 (web-service, mysql-service)
- **Load Balancing**: Web Pod 2개로 부하 분산
- **Storage**: PVC로 영속성 보장
- **Secrets**: 민감 정보 안전 관리
- **Jobs**: 일회성 작업 실행

## 트러블슈팅

### MySQL Pod이 시작되지 않는 경우
```bash
kubectl describe pod mysql-0
kubectl logs mysql-0
```

### Web Pod이 DB에 연결되지 않는 경우
```bash
# Service 확인
kubectl get svc mysql-service

# DNS 확인
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup mysql-service
```

### Fuzzer Job이 실패하는 경우
```bash
kubectl describe job fuzzer-job
kubectl logs job/fuzzer-job
```

## 참고 자료

- 원본 프로젝트: [capston](https://github.com/choiih2/capston)
- Kubernetes 공식 문서: https://kubernetes.io/docs/
