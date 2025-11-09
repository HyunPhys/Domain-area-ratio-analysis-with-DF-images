function [P, P_rc] = collectPointsInteractive(Irgb,skel,saveDir)


% 이진화 이미지가 uint8일 수도 있으니 logical 변환
skel = skel > 0;

f = figure('Name','Click nodes: Left=add, Right=undo, Enter=finish');
imshow(Irgb, 'Border','tight'); hold on;



% 빨간색 맵 생성 (mask가 있는 pixel ↔ 빨강, 없는 pixel ↔ 표시 X)
red_layer = cat(3, ones(size(skel)), zeros(size(skel)), zeros(size(skel)));

% overlay
h = imshow(red_layer);

% 검정(0) → 투명, 흰색(1) → alpha 적용
alpha = 0.6;  % 원하는 투명도
set(h, 'AlphaData', skel * alpha);

exportgraphics(f, fullfile(saveDir,'fig0_overlay.png'), 'Resolution',300);


% f = figure('Name','Click nodes: Left=add, Right=undo, Enter=finish');
% 
% imshow(Irgb, 'Border','tight'); hold on;

title('좌클릭: 점 추가 / 우클릭: 되돌리기 / Enter: 종료');
P = []; hPts = []; hTxt = [];
while true
    [x,y,button] = ginput(1);   % button: 1=left, 3=right, 13=enter
    if isempty(x) || button==13
        break; % finish
    elseif button==1
        P = [P; x y];
        % 점/라벨 실시간 표시
        hPts(end+1) = plot(x, y, 'ro','MarkerFaceColor','r','MarkerSize',7); %#ok<AGROW>
        hTxt(end+1) = text(x+6, y, sprintf('%d', size(P,1)), ...
            'Color','y','FontSize',10,'FontWeight','bold'); %#ok<AGROW>
        drawnow;
    elseif button==3
        % undo: 마지막 점 제거
        if ~isempty(P)
            P(end,:) = [];
            delete(hPts(end)); hPts(end) = [];
            delete(hTxt(end)); hTxt(end) = [];
            drawnow;
        end
    end
end
hold off

exportgraphics(f, fullfile(saveDir,'fig0_overlay_with_nodes.png'), 'Resolution',300);


close(f);
P_rc = [P(:,2) P(:,1)];  % [r c]
end
