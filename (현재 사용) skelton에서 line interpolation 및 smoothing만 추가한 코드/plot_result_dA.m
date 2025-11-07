close all; clear all;

load("results_TTT_0038_3_crop_1\metrics.mat")

if exist('Metrics_raw','var')
    Metrics = Metrics_raw;
end

p_nrm = [
% --- 2행 ---
-1,+1,-1,+1,-1,+1,+1,+1,-1,0,+1,+1,0,0,+1,+1,0,+1,-1,+1,...
-1,+1,+1,-1,+1,+1,-1,+1,-1,-1,0,+1,+1,0,+1,+1,+1,0,+1,+1,...
-1,+1,-1,0,0,+1,0,+1,+1,-1,+1,0,+1,+1,+1,+1,-1,-1,+1,-1,...
0,+1,+1,+1,+1,+1,+1,0,+1,-1,+1,-1,+1,+1,+1,+1,+1,+1,+1,0,...
+1,+1,+1,0,+1,0,0,0,-1,-1,-1];

% 추출한 \delta가 Bernal 방향이 되도록 보정하는 변수
% 즉 overlay image에서 normal vector가 Bernal 방향을 향하는지의 여부이다.
% 향한다면 +1, 그렇지 않다면 -1
% Bilayer에서는 밝은 영역을 향할 때 +1, 검정 영역을 향할 때 -1


dA = Metrics.area_proj_nm2 ./ (Metrics.chord_len_nm.^2);

if ~(length(p_nrm) == size(dA,1))
    error("p_nrm과 dA의 길이가 맞지 않습니다")
end

Metrics.dA_real = dA .* p_nrm';

figure()

hold on
scatter(Metrics.chord_len_nm,Metrics.dA_real)

ylim([-0.5,0.5])

hold off
