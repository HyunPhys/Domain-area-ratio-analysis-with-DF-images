
# Bending Analysis & Error Estimation Documentation

## ✅ 1) 데이터(bending metric)를 산출하는 전체 과정 (원리 중심)

### 1-1) Skeleton 생성
- TEM 이미지 → filtering & threshold → domain boundary 강조
- Skeletonization으로 1-pixel-width 중심선 추출

### 1-2) Node 입력 & Snap
- 사용자가 node 선택
- skeleton에서 최근접 pixel로 snap → (p1, p2)

### 1-3) Skeleton Graph 구성
- skeleton pixel → 그래프 노드
- 8-neighbor connectivity → edge

### 1-4) Shortest Path
- graph shortest-path로 두 node 연결 → pathRC

### 1-5) Arc & Chord
- Chord = 두 점 직선거리
- Arc = path 길이
- Arc/Chord = bending 정도

### 1-6) Sagitta
- chord normal 방향으로 offset 계산
- max sagitta, RMS sagitta 산출

---

## ✅ 2) 에러(uncertainty) 산출 과정 (원리 중심)

### 2-1) Endpoint jitter Monte-Carlo
- p1, p2를 ±1 px 범위로 랜덤 perturb

### 2-2) Bending 재계산
- jitter된 endpoint들에 대해 bending metric 반복 계산

### 2-3) 통계 처리
- std = internal processing uncertainty
- max_sagitta_std, rms_sagitta_std, arc/chord_std

---

## ✅ 3) 코드 요약 (Pipeline, Workflow, Data Structure)

### 📌 Pipeline
1) Load image
2) Preprocess → Skeleton
3) Node pick → Snap
4) Graph build
5) Shortest path
6) Bending metrics
7) Monte-Carlo jitter → error estimate
8) Save & plot

### 📌 Data 구조
- I: input image
- skel: skeleton map
- P_rc_s: snapped nodes
- G: graph
- pathRC: path pixels
- M: metrics
- E: error
- Metrics: table

---

## ✅ 4) 중요한 파라미터 정리

| 파라미터 | 의미 | 영향 |
|---|---|---|
| nmPerPx | px→nm 스케일 | 매우 큼 |
| pairMode | 노드 연결 방식 | 중 |
| maxPairDist | pair cutoff | 중 |
| maxArcChord | 경로 유효성 판단 | 중 |
| maxDegree | branch 억제 | 중 |
| mc_N | MC 반복 | error 정밀도 |
| mc_jitter | perturb px | error scale |

---
