
# Bending Analysis & Error Estimation Documentation

---

## 1) 코드에서 데이터를 뽑는 일련의 과정 (원리 중심)

본 알고리즘은 TEM 이미지에서 사용자가 선택한 두 점(node)을 기준으로,  
그 두 점을 잇는 실제 경로(=domain boundary)를 찾아  
경로의 굽힘(bending)을 정량화하는 절차이다.

### 1-1) Skeleton 생성
- 입력: TEM 이미지
- 이미지 전처리(필터링, 이진화 등)를 통해 domain boundary를 강조
- `bwmorph(...,'thin',inf)` 등으로 경계 중심선을 **skeleton** 형태로 추출
- skeleton은 boundary의 1-pixel wide graph-like representation  
→ 이후 path 탐색의 기반이 됨

### 1-2) Node 입력 & Skeleton snap
- 사용자가 마우스로 boundary 상의 관심 지점을 찍음 (ginput)
- 선택된 점은 boundary에 정확히 있지 않을 수 있음  
→ skeleton 상 가장 가까운 pixel 로 **snap**
- snap 결과: `p1_rc`, `p2_rc` (row,col)

### 1-3) Skeleton Graph 구성
- skeleton의 1-픽셀 경로를 Graph로 해석
- 각 skeleton pixel = node  
상하좌우/대각선 연결 = edge
- edge weight = pixel 간 유클리드 거리 (1 또는 √2)
- 따라서 skeleton은 **연결 가능성이 보장된 최소 표현**이 됨

### 1-4) Path 탐색 (Shortest Path)
- snap 노드(p1,p2) 사이의 경로를 skeleton graph에서 최단 경로로 탐색  
→ `shortestpath(G, node1, node2)`
- 도출된 경로가 실제 boundary를 추적한 pixel sequence
- 결과: `pathRC = [row_i, col_i]` (경로상의 pixel 순서)

### 1-5) Arc length & Chord length 계산
- **Chord**: 시작/끝 점을 잇는 직선 거리  

$$
L_c = \|p_2 - p_1\|
$$

- **Arc**: shortest path 누적길이  

$$
L_a = \sum_i \|\Delta \mathbf{r}_i\|
$$

- **Arc/Chord ratio**  

$$
R = \frac{L_a}{L_c}
$$

→ 얼마나 길게 구부러졌는지 표현

### 1-6) Sagitta 계산
- chord 방향을 기준으로 normal vector 계산
- 각 path pixel 에 대해, chord 에서의 **signed offset** 측정  

$$
d_i = (r_i - p_1) \cdot n
$$

- bending metric  
  - **max sagitta**
$$
\max |d_i|
$$
  - **RMS sagitta**
$$
\sqrt{\frac{1}{N}\sum d_i^2}
$$

- sagitta는 px 단위  
→ nm/pixel 스케일 입력 시 nm 단위로 변환 가능

---

## 2) 코드에서 에러를 뽑는 일련의 과정 (원리 중심)

여기서의 “error”는  
**실험(TEM) 오차가 아닌,  
데이터 처리 과정에서 발생하는 알고리즘적 불확실성**  
을 정량화한 값이다.

핵심 아이디어:  
> node selection + snapping 은 ±1 px 정도의 위치 불확실성을 가진다  
> → endpoint 를 px 단위로 흔들면 → bending metric 도 변한다  
> → 이 변동량을 통해 internal processing uncertainty 를 추정한다.

### 2-1) Endpoint jitter Monte‑Carlo
- p1, p2 를 기준점으로 삼고  
±1 px 범위 내에서 랜덤 perturb:
$$
p_1' = p_1 + \delta_1,\quad p_2' = p_2 + \delta_2
$$
($\delta$ ∈ {−1,0,1})

- jitter 변경 → snap 변경 → skeleton path 변경 → bending 변경

### 2-2) Bending 재계산
각 jitter pair 에 대해 bending metric 을 다시 계산:
- max sagitta
- rms sagitta
- arc / chord ratio

이 과정을 N회 반복  
$$
\{ M^{(1)}, M^{(2)}, ..., M^{(N)} \}
$$

### 2-3) 통계 처리 → error 추정
각 metric 값에 대해
- 평균 $\mu$
- 표준편차 $\sigma$

$$
\sigma = \sqrt{\frac{1}{N-1}\sum(M^{(i)} - \mu)^2}
$$

이 표준편차가 **internal processing uncertainty = error bar**

### 반환되는 error
| 항목 | 의미 |
|----|----|
| max_sagitta_std | 최대 굽힘 불확실도 |
| rms_sagitta_std | 평균 굽힘 불확실도 |
| arc/chord_std | 전체 굽힘도 불확실도 |

px / nm 모두 저장 가능  
(nm/px scaling 사용 시 nm std 도 생성)

---

## 3) 코드 요약 (pipeline, workflow, 자료구조 등)

### 📌 Pipeline
```
(1) Load image
(2) Preprocess (filter/threshold)
(3) Skeletonize
(4) Interactive node pick
(5) Snap to skeleton
(6) Build graph
(7) Shortest path along skeleton
(8) Compute bending metrics
(9) Monte‑Carlo jitter → uncertainty
(10) Save table / figures
```

### 📌 Data Structure

| 이름 | 설명 |
|-----|-----|
| I | 입력 이미지 |
| skel | skeleton (logical) map |
| P_rc | user‑picked nodes |
| P_rc_s | snapped nodes |
| G | graph of skeleton pixels |
| pathRC | 최단경로 pixel sequence |
| M | bending metric |
| E | error metric |
| Metrics | 테이블; pair별 summary |

---

## 4) 중요한 파라미터들

| 파라미터 | 역할 | 영향 |
|---|---|---|
| **nmPerPx** | px→nm 변환 | 매우 큼 |
| **pairMode** | pairing 방식 | 중 |
| **maxPairDist** | pair cutoff | 중 |
| **maxArcChord** | 잘못된 경로 필터링 | 중 |
| **maxDegree** | skeleton branch 억제 | 중 |
| **mc_N** | Monte‑Carlo 반복 | error 정밀도 |
| **mc_jitter** | endpoint perturb 범위 | error scale |
| spline_samples | 경로 resample | 낮음 |
| smooth_span | smoothing | 낮음 |

### 가장 중요한 TOP 4
1) nmPerPx  
2) maxArcChord  
3) pairMode/maxPairDist  
4) mc_jitter, mc_N  

---

> ✅ **한 줄 요약**  
Skeleton 기반 shortest‑path 로 실제 boundary 경로를 구하고  
→ sagitta/arc/chord 로 bending 을 계산하며  
→ endpoint jitter Monte‑Carlo 로 내부 알고리즘 불확실도를 추정한다.

