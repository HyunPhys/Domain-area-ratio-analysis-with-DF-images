function pathRC = findPathRidge(Igray, p1_rc, p2_rc, opts)
% Igray: double[0..1]
% p1_rc,p2_rc: [row col]
% opts.sigmas (e.g. [1 2 3]), opts.corridor_px (e.g. 12)

if ~isfield(opts,'sigmas'),      opts.sigmas = [1 2 3]; end
if ~isfield(opts,'corridor_px'), opts.corridor_px = 12; end


Igray_double = im2double(Igray);
[h,w] = size(Igray_double);

% ---- (1) 좌표 정수화 + boundary clamp ----
p1_rc = round(p1_rc);
p2_rc = round(p2_rc);
p1_rc(1) = min(max(p1_rc(1),1), h);
p1_rc(2) = min(max(p1_rc(2),1), w);
p2_rc(1) = min(max(p2_rc(1),1), h);
p2_rc(2) = min(max(p2_rc(2),1), w);


% 1) vesselness & cost
V  = vesselness2d(Igray, opts.sigmas);
C  = 1 - V;                            % 비용(선 위가 작음)
C  = imnormalize(C);                   % 0~1

% 2) chord 주변 좁은 띠(corridor) 마스크
mask = corridorMask(size(Igray), p1_rc, p2_rc, opts.corridor_px);
C(~mask) = 1e3;                        % 바깥은 아주 큰 비용으로 봉인

% 3) 8-이웃 그래프 edge 비용 구성
[pathRC] = shortestPathOnCost(C, p1_rc, p2_rc);
end

function M = imnormalize(M), M = (M - min(M(:))) / max(eps, (max(M(:))-min(M(:)))); end

function mask = corridorMask(sz, p1, p2, w)
% 거리< w 인 점들만 True
[rr,cc] = ndgrid(1:sz(1), 1:sz(2));
v = p2 - p1; v = v / max(norm(v), eps);
a = ( (rr - p1(1))*v(1) + (cc - p1(2))*v(2) );
a = min(max(a,0), norm(p2-p1));   % segment 범위 클램프
% 최근접점:  (row, col) 좌표 각각 따로 계산
proj_r = p1(1) + a * v(1);
proj_c = p1(2) + a * v(2);

% 거리
dist = hypot(rr - proj_r, cc - proj_c);
mask = dist <= w;
end

function pathRC = shortestPathOnCost(C, s_rc, t_rc)
% grid graph 최단경로(Dijkstra)
sz = size(C);
% 노드 인덱스
lin = @(r,c) sub2ind(sz, r, c);

% 초기화
start = lin(s_rc(1), s_rc(2));
goal  = lin(t_rc(1), t_rc(2));
dist  = inf(sz); dist(start) = 0;
prev  = zeros(sz,'uint32');

% 8-이웃
nbr = [-1 -1; -1 0; -1 1; 0 -1; 0 1; 1 -1; 1 0; 1 1];
w    = [sqrt(2) 1 sqrt(2) 1 1 sqrt(2) 1 sqrt(2)];

% 간단 Dijkstra (min-heap 없이 구현: corridor가 좁으면 충분히 빠름)
visited = false(sz);
while true
    % 미방문 중 최소 dist
    [~, idx] = min(dist(:) + (visited(:))*1e12);
    if isinf(dist(idx)) || idx == goal, break; end
    visited(idx) = true;
    [r,c] = ind2sub(sz, idx);

    for k=1:8
        rr = r + nbr(k,1); cc = c + nbr(k,2);
        if rr<1 || cc<1 || rr>sz(1) || cc>sz(2), continue; end
        if visited(rr,cc), continue; end

        % edge 비용 = 평균 cost × 기하학 길이
        ecost = ((C(r,c) + C(rr,cc))/2) * w(k);
        nd = dist(r,c) + ecost;
        if nd < dist(rr,cc)
            dist(rr,cc) = nd;
            prev(rr,cc) = idx;
        end
    end
end

% backtrack
if isinf(dist(goal))
    pathRC = [s_rc; t_rc]; % fallback
    return;
end
P = uint32(goal);
while P(end) ~= start
    P(end+1) = prev(P(end)); %#ok<AGROW>
end
P = flip(P);

[rp, cp] = ind2sub(sz, double(P));
pathRC = [rp, cp];
end
