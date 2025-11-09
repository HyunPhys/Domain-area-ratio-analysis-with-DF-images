function [BW_raw,BW_morph,skel,opts] = makeSkeletonRobust(Igray, opts)
% Robust line-enhancement + skeletonization
% opts fields (모두 선택 사항, 괄호는 기본값):
%   .invert (true)       : 어두운 선을 밝게 보이도록 반전
%   .claheClip (0.01)    : adapthisteq clipLimit
%   .gaussSigma (1.0)    : 노이즈 완화용 Gaussian sigma
%   .method ('adaptive') : 'adaptive' | 'canny' | 'gabor'
%   .adaptWin (51)       : adaptthresh 윈도우 (홀수 권장)
%   .adaptSens (0.45)    : adaptthresh 민감도 (0~1, 클수록 더 많은 픽셀 ON)
%   .cannyThresh ([0.06 0.18]) : edge Canny 임계 (정규화)
%   .gaborWavelengths ([3 4 5]) : 가보 파장 (px)
%   .gaborTheta (0:15:165)      : 가보 방향(도)
%   .morphOpen (2)       : 개방(열기) 반경(0이면 건너뜀)
%   .morphClose (1)      : 폐쇄(닫기) 반경(0이면 건너뜀)
%   .minObject (80)      : 작은 객체 제거 크기
%   .spurPrune (8)       : skeleton 가지치기 반복 횟수

% -------- Defaults --------
if ~isfield(opts,'invert'),       opts.invert = true; end
if ~isfield(opts,'claheClip'),    opts.claheClip = 0.01; end
if ~isfield(opts,'gaussSigma'),   opts.gaussSigma = 1.5; end
if ~isfield(opts,'method'),       opts.method = 'adaptive'; end
if ~isfield(opts,'adaptWin'),     opts.adaptWin = 51; end
if ~isfield(opts,'adaptSens'),    opts.adaptSens = 0.3; end
if ~isfield(opts,'cannyThresh'),  opts.cannyThresh = [0.06 0.18]; end
if ~isfield(opts,'gaborWavelengths'), opts.gaborWavelengths = [3 4 5]; end
if ~isfield(opts,'gaborTheta'),   opts.gaborTheta = 0:15:165; end
if ~isfield(opts,'morphOpen'),    opts.morphOpen = 0; end
if ~isfield(opts,'morphClose'),   opts.morphClose = 0; end
if ~isfield(opts,'minObject'),    opts.minObject = 100; end
if ~isfield(opts,'spurPrune'),    opts.spurPrune = Inf; end

I = im2double(Igray);

% 1) 대비 보정 + 블러
I = adapthisteq(I,'NumTiles',[8 8],'ClipLimit',opts.claheClip);
if opts.gaussSigma>0, I = imgaussfilt(I, opts.gaussSigma); end
if opts.invert, I = 1 - I; end % 어두운 선을 밝게

% 2) 선강조/이진화
switch lower(opts.method)
    case 'adaptive'
        T  = adaptthresh(I, opts.adaptSens, 'NeighborhoodSize', opts.adaptWin);
        BW = imbinarize(I, T);

    case 'canny'
        E  = edge(I,'canny',opts.cannyThresh);
        % 경계선은 1px, 내부를 메우기 위해 작은 닫힘
        BW = imfill(E,'holes');
    case 'gabor'
        g = gabor(opts.gaborWavelengths, opts.gaborTheta);
        R = imgaborfilt(I, g);          % filter responses
        Rmax = max(R,[],3);             % 방향/파장 중 최댓값
        Rn = mat2gray(Rmax);
        T  = adaptthresh(Rn, 0.5, 'NeighborhoodSize', opts.adaptWin);
        BW = imbinarize(Rn, T);
    otherwise
        error('Unknown method: %s', opts.method);
end

% % ------------------ 로컬 절개 (local carving) ------------------
% % 기본값 (Defaults에 추가해도 좋음)
% if ~isfield(opts,'minGapPx'),    opts.minGapPx    = 4; end    % gap 임계 (px)
% if ~isfield(opts,'trenchWidth'), opts.trenchWidth = 5; end    % 절개 폭(반지름 개념) (px)
% if ~isfield(opts,'minThickness'),opts.minThickness= 0; end    % 선이 완전히 사라지지 않게 허용하는 최소 두께(px)
% 
% for i=1:3
% 
% % 1) 배경 거리와 배경 중심선 계산
% D_bg = bwdist(BW);                     % background 픽의 foreground까지 거리 (배경>0, 전경=0)
% gapCenter = bwskel(~BW);               % 배경의 medial axis
% 
% % 2) 좁은 gap 후보(중심선 중에서 반폭 < minGapPx/2 인 것)
% narrowCenter = gapCenter & (D_bg < (opts.minGapPx+1)/2);
% 
% % 3) 중심선을 trenchWidth 만큼 팽창시켜 '절개 후보 마스크' 생성
% se = strel('disk', max(1, opts.trenchWidth+1));
% carveCand = imdilate(narrowCenter, se);   % carve candidate (may cover foreground)
% 
% % 4) 안전성 검사: carve가 전경의 아주 얇은 부분을 잘라내지 않도록 로컬 두께 체크
% %    전경의 로컬 반폭(=distance to background) 계산
% Df = bwdist(~BW);                          % foreground 픽의 background 거리 (foreground>0, background=0)
% % 허용 조건: carve가 겹치는 foreground 픽들 중에서 로컬 두께 >= minThickness
% safeToCarve = carveCand & BW & (Df >= opts.minThickness);
% 
% % 5) carve 실행 (전경에서만 제거)
% BW(safeToCarve) = 0;
% 
% % (선택) 6) 아주 작은 점 제거 (침식으로 생긴 잡티)
% BW = bwareaopen(BW, opts.minObject);   % 기존 opts.minObject 사용
% % ----------------------------------------------------------------
% 
% end


BW_raw = BW;


%3) 형태학적 정리
if opts.morphOpen>0
    BW = imopen(BW, strel('disk',opts.morphOpen));
end
if opts.morphClose>0
    BW = imclose(BW, strel('disk',opts.morphClose));
end
BW = bwmorph(BW, 'thin', Inf);   % <== 중요
BW = bwareaopen(BW, opts.minObject);

BW_morph = BW;


% 4) Skeleton + 가지치기
skel = bwskel(BW);
if opts.spurPrune>0
    skel = bwmorph(skel,'spur',opts.spurPrune);
end




end
