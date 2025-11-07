function pairs2 = validatePairsOnSkeleton(pairs, P_rc, P_rc_s, skel, G, lin2node, node2lin, maxRatio)
pairs2 = [];
for k=1:size(pairs,1)
    i = pairs(k,1); j = pairs(k,2);
    p1_rc = P_rc(i,:); p2_rc = P_rc(j,:);
    p1_s  = P_rc_s(i,:); p2_s = P_rc_s(j,:);

    sNode = lin2node(sub2ind(size(skel), p1_s(1), p1_s(2)));
    tNode = lin2node(sub2ind(size(skel), p2_s(1), p2_s(2)));

    [pathNodes, pathLen] = shortestpath(G, sNode, tNode);
    if isempty(pathNodes), continue; end
    chord = hypot(p2_rc(1)-p1_rc(1), p2_rc(2)-p1_rc(2));
    if chord==0, continue; end
    if pathLen / chord <= maxRatio
        pairs2 = [pairs2; i j]; %#ok<AGROW>
    end
end
pairs2 = unique(pairs2,'rows');
end
