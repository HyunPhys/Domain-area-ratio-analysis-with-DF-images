close all; clear all;

saved_dir = "..\results_TTT_0069_2_crop_1_error 계산";


imgPath = '..\..\raw data\TTT_0069_2_crop_1.tif';

to_saveDir = "..\results_TTT_0069_2_crop_1_error 계산\aspect_ratio";

saved_node_point = load(strcat(saved_dir,'\','node_point.mat'));


conversion = 1.7; %Units: nm/pixel <THIS CONVERTS IMAGE COORDINATES TO REAL UNITS


%%

% data_save_root 

Irgb = imread(imgPath);
if size(Irgb,3)==1, Irgb = repmat(Irgb,[1 1 3]); end
Igray = rgb2gray(Irgb);


node_list = saved_node_point.node_point.P;


f = figure('Name','Click nodes: Left=add, Right=undo, Enter=finish');
imshow(Irgb, 'Border','tight'); hold on;

plot(node_list(:,1), node_list(:,2), 'ro','MarkerFaceColor','r','MarkerSize',7); 


%% Polygon 찍기

title('Select lines')


% Hexagon으로 찍을지, moire cell로 찍을지에 대해서, 각각 다른 parameter를 선택
numofnodes = 3; % 여기선 triangle로 찍기

% Parameter들
poly_current = zeros(numofnodes,2);
poly_by_node = zeros(numofnodes,1); % Polygon의 n번째 point가 node_list의 n번째 point로 snap되었는지 알려주는 배열 - min_idx를 저장한다 - 나중에 frame by frame으로 node 위치를 tracking할 때, polygon의 좌표 위치를 갱신할 때 쓰임
poly_idx = 1;

poly_info = table;


% 이 가장 바깥쪽 반복문에서 반복한 횟수가, 바로 polygon의 수가 됨
while true 

    title(['Polygon: ' num2str(poly_idx)]);
    
    % Polygon 찍기: `numofnodes` 만큼 찍음
        
    point_idx = 1;    
    
    % Polygon의 각 point를 찍기: 가장 가까운 node로 snap됨
    for idx1 = 1:numofnodes
        [x,y,button] = ginput(1);   % button: 1=left, 3=right, 13=enter
        if isempty(x) || button==13
            break; % finish
        elseif button==1
            [~, min_idx] = min( (node_list(:,1) - x).^2 + (node_list(:,2) - y).^2); % snap 구현
            poly_current(point_idx,:) = node_list(min_idx,:);
            poly_by_node(point_idx) = min_idx;
            
            if point_idx > 1

                r_start = poly_current(point_idx-1,:);
                r_end =  poly_current(point_idx,:);
                plot([r_start(1) r_end(1)],[r_start(2) r_end(2)],'--r')

            end

            point_idx = point_idx+1;
        end

    end
    
    if isempty(x) || button==13
        break; % finish
    end

    % 내가 선택한 Polygon을 green line으로 plot하기 위한 부분
    plot_poly = poly_current; plot_poly(numofnodes+1,:) = poly_current(1,:);
    for idx = 1:numofnodes
        r_start = plot_poly(idx,:);
        r_end =  plot_poly(idx+1,:);
        plot([r_start(1) r_end(1)],[r_start(2) r_end(2)],'-g')
    end




    poly_info.index{poly_idx} = poly_idx;

    poly_info.poly_list{poly_idx} = poly_current;
    poly_info.poly_list_by_node{poly_idx} = poly_by_node;

    % 총 Polygon 개수 count
    poly_idx = poly_idx+1;


    % reset
    poly_current = zeros(numofnodes,2);
    poly_by_node = zeros(numofnodes,1);
    clear plot_poly r_start r_end point_temp min_idx



end


stop_gui = 0;

clear poly_idx

%% 3. Find histogram at all V


polyTotalNum = 1;
polyTotalNum_Compare = size(poly_info,1);

for p=1:polyTotalNum_Compare

    poly_h = poly_info.poly_list{p};
    p_side = @(i,j) squeeze(poly_h(i,:))-squeeze(poly_h(j,:));
    sides_quad=[norm(p_side(1,2)), norm(p_side(2,3)), norm(p_side(3,1))]; % 가운데 moire length 제외하고서
                     
    poly_info.sides_quad{p} = sides_quad;
    poly_info.moire_length_2nd_peak(p)=mean(sides_quad)*conversion; % 각 frame (row index) 별 polygon 1, 2, ... (column index)의 평균 moire length(변 1,2,3,4 평균냄)
    poly_info.moire_length_std_2nd_peak(p)=std(sides_quad)*conversion; % 표준편차
    poly_info.x_s(p) = max(sides_quad)/min(sides_quad); %I've been using the average of the aspect ratio of the two triangles. 

    xc1 = (poly_h(1,1)+poly_h(2,1))/2; yc1 = (poly_h(1,2)+poly_h(2,2))/2;
    xc2 = (poly_h(2,1)+poly_h(3,1))/2; yc2 = (poly_h(2,2)+poly_h(3,2))/2;
    xc3 = (poly_h(3,1)+poly_h(1,1))/2; yc3 = (poly_h(3,2)+poly_h(1,2))/2;

    xc = mean(poly_h(:,1)); yc = mean(poly_h(:,2));
    
    text_to_plot = sprintf('%d, x_s=%.2f', p, poly_info.x_s(p)); % "n번째 polygon, 그리고 그것의 aspect ratio"
 
    text(xc1, yc1, sprintf('%.2f', sides_quad(1)), ...
     'HorizontalAlignment','center', ...
     'VerticalAlignment','middle','Color','b');
    text(xc2, yc2, sprintf('%.2f', sides_quad(2)), ...
     'HorizontalAlignment','center', ...
     'VerticalAlignment','middle','Color','b');
    text(xc3, yc3, sprintf('%.2f', sides_quad(3)), ...
     'HorizontalAlignment','center', ...
     'VerticalAlignment','middle','Color','b');

    text(xc, yc, text_to_plot, ...
         'HorizontalAlignment','center', ...
         'VerticalAlignment','middle','Color','r');
    
    clear xc yc

end




hold off


%% Save

if ~exist(to_saveDir,'dir'), mkdir(to_saveDir); end

exportgraphics(f, fullfile(to_saveDir,'fig0_overlay.png'), 'Resolution',300);

save(fullfile(to_saveDir,'aspect_ratio.mat'),'poly_info');
writetable(poly_info, fullfile(to_saveDir,'aspect_ratio.csv'));

