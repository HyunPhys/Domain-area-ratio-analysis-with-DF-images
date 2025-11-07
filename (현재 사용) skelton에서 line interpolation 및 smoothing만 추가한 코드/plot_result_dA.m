close all; clear all;

load("results\metrics.mat")


p_nrm = [1,1,1,1
    ]; 

% 추출한 \delta가 Bernal 방향이 되도록 보정하는 변수
% 즉 overlay image에서 normal vector가 Bernal 방향을 향하는지의 여부이다.
% 향한다면 +1, 그렇지 않다면 -1


dA = Metrics.area_proj_nm2 ./ (Metrics.chord_len_nm.^2);

if ~(length(p_nrm) == size(dA,1))
    error("p_nrm과 dA의 길이가 맞지 않습니다")
end

Metrics.dA_real = dA .* p_nrm;

figure()

hold on
scatter(Metrics.chord_len_nm,Metrics.dA_real)

ylim([-0.5,0.5])

hold off
