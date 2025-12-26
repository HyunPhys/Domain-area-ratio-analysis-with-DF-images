close all; clear all;

dir = "results_TTW-0049_4_crop_1";

cd(dir)

load("metrics.mat")


% 시편 및 데이터 정보 적기 (같은 시편인 경우 구분 위해)
specimen_info = '230411 TEM_대성이형';
data_info = dir;

p_nrm = zeros(1,10);
p_nrm(1)=1;
p_nrm(4)=-1;
p_nrm(8)=1;


%%
if exist('Metrics_raw','var')
    Metrics = Metrics_raw;
end



% 추출한 \delta가 Bernal 방향이 되도록 보정하는 변수
% 즉 overlay image에서 normal vector가 Bernal 방향을 향하는지의 여부이다.
% 향한다면 +1, 그렇지 않다면 -1
% Bilayer에서는 밝은 영역을 향할 때 +1, 검정 영역을 향할 때 -1


dA =  2.*sqrt(3) .* (Metrics.area_proj_nm2 ./ (Metrics.chord_len_nm.^2));

dx = Metrics.chord_len_nm / length(Metrics.signed_dist_nm);
dA_error = 2.*sqrt(3) .* Metrics.mean_sagitta_nm_std .* dx .* sqrt(length(Metrics.signed_dist_nm)) ./ (Metrics.chord_len_nm.^2);


if ~(length(p_nrm) == size(dA,1))
    error("p_nrm과 dA의 길이가 맞지 않습니다")
end

Metrics.dA_real = dA .* p_nrm';
Metrics.dA_error = dA_error .* p_nrm';
Metrics.p_nrm = p_nrm';

n = height(Metrics);
Metrics.specimen_info = repmat(specimen_info, n, 1);
Metrics.data_info = repmat(data_info, n, 1);

Metrics = movevars(Metrics, 'data_info', 'Before', 1);
Metrics = movevars(Metrics, 'specimen_info', 'Before', 1);

save(fullfile(pwd,'metrics_with_dA.mat'),'Metrics');
writetable(Metrics, fullfile(pwd,'metrics_with_dA.csv')); 


figure()

hold on
errorbar(Metrics.chord_len_nm,Metrics.dA_real,Metrics.dA_error,'LineStyle','none')


ylim([-0.5,0.5])

hold off
