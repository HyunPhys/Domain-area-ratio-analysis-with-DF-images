function pathRC2 = refinePathByNormal(Igray, pathRC, p1_rc, p2_rc, win)
% 각 점에서 chord-normal 방향으로 ±win 픽셀 범위에서 vesselness 최대점으로 스냅
if nargin<5, win = 2; end
Igray = im2double(Igray);
V = vesselness2d(Igray, [1 2]);      % 작은 시그마로 정밀 리스폰스
v = p2_rc - p1_rc; v = v / max(norm(v), eps);
n = [-v(2), v(1)];                   % chord-normal
% Ensure Nx2
if size(pathRC,2) ~= 2
    % Assume pathRC is [r1 c1 r2 c2 ...]
    pathRC = reshape(pathRC, [], 2);
end
pathRC2 = pathRC;
for i=1:size(pathRC,1)
    r0 = pathRC(i,1); c0 = pathRC(i,2);
    rs = r0 + (-win:win)*n(1);
    cs = c0 + (-win:win)*n(2);
    % 선형보간
    vals = interp2(V, cs, rs, 'linear', 0);
    [~, mxi] = max(vals);
    pathRC2(i,:) = round([rs(mxi), cs(mxi)]);
end
end
