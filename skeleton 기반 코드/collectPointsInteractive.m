function [P, P_rc] = collectPointsInteractive(Irgb)
f = figure('Name','Click nodes: Left=add, Right=undo, Enter=finish');
imshow(Irgb, 'Border','tight'); hold on;
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
close(f);
P_rc = [P(:,2) P(:,1)];  % [r c]
end
