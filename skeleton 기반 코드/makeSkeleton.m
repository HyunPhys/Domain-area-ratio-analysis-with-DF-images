function skel = makeSkeleton(Igray, sigma, minObj)
I = im2double(Igray);
I = imgaussfilt(I, sigma); % Gaussian filter (선 부드럽게)
I = 1 - I;                          % 어두운 선 강조 (반전: invert) (binarize 쉽도록)
BW = imbinarize(I, graythresh(I));  % Otsu thereshold로 line (bright)만 남김
BW = bwareaopen(BW, minObj); % 작은 얼룩 제거
skel = bwskel(BW); % 한 픽셀 두께 skeleton 확보
end