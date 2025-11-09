function line_bending_interactive(imgPath, mode, opts, opts_skel)
% line_bending_interactive  –  Click many nodes; quantify bending for each pair.
% USAGE:
%   line_bending_interactive('your_image.png');              % default: 'mutual'
%   line_bending_interactive('your_image.png','sequential'); % 1-2,2-3,3-4,...
%
% OUTPUTS (saved in results/):
%   overlay_###.png, profile_###.png, metrics.csv/mat

% -------- Default 값 넣는 코드-----------
if nargin < 2 || isempty(mode), mode = 'mutual'; end

if nargin < 3, opts = struct; end

t_now  = datetime("now","Format","yyyyMMdd_HHmmss");
saveDir_name = "results_" + string(t_now);



opts = setDefault(opts,'gaussSigma',1.0);
opts = setDefault(opts,'nmPerPx', []);   % ← 한 픽셀당 나노미터 (예: 0.52)
opts = setDefault(opts,'minObject',64);
opts = setDefault(opts,'saveDir',saveDir_name);
opts = setDefault(opts,'pairMode','quadrant');   % 'quadrant' | 'knn'
opts = setDefault(opts,'knnK',6);                % pairMode='knn'일 때 후보 K
opts = setDefault(opts,'maxPairDist',inf);       % 후보 거리 컷오프 (필요시 거리 제한(px))
opts = setDefault(opts,'maxArcChord',1.20);      % skeleton 경로의 arc/chord 허용 상한
opts = setDefault(opts,'maxDegree',4);           % 한 점에서 허용할 최대 연결 수
opts = setDefault(opts,'mc_N', 50);       % Monte-Carlo 반복 횟수 (기본 50)
opts = setDefault(opts,'mc_jitter', 1);   % px perturbation size (±1)
opts = setDefault(opts,'sortChordAxis', false); % F3에서 x축을 정렬할지 말지 (정렬 안 하는 게 낫다고 생각함)


% line_bending_interactive() 맨 위쪽
if nargin>=2 && ischar(mode) && ~isempty(mode)
    if strcmpi(mode,'mutual'), opts.pairMode = 'quadrant'; end
    if strcmpi(mode,'sequential'), ; % 그대로 sequential 분기 사용
    end
end


Irgb = imread(imgPath);
if size(Irgb,3)==1, Irgb = repmat(Irgb,[1 1 3]); end
Igray = rgb2gray(Irgb);

% --- 0) Skeleton 준비 ---
% skel = makeSkeleton(Igray, opts.gaussSigma, opts.minObject);

% opts_skel = struct( ...
%   'method','gabor', ...
%   'gaussSigma', 1.5, ...       % 노이즈 더 누르고
%   'gaborWavelengths', [2 3 4],... % 가는 선 대응
%   'gaborTheta', 0:10:170, ...
%   'adaptWin', 71, ...
%   'adaptSens', 0.40, ...       % 보수적으로 ON (놓치지 않도록)
%   'morphOpen', 1, ...
%   'morphClose', 2, ...
%   'minObject', 60, ...
%   'spurPrune', 6);

% opts_skel = struct( ...
%   'method','gabor', ...
%   'gaussSigma', 1.0, ...
%   'gaborWavelengths', [3 4 5], ...
%   'gaborTheta', 0:15:165, ...
%   'adaptWin', 51, ...
%   'adaptSens', 0.48, ...       % (0.45→0.48) 조금 더 공격적으로 ON
%   'morphOpen', 2, ...          % 열기 강화(잡영 제거)
%   'morphClose', 1, ...
%   'minObject', 120, ...        % 작은 조각 과감히 제거
%   'spurPrune', 10);            % 짧은 가시 적극 제거

% opts_skel = struct( ...
%   'method','gabor', ...
%   'gaussSigma', 1.2, ...       % (1.0→1.2) 약간 더 블러
%   'gaborWavelengths', [4 6 8],... % 선 폭이 조금 굵다 가정
%   'gaborTheta', 0:10:170, ...  % 방향 분해능↑ (15→10도 간격)
%   'adaptWin', 61, ...          % 로컬 윈도우 조금 키움
%   'adaptSens', 0.42, ...       % (0.45→0.42) 이진화 더 보수적
%   'morphOpen', 1, ...          % 열기 약화(연결 유지)
%   'morphClose', 2, ...         % 닫기 강화(틈 메우기)
%   'minObject', 700, ...
%   'spurPrune', 6);             % 너무 과하게 가지치지 않음



%skel = makeSkeletonRobust(Igray, opts_skel);
[BW_raw,BW_morph,skel,opts_skel_used] = makeSkeletonRobust(Igray,opts_skel);

fig_BW_raw = figure('Name','After binarize');
imshow(BW_raw)

fig_BW_morph = figure('Name','After morphology trimming');
imshow(BW_morph)


% (요구사항 1) skeleton 결과 한 번 표시
figPrev = figure('Name','Skeleton preview');
tiledlayout(figPrev,1,2,"Padding","compact","TileSpacing","compact");
nexttile; imshow(Irgb, 'Border','tight'); title('Original');
nexttile; imshow(skel, []); title('Skeleton (press any key to continue)');
set(figPrev,'Color','w'); drawnow;

if ~exist(opts.saveDir,'dir'), mkdir(opts.saveDir); end


exportgraphics(fig_BW_raw, fullfile(opts.saveDir,'fig0_binary.png'), 'Resolution',600);
exportgraphics(fig_BW_morph, fullfile(opts.saveDir,'fig0_morphology.png'), 'Resolution',600);
exportgraphics(figPrev, fullfile(opts.saveDir,'fig0_skeleton_with_spurPrune.png'), 'Resolution',600);


waitforbuttonpress; close(fig_BW_raw);close(fig_BW_morph); close(figPrev);



% --- 1) 인터랙티브 클릭 ---
% figure('Name','Click node points (Enter to finish)'); imshow(Irgb, 'Border','tight');
% title('원하는 만큼 점을 찍고 Enter');
% [x,y] = ginput(); close;       % x,y라는 벡터가 2개 나옴 (cols,rows)
% if numel(x) < 2, error('최소 2개 점이 필요합니다.'); end
% P      = [x y];                 % Nx2, [x y] 두 벡터 합쳐서 하나의 행렬로. 현재는 column, row임
% P_rc   = [P(:,2) P(:,1)];       % [r c] 근데 보통 row column을 쓰므로 그렇게 바꿈

[P, P_rc] = collectPointsInteractive(Irgb,skel,opts.saveDir);   % P=[x y], P_rc=[r c]


if size(P,1) < 2, error('최소 2개 점이 필요합니다.'); end


% Skeleton 픽셀로 스냅
[rr,cc] = find(skel); 
SkelRC = [rr cc];

KDT     = KDTreeSearcher(double(SkelRC));
idx     = knnsearch(KDT,double(P_rc));
P_rc_s  = SkelRC(idx,:);

% --- 2) 쌍 구성 ---
% switch lower(mode)
%     case 'mutual'
%         pairs = mutualNearestPairs(P); % Mutual nearest neighbor만 뽑아 pair 형성 (인덱스 i<j)
%     case 'sequential'
%         n = size(P,1); pairs = [(1:n-1)' (2:n)']; % 클릭 순서대로 pair 형성
%     otherwise
%         error('mode must be "mutual" or "sequential".');
% end

switch lower(opts.pairMode)
    case 'quadrant'
        % 각 점마다 4사분면(NE/NW/SE/SW)에서 가장 가까운 점을 후보로 선정
        pairs = quadrantPairs(P, opts.maxPairDist);
    case 'knn'
        % 각 점에서 K-NN 후보를 뽑아 검사
        pairs = knnPairs(P, opts.knnK, opts.maxPairDist);
    otherwise
        error('Unknown pairMode: %s', opts.pairMode);
end




if ~isinf(opts.maxPairDist) % 너무 멀리 떨어진 점들 제외
    d = vecnorm(P(pairs(:,1),:) - P(pairs(:,2),:), 2, 2);
    pairs = pairs(d <= opts.maxPairDist, :);
end

if isempty(pairs), error('형성된 쌍이 없습니다.'); end



% --- 3) Skeleton 그래프 및 경로 탐색 준비 ---
[G, lin2node, node2lin] = skeletonGraph(skel);

% skeleton 연결성 검증 + arc/chord 필터링
pairs = validatePairsOnSkeleton(pairs, P_rc, P_rc_s, skel, G, lin2node, node2lin, opts.maxArcChord);

% 한 점의 연결 수 제한(선택)
if isfinite(opts.maxDegree)
    pairs = capNodeDegree(pairs, P, opts.maxDegree);
end



% --- 4) 각 쌍 처리 ---
Trows = {};
Trows_raw = {};

% === BEFORE pair loop ===
all_paths = {};
all_p1 = [];
all_p2 = [];
all_norms = [];     % 1×2 per pair
valid_pair_ids = [];


for k=1:size(pairs,1)
    i = pairs(k,1); j = pairs(k,2);
    p1_rc = P_rc(i,:); p2_rc = P_rc(j,:);
    p1_s  = P_rc_s(i,:); p2_s = P_rc_s(j,:);

    sNode = lin2node(sub2ind(size(skel),p1_s(1),p1_s(2)));
    tNode = lin2node(sub2ind(size(skel),p2_s(1),p2_s(2)));
    pathNodes = shortestpath(G, sNode, tNode);
    linIdx    = node2lin(pathNodes);
    [rpath,cpath] = ind2sub(size(skel), linIdx);
    pathRC = [rpath cpath];

    pathRC_raw = pathRC;


    % pathRC: Nx2 [r c]
    d = hypot(diff(pathRC(:,1)), diff(pathRC(:,2)));
    s = [0; cumsum(d)];


    % 등간격(예: 1 px 간격)으로 재샘플
    ds = 1;  ss = (0:ds:s(end))';
    r_s = interp1(s, pathRC(:,1), ss, 'pchip');
    c_s = interp1(s, pathRC(:,2), ss, 'pchip');
    % Savitzky–Golay로 살짝 평활화 (창 9~11, 차수 2~3 권장)
    r_s = sgolayfilt(r_s, 3, 9);
    c_s = sgolayfilt(c_s, 3, 9);
    pathRC = [r_s c_s];   % 이걸로 bendingMetrics 실행


    M = bendingMetrics(pathRC, p1_rc, p2_rc,opts.nmPerPx);
    if numel(M.signed_dist_px) < 2, continue; end   % 샘플 부족 시 건너뜀

    M_raw = bendingMetrics(pathRC_raw, p1_rc, p2_rc,opts.nmPerPx);
    if numel(M_raw.signed_dist_px) < 2, continue; end   % 샘플 부족 시 건너뜀


    % ---- Monte-Carlo error estimation ----
    E = estimateErrorMC_onPath(pathRC, p1_rc, p2_rc, opts.nmPerPx, opts.mc_N, opts.mc_jitter);
    E_raw = estimateErrorMC_onPath(pathRC_raw, p1_rc, p2_rc, opts.nmPerPx, opts.mc_N, opts.mc_jitter);
    
    M.max_sagitta_px_std = E.max_sag_px_std;
    M.rms_sagitta_px_std = E.rms_sag_px_std;
    M.length_ratio_std   = E.lratio_std;
    M_raw.max_sagitta_px_std = E_raw.max_sag_px_std;
    M_raw.rms_sagitta_px_std = E_raw.rms_sag_px_std;
    M_raw.length_ratio_std   = E_raw.lratio_std;

    if ~isempty(opts.nmPerPx)
        M.max_sagitta_nm_std = E.max_sag_nm_std;
        M.rms_sagitta_nm_std = E.rms_sag_nm_std;
        M_raw.max_sagitta_nm_std = E_raw.max_sag_nm_std;
        M_raw.rms_sagitta_nm_std = E_raw.rms_sag_nm_std;
    end


    % ... pathRC, p1_rc, p2_rc, M 등이 정상 계산된 직후에:
    all_paths{end+1} = pathRC;        % [row col]
    all_p1           = [all_p1; p1_rc];   % 1x2
    all_p2           = [all_p2; p2_rc];   % 1x2
    all_norms = [all_norms; M.normal]; %  <<=== 추가
    valid_pair_ids   = [valid_pair_ids; k];  % 현재 pair id






    % Overlay: 원본 + 기준 직선 + 탐색 경로 + 클릭점
    f1 = figure('Visible','off'); imshow(Irgb); hold on;
    plot([p1_rc(2) p2_rc(2)], [p1_rc(1) p2_rc(1)], 'w--','LineWidth',0.8);
    plot(pathRC(:,2), pathRC(:,1), 'c-','LineWidth',0.8);
    plot(P(:,1), P(:,2), 'r.','MarkerSize',18);

    % path 중간점
    mid_idx = round(size(pathRC,1)/2);
    mid_pt  = pathRC(mid_idx,:);      % [row col]
    p       = [mid_pt(2), mid_pt(1)]; % (x,y)
    
    % normal from bendingMetrics
    n = M.normal;     % <== 여기!
    
    scale = 15;
    pn = p + scale * [n(2) n(1)];
    
    quiver(p(1), p(2), pn(1)-p(1), pn(2)-p(2), ...
           0, 'Color','r','LineWidth',2,'MaxHeadSize',2);

    if ~isempty(opts.nmPerPx)
        ttl = sprintf('Pair %d: arc/chord=%.4f  max=%.2f nm  RMS=%.2f nm', ...
            k, M.length_ratio, M.max_sagitta_nm, M.rms_sagitta_nm);
    else
        ttl = sprintf('Pair %d: arc/chord=%.4f  max=%.2f px  RMS=%.2f px', ...
            k, M.length_ratio, M.max_sagitta_px, M.rms_sagitta_px);
    end
    title(ttl);

    exportgraphics(f1, fullfile(opts.saveDir,sprintf('overlay_%03d.png',k)), 'Resolution',300);
    close(f1);

    % Profile: 휨 프로파일 그림: s/L 대 signed deviation (axis: normalized arc-axis)
    f2 = figure('Visible','off');
    
    if ~isempty(opts.nmPerPx)
        y = M.signed_dist_px * opts.nmPerPx;   % nm
        plot(M.s_norm, y, 'LineWidth',1.4); grid on;
        if ~isempty(opts.nmPerPx)
            err = M.rms_sagitta_nm_std * ones(size(y));
        else
            err = M.rms_sagitta_px_std * ones(size(y));
        end
        errorbar(M.s_norm, y, err,'LineWidth',1.2);
        errorbar(M.s_norm, y, err, 'LineWidth',1.2);
        xlabel('Normalized arc length (s / L)');
        ylabel('Signed deviation (nm)');
    else
        plot(M.s_norm, M.signed_dist_px, 'LineWidth',1.4); grid on;
        xlabel('Normalized arc length (s / L)');
        ylabel('Signed deviation (px)');
    end


    title(sprintf('Bending profile – Pair %d',k));
    exportgraphics(f2, fullfile(opts.saveDir,sprintf('fig2 profile_%03d.png',k)), 'Resolution',300);
    close(f2);


    % ======== f3: chord-axis bending profile ========
    
    % (1) 기본 벡터
    if ~isempty(opts.nmPerPx)
        x = M.x_proj_nm;      % nm
        y = M.signed_dist_nm; % nm
        xunit = 'nm';
    else
        x = M.x_proj_px;      % px
        y = M.signed_dist_px; % px
        xunit = 'px';
    end


    % (2) 정렬 옵션
    % opts.sortChordAxis = true/false
    if isfield(opts, 'sortChordAxis') && opts.sortChordAxis
        [x_sorted, ord] = sort(x(:));
        y_sorted = y(ord);
    else
        x_sorted = x(:);
        y_sorted = y(:);
    end
    
    % (3) Figure 생성
    f3 = figure('Visible','off');
    plot(x_sorted, y_sorted, 'LineWidth', 1.4);
    grid on;
    xlabel(sprintf('Chord direction (%s)', xunit));
    ylabel(sprintf('Normal offset (%s)', xunit));
    title(sprintf('Chord-axis bending profile (pair %d)', k));
    
    % (4) 저장

    exportgraphics(f3, fullfile(opts.saveDir,sprintf('pair_%03d_f3_chord_axis.png',k)), 'Resolution',300);
    close(f3);


    vars = {'pair_id','idx1','idx2', ...
            'arc_len_px','chord_len_px','arc_over_chord','signed_dist_px','max_sagitta_px','rms_sagitta_px','max_sagitta_px_std','rms_sagitta_px_std','area_proj_px2'};
    row = {k,i,j, M.arc_len_px, M.chord_len_px, M.length_ratio, M.signed_dist_px, M.max_sagitta_px, M.rms_sagitta_px,M.max_sagitta_px_std, M.rms_sagitta_px_std, M.area_proj_px2};
    row_raw = {k,i,j, M_raw.arc_len_px, M_raw.chord_len_px, M_raw.length_ratio, M_raw.signed_dist_px, M_raw.max_sagitta_px, M_raw.rms_sagitta_px,M_raw.max_sagitta_px_std, M_raw.rms_sagitta_px_std, M_raw.area_proj_px2};


    if ~isempty(opts.nmPerPx)
        vars = [vars, {'arc_len_nm','chord_len_nm','signed_dist_nm','max_sagitta_nm','rms_sagitta_nm','max_sagitta_nm_std','rms_sagitta_nm_std','area_proj_nm2'}];
        row  = [row,  {M.arc_len_nm, M.chord_len_nm, M.signed_dist_nm,M.max_sagitta_nm, M.rms_sagitta_nm,  M.max_sagitta_nm_std, M.rms_sagitta_nm_std,M.area_proj_nm2}];
        row_raw  = [row_raw,  {M_raw.arc_len_nm, M_raw.chord_len_nm, M_raw.signed_dist_nm,M_raw.max_sagitta_nm, M_raw.rms_sagitta_nm,  M_raw.max_sagitta_nm_std, M_raw.rms_sagitta_nm_std,M_raw.area_proj_nm2}];

    end
    Trows = [Trows; row];
    Trows_raw = [Trows_raw; row_raw];

end



if ~isempty(valid_pair_ids)
    f4 = figure('Visible','off');
    imshow(Irgb,[]); hold on;

    C = lines(max(7, numel(valid_pair_ids)));

    for m = 1:numel(valid_pair_ids)
        pid    = valid_pair_ids(m);
        pathRC = all_paths{m};
        p1_rc  = all_p1(m,:);
        p2_rc  = all_p2(m,:);
        cc     = C(m,:);
        n = all_norms(m,:);

        % arc path
        plot(pathRC(:,2), pathRC(:,1), '-', 'Color', cc, 'LineWidth', 0.8);

        % chord
        plot([p1_rc(2), p2_rc(2)], [p1_rc(1), p2_rc(1)], '--', ...
             'Color', cc*0.6, 'LineWidth', 0.8);

        % midpoint 
        mid_idx = round(size(pathRC,1)/2);
        mid_xy  = [pathRC(mid_idx,2), pathRC(mid_idx,1)];

        % Pair Number Label
        text(mid_xy(1), mid_xy(2), sprintf('%d', pid), ...
             'Color', 'w','FontWeight','bold','FontSize',11, ...
             'HorizontalAlignment','center','VerticalAlignment','middle', ...
             'BackgroundColor',[0 0 0 0.35]);
        % ----- Normal Vector -----

        % normal from bendingMetrics
        scale = 12;   % arrow length
        p  = mid_xy;
        pn = p + scale * [n(2), n(1)];  % NOTE: (r,c)->(x,y) swap

        quiver(p(1), p(2), pn(1)-p(1), pn(2)-p(2), ...
               0, 'Color', cc, 'LineWidth',1.8, 'MaxHeadSize',1.5);
    end

    title(sprintf("All Pairs Overlay (N = %d)", numel(valid_pair_ids)));
    hold off;

    exportgraphics(f4, fullfile(opts.saveDir,'fig4_all_pairs_overlay.png'), 'Resolution',300);
    close(f4);
    
else
    warning("Fig4 skipped: no valid pairs.");
end

Metrics = cell2table(Trows, 'VariableNames', vars);
save(fullfile(opts.saveDir,'metrics.mat'),'Metrics');
writetable(Metrics, fullfile(opts.saveDir,'metrics.csv'));

Metrics_raw = cell2table(Trows_raw, 'VariableNames', vars);
save(fullfile(opts.saveDir,'metrics_raw.mat'),'Metrics_raw');
writetable(Metrics, fullfile(opts.saveDir,'metrics_raw.csv'));

save(fullfile(opts.saveDir,'parameters_opts.mat'),'opts')
save(fullfile(opts.saveDir,'parameters_opts_skel.mat'),'opts_skel_used')


node_point = struct();
node_point.P = P;
node_point.P_rc = P_rc;
node_point.P_rc_s = P_rc_s;
node_point.pairs = pairs;
node_point.skel = skel;

save(fullfile(opts.saveDir,'node_point.mat'),'node_point')




disp(Metrics);
fprintf('완료! 결과는 "%s"에 저장되었습니다.\n', opts.saveDir);

end % ===== main =====

% --------------------- Helpers -------------------------------------------
