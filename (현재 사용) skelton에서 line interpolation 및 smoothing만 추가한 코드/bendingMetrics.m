function M = bendingMetrics(pathRC, p1_rc, p2_rc, nmPerPx)

% 이 함수는 **skeleton 경로(pathRC)**와 **두 기준점(p1_rc,p2_rc)**이 주어졌을 때, 
% “실제 선(경로)”이 “두 점을 잇는 직선(현)”에 비해 얼마나 휘었는지 정량화 지표를 계산해 M에 담아 반환해요. 
% 좌표계는 [r, c] = [row, col] 기준입니다.
if nargin < 4, nmPerPx = []; end
% pathRC: 경로를 이루는 픽셀 좌표들의 배열, 크기 K×2, 각 행이 [r_k, c_k].
% p1_rc, p2_rc: 시작/끝 기준점의 좌표, 1×2, 각각 [r, c].

d = diff(pathRC,1,1);
seg = sqrt(sum(d.^2,2));
s = [0; cumsum(seg)];
arc_len = s(end); 
chord_vec = (p2_rc - p1_rc); 
chord_len = hypot(chord_vec(1), chord_vec(2)); 
t = chord_vec / max(chord_len, eps);
n = [-t(2), t(1)];
rel = pathRC - p1_rc;
signed_dist = rel * n';

% ---- Save basic metrics ----

M.arc_len_px      = arc_len; % 경로(호)의 길이 (px)
M.chord_len_px    = chord_len; % 두 점을 잇는 직선(현) 길이 (px)
M.length_ratio = arc_len / max(chord_len, eps); % arc_len / chord_len (1이면 직선, 클수록 더 굽음)
M.max_sagitta_px  = max(abs(signed_dist)); % 직선에서의 최대 수직 편차 (px)
M.rms_sagitta_px  = sqrt(mean(signed_dist.^2)); % 편차의 RMS (px)
M.s_norm       = s / max(arc_len, eps); % 경로를 0~1로 정규화한 누적 호좌표
M.signed_dist_px  = signed_dist; % 각 경로점의 부호 있는 직선 수직 편차 배열 (px)
M.normal = n;   % 1×2 normal vector
M.tangent = t;  % optional
% ---- 물리 단위로 변환 (nm) ----
if ~isempty(nmPerPx)
    M.arc_len_nm     = M.arc_len_px     * nmPerPx;
    M.chord_len_nm   = M.chord_len_px   * nmPerPx;
    M.max_sagitta_nm = M.max_sagitta_px * nmPerPx;
    M.rms_sagitta_nm = M.rms_sagitta_px * nmPerPx;
    M.signed_dist_nm = M.signed_dist_px * nmPerPx;
end

%% ======================================================
%     Projection Integral  (현-법선 좌표계 적분 ) 
%     A = ∫ |d(x)| dx  ≈ Σ 0.5*( |d_i| + |d_{i+1}| ) * (x_{i+1} - x_i)
%   -----------------------------------------------------
%   x_i = (path_i - p1) · t   : arc point를 chord 방향으로 투영한 좌표
%% ======================================================

% --- chord-direction projection coordinate ---
x_proj = rel * t';               % (Nx1)

% (선택) x_proj 정렬 (정렬 후 대응하는 signed_dist도 같이 정렬)
% [xs, ord] = sort(x_proj(:));
% ys = signed_dist(ord);

xs = x_proj;
ys = signed_dist;

good = isfinite(xs) & isfinite(ys);
xs = xs(good);
ys = ys(good);

if numel(xs) < 2 % 샘플이 2개 미만이면 적분 의미가 없으므로 안전 종료

M.x_proj_px = xs;   % px 단위 projection coordinate
M.area_proj_px2 = 0;


else
% (선택) x 중복 시 평균처리: x가 같은 위치에 점이 여러개 찍히는 경우 방지
[xu, ia, ic] = unique(xs, 'stable');
yu = accumarray(ic, ys, [], @mean);





% --- trapezoidal rule: ∫ |y| dx ---
dx = diff(xu);
A_proj_px2 = sum( 0.5 * (abs(yu(1:end-1)) + abs(yu(2:end))) .* dx );

% Save px^2 result
M.x_proj_px = x_proj;   % px 단위 projection coordinate
M.area_proj_px2 = A_proj_px2;

end



% --- nm^2 변환 ---
if ~isempty(nmPerPx)
    A_proj_nm2 = (nmPerPx^2) * A_proj_px2;
    M.area_proj_nm2 = A_proj_nm2;
    M.x_proj_nm = x_proj * nmPerPx;
end



end