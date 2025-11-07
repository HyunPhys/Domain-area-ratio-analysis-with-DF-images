function pairs2 = capNodeDegree(pairs, P, maxDeg)
if ~isfinite(maxDeg) || maxDeg<=0, pairs2 = pairs; return; end
deg = accumarray(pairs(:),1,[size(P,1),1]);
pairs2 = [];
for i=1:size(pairs,1)
    a = pairs(i,1); b = pairs(i,2);
    if deg(a)>maxDeg || deg(b)>maxDeg
        % 가까운 간선 우선: 현재 전략에서는 단순 통과(필요하면 거리 기준 정렬 추가)
        continue
    end
    pairs2 = [pairs2; a b]; %#ok<AGROW>
end
if isempty(pairs2), pairs2 = pairs; end  % 너무 많이 잘리면 원본 유지
end
