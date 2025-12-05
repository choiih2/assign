# 🚀 빠른 시작 가이드 (Quickstart Guide)

## 📋 사전 준비사항

### 필수 설치 항목

1. **Kubernetes 클러스터**
   - Minikube (로컬 테스트용)
   - Docker Desktop with Kubernetes
   - 실제 클러스터 (GKE, EKS, AKS 등)

2. **kubectl** (쿠버네티스 CLI 도구)
   ```bash
   # 설치 확인
   kubectl version --client
   ```

3. **Git**
   ```bash
   git --version
   ```

---

## 🎯 단계별 실행 가이드

### Step 1: 저장소 클론

```bash
# 저장소 다운로드
git clone https://github.com/choiih2/assign.git

# 디렉토리 이동
cd assign

# 파일 구조 확인
ls -la
```

**예상 출력:**
```
README.md
QUICKSTART.md
deploy.sh
k8s/
```

---

### Step 2: Kubernetes 클러스터 준비

#### Option A: Minikube 사용 (권장)

```bash
# Minikube 시작
minikube start

# 클러스터 상태 확인
kubectl cluster-info
kubectl get nodes
```

#### Option B: Docker Desktop 사용

1. Docker Desktop 실행
2. Settings → Kubernetes → Enable Kubernetes 체크
3. Apply & Restart

```bash
# 확인
kubectl get nodes
```

---

### Step 3: 배포 스크립트 실행

```bash
# 실행 권한 부여
chmod +x deploy.sh

# 배포 시작
./deploy.sh
```

**배포 과정 (약 2-3분 소요):**
```
=================================
Capston Kubernetes Deployment
=================================

[1/8] Creating Secrets...
[2/8] Creating ConfigMaps...
[3/8] Creating Storage...
[4/8] Deploying Database...
[5/8] Waiting for Database to be ready...
[6/8] Deploying Web Application...
[7/8] Waiting for Web Application to be ready...
[8/8] Starting Fuzzer Job...

Deployment Complete!
=================================
```

---

### Step 4: 배포 확인

#### 4-1. Pod 상태 확인

```bash
kubectl get pods
```

**예상 출력:**
```
NAME                       READY   STATUS      RESTARTS   AGE
mysql-0                    1/1     Running     0          2m30s
web-app-7d4b5c8f9-abc12    1/1     Running     0          1m45s
web-app-7d4b5c8f9-xyz89    1/1     Running     0          1m45s
fuzzer-job-abcde           0/1     Completed   0          1m
```

✅ **중요**: 
- mysql-0: Running 상태
- web-app (2개): Running 상태
- fuzzer-job: Completed 상태

#### 4-2. Pod 간 통신 확인 (Fuzzer 로그)

```bash
kubectl logs job/fuzzer-job
```

**예상 출력:**
```
Starting fuzzer...
Fuzzing web-service at http://web-service
SQLi and XSS vulnerability scanning completed.
Results saved to /app/results/fuzz_report.txt
```

이 로그는 **Fuzzer → Web Service 통신**이 성공했음을 보여줍니다!

#### 4-3. Services 확인

```bash
kubectl get svc
```

**예상 출력:**
```
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
mysql-service   ClusterIP   None            <none>        3306/TCP       3m
web-service     NodePort    10.96.123.45    <none>        80:30080/TCP   2m
```

---

### Step 5: 웹 애플리케이션 접속

#### Minikube 사용 시:

```bash
# URL 확인
minikube service web-service --url
```

출력된 URL로 브라우저에서 접속

#### Docker Desktop 사용 시:

```bash
# localhost로 직접 접속
open http://localhost:30080
```

---

## 🔍 상세 확인 명령어

### MySQL Pod 확인

```bash
# MySQL 로그 확인
kubectl logs mysql-0

# MySQL Pod 내부 접속
kubectl exec -it mysql-0 -- mysql -u root -prootpassword
```

### Web Pod 확인

```bash
# Web Pod 로그 확인 (첫 번째 Pod)
kubectl logs deployment/web-app

# 특정 Pod 로그 확인
kubectl logs <pod-name>
```

### Fuzzer 결과 확인

```bash
# Fuzzer Pod 이름 확인
kubectl get pods -l app=fuzzer

# 결과 파일 다운로드
kubectl cp <fuzzer-pod-name>:/app/results/fuzz_report.txt ./fuzz_report.txt

# 내용 확인
cat fuzz_report.txt
```

---

## 🧹 리소스 정리

### 모든 리소스 삭제

```bash
kubectl delete -f k8s/fuzzer/
kubectl delete -f k8s/web/
kubectl delete -f k8s/database/
kubectl delete -f k8s/storage/
kubectl delete -f k8s/configmaps/
kubectl delete -f k8s/secrets/
```

또는 한 번에:

```bash
kubectl delete all --all
kubectl delete pvc --all
kubectl delete configmap --all
kubectl delete secret --all
```

---

## ❓ 트러블슈팅

### 문제 1: Pod이 Pending 상태

```bash
kubectl describe pod <pod-name>
```

**해결 방법:**
- PVC 문제: 스토리지 클래스 확인
- 리소스 부족: Minikube 메모리 증가
  ```bash
  minikube start --memory=4096 --cpus=2
  ```

### 문제 2: Image Pull 오류

```bash
kubectl describe pod <pod-name>
```

**해결 방법:**
- 인터넷 연결 확인
- 이미지 이름 확인 (php:7.4-apache, mysql:8.0)

### 문제 3: Service 접속 불가

```bash
# Service 상태 확인
kubectl get svc

# Endpoint 확인
kubectl get endpoints web-service
```

---

## 📝 주요 질문 답변

### Q1: 실제 Fuzzer 코드가 없어도 되나요?

**A:** 네, 현재 구조는 **Pod 간 통신 시연**을 목적으로 합니다.
- ✅ Fuzzer → Web → MySQL 통신 흐름
- ✅ Service Discovery (DNS)
- ✅ PVC를 통한 데이터 공유

실제 Fuzzing 기능이 필요하다면 capston 저장소의 코드를 추가해야 합니다.

### Q2: Web PHP 파일이 없어도 되나요?

**A:** 네, web-deployment.yaml은 **php:7.4-apache** 기본 이미지를 사용합니다.
- 실제 취약한 웹 앱이 필요하다면 커스텀 이미지 빌드 필요
- 현재는 Pod 간 네트워크 통신 검증용

---

## 📚 다음 단계

1. **실제 코드 추가**: capston 저장소의 Fuzzer와 Web 코드 통합
2. **커스텀 이미지 빌드**: Docker 이미지 생성 후 DockerHub 업로드
3. **Helm 차트 작성**: 더 쉬운 배포를 위한 Helm 패키징

---

## 🎓 과제 체크리스트

- [x] 3개 이상의 Pod 실행 (MySQL, Web x2, Fuzzer)
- [x] Pod 간 통신 (Service Discovery)
- [x] 데이터 주고받기 (MySQL ↔ Web ↔ Fuzzer)
- [x] 영속성 스토리지 (PVC)
- [x] 배포 자동화 (deploy.sh)
- [x] 상세 문서화 (README + QUICKSTART)

---

## 💡 팁

1. **로그 실시간 모니터링**: 
   ```bash
   kubectl logs -f <pod-name>
   ```

2. **모든 리소스 한 번에 보기**:
   ```bash
   kubectl get all
   ```

3. **특정 Pod 재시작**:
   ```bash
   kubectl delete pod <pod-name>
   # Deployment가 자동으로 재생성
   ```

---

**문제가 발생하면 이슈를 등록해주세요!**
**https://github.com/choiih2/assign/issues**
