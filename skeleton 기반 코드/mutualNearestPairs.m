function pairs = mutualNearestPairs(P)
% P: Nx2 [x y], 상호 최근접 쌍(i<j) 반환
N = size(P,1);
if N<2, pairs = zeros(0,2); return; end

D = squareform(pdist(P));

D(1:N+1:end) = inf; % 대각선이 0인데, 자기 자신이 nearest neighbor가 되는 걸 방지 위해 infinity로 설정


[~, nn] = min(D,[],2);
pairs = [];

for i=1:N
    j = nn(i);
    if nn(j)==i && i<j
        pairs = [pairs; i j]; %#ok<AGROW>
    end
end
end