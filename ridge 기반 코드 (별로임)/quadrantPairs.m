function pairs = quadrantPairs(P, maxDist)
% 각 점 i에 대해 4사분면(NE/NW/SE/SW)에서 가장 가까운 점을 하나씩 후보로 선택
% P: Nx2 [x y], 이미지 좌표(오른쪽 +x, 아래 +y)
% maxDist: 후보 거리 컷오프 (inf 허용)

if nargin < 2 || isempty(maxDist), maxDist = inf; end
N = size(P,1);
pairs = [];

for i = 1:N
    dx = P(:,1) - P(i,1);
    dy = P(:,2) - P(i,2);

    % 자기자신 제외한 서브셋을 만들어 길이 불일치 문제 방지
    keep     = true(N,1); keep(i) = false;
    idx_sub  = (1:N)';    idx_sub = idx_sub(keep);
    dx_sub   = dx(keep);
    dy_sub   = dy(keep);

    % 4사분면 마스크 (이미지 좌표: 위가 -y)
    quad = {@(dx,dy) dx>0 & dy<0,  ... % NE
            @(dx,dy) dx<0 & dy<0,  ... % NW
            @(dx,dy) dx>0 & dy>0,  ... % SE
            @(dx,dy) dx<0 & dy>0};     % SW

    for q = 1:4
        m = quad{q}(dx_sub, dy_sub);       % <- 길이 N-1
        if ~any(m), continue; end
        cand_idx = idx_sub(m);
        d        = hypot(dx_sub(m), dy_sub(m));
        [dmin,k] = min(d);
        if dmin <= maxDist
            j = cand_idx(k);
            pairs = [pairs; sort([i j])];  %#ok<AGROW>
        end
    end
end

if isempty(pairs)
    pairs = zeros(0,2);
else
    pairs = unique(pairs,'rows');
end
end
