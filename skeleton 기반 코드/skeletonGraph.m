function [G, lin2node, node2lin] = skeletonGraph(skel)

[rr,cc] = find(skel);
lin = sub2ind(size(skel), rr, cc);

lin2node = containers.Map('KeyType','uint32','ValueType','uint32');
for k=1:numel(lin), lin2node(lin(k)) = uint32(k); end
node2lin = uint32(lin);
dirs = [-1 -1; -1 0; -1 1; 0 -1; 0 1; 1 -1; 1 0; 1 1];

rows=[]; cols=[]; w=[];

for k=1:numel(lin) 
    [r,c] = ind2sub(size(skel), lin(k));
    for d=1:8 % 모든 skeleton 픽셀(k)에 대해 8방향으로 이웃 픽셀을 검사:
        r2=r+dirs(d,1); c2=c+dirs(d,2);

        if r2<1||r2>size(skel,1)||c2<1||c2>size(skel,2), continue; end % 영상 바깥이면 skip,

        if ~skel(r2,c2), continue; end % 이웃이 skeleton(1)인지 확인,

        lin2 = sub2ind(size(skel), r2, c2);

        if ~isKey(lin2node, uint32(lin2)), continue; end % 그 이웃 픽셀도 우리가 만든 노드 집합에 있는지 확인(isKey).

        % 조건을 통과하면 간선 추가:
        rows(end+1)=double(lin2node(uint32(lin(k))));
        cols(end+1)=double(lin2node(uint32(lin2)));
        w(end+1)=hypot(double(r2-r),double(c2-c)); % w(end+1) = 가중치 = 유클리드 거리(hypot(dr,dc))
    end
end
G = digraph(rows,cols,w); % 누적해 둔 rows, cols, w로 digraph를 생성.
G = simplify(G,'min');    % 중복 간선 정리
end