function pairs = knnPairs(P, K, maxDist)
N = size(P,1);
pairs = [];
Mdl = KDTreeSearcher(P);
for i=1:N
    [idx,dist] = knnsearch(Mdl, P(i,:), 'K', K+1);
    idx = idx(2:end); dist = dist(2:end);
    keep = dist <= maxDist;
    idx = idx(keep);
    for j=idx(:)'
        if i<j, pairs = [pairs; i j]; end %#ok<AGROW>
    end
end
pairs = unique(pairs,'rows');
end
