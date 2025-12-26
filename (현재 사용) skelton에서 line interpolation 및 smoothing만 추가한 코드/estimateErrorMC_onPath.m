function E = estimateErrorMC_onPath(pathRC, p1_rc, p2_rc, nmPerPx, N, jitter)

if nargin < 5, N = 50; end
if nargin < 6, jitter = 1; end

sag_px   = zeros(N,1);
rmsv_px  = zeros(N,1);
mean_px = zeros(N,1);
lratio   = zeros(N,1);

if ~isempty(nmPerPx)
    sag_nm  = zeros(N,1);
    rmsv_nm = zeros(N,1);
    mean_nm = zeros(N,1);
end

for ii = 1:N

    dp1 = randi([-jitter jitter],1,2);
    dp2 = randi([-jitter jitter],1,2);

    p1p = p1_rc + dp1;
    p2p = p2_rc + dp2;

    M2 = bendingMetrics(pathRC, p1p, p2p, nmPerPx);

    sag_px(ii)   = M2.max_sagitta_px;
    rmsv_px(ii)  = M2.rms_sagitta_px;
    mean_px(ii)  = M2.mean_sagitta_px;
    lratio(ii)   = M2.length_ratio;

    if ~isempty(nmPerPx)
        sag_nm(ii)  = M2.max_sagitta_nm;
        rmsv_nm(ii) = M2.rms_sagitta_nm;
        mean_nm(ii) = M2.mean_sagitta_nm;
    end
end

% === px 기반 ===
E.max_sag_px_std  = std(sag_px);
E.rms_sag_px_std  = std(rmsv_px);
E.mean_sag_px_std  = std(mean_px);
E.lratio_std      = std(lratio);

% === nm 기반 ===
if ~isempty(nmPerPx)
    E.max_sag_nm_std  = std(sag_nm);
    E.rms_sag_nm_std  = std(rmsv_nm);
    E.mean_sag_nm_std  = std(mean_nm);
else
    E.max_sag_nm_std  = [];
    E.rms_sag_nm_std  = [];
    E.mean_sag_nm_std  = [];
end
end
