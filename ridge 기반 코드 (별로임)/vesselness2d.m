function V = vesselness2d(I, sigmas)
% I: grayscale double [0~1]
% sigmas: e.g., [1 2 3]
I = im2double(I);
V = zeros(size(I));
for s = sigmas
    g = imgaussfilt(I, s);

    % 2차 미분(해시안) 근사
    [gx, gy] = gradient(g);
    [gxx, gxy] = gradient(gx);
    [gyx, gyy] = gradient(gy);

    % Hessian eigenvalues
    % H = [gxx gxy; gyx gyy]; (gyx≈gxy)
    A = (gxx + gyy)/2;
    B = sqrt( ((gxx - gyy)/2).^2 + gxy.^2 );
    l1 = A + B;   % 큰 고유값
    l2 = A - B;   % 작은 고유값

    % 선 구조 응답 (Frangi 간략형)
    beta  = 0.5; c = 15;   % 튜닝 가능
    Rb = (l1./(l2+eps)).^2;     % 원형성 억제
    S2 = l1.^2 + l2.^2;         % 구조 강도
    resp = exp(-Rb/(2*beta^2)) .* (1 - exp(-S2/(2*c^2)));

    % 어두운 선/밝은 선 선택(이미지에 맞게)
    % 선이 어둡다면 l2<0 구간만 사용:
    resp(l2 > 0) = 0;

    V = max(V, resp); % 멀티스케일 최대
end
V = mat2gray(V);
end
