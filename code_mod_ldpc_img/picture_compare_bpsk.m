clear; clc;

img = imread('test.jpg');   % 读入图片
figure; imshow(img); title('原图');
img_vec = img(:);
img_bits = de2bi(img_vec, 8, 'left-msb');
img_bits = img_bits(:);
img_bits = int8(img_bits);
img_len = length(img_bits);

SNR_list = 0:2:16;  % 需要的信噪比集合

% 结果图窗口
figure;
tiledlayout(2, ceil((length(SNR_list)+1)/2));
nexttile;
imshow(img);
title("原图，BPSK+2/3");

% 保存所有 BER
BER = zeros(length(SNR_list),1);

for si = 1:length(SNR_list)

    SNR = SNR_list(si);

    % -------- LDPC 选择 ---------

    H = load('H1.mat');
    
    H = H.H;
    H = sparse(H ~= 0);
    [m, n] = size(H);
    k = n - m; 
    cfgEnc = ldpcEncoderConfig(H);
    maxnumiter = 20;
    cfgDec = ldpcDecoderConfig(H);

    % -------- 分块处理 ---------
    numBlocks = ceil(img_len / k);
    pad_len = numBlocks*k - img_len;
    img_bits_padded = [img_bits; zeros(pad_len,1)];

    rx_bits_all = zeros(numBlocks*k,1);

    for i = 1:numBlocks
        idx = (i-1)*k + 1 : i*k;
        info_block = img_bits_padded(idx);

        % 瑞丽信道 
        h = 1/sqrt(2) * (randn + 1i*randn);

        % LDPC 编码
        cw = ldpcEncode(info_block, cfgEnc);

        % BPSK 调制
        modsignal = bpskmod(cw);

        % 经过信道
        modsignal = h * modsignal;
        noSig = awgn(modsignal, SNR, 'measured','dB');

        % LLR
        var = 1/(10^(SNR/10));%qam和bpsk不同
        demodsignal = bpskdemod(noSig, h, var, 'llr');

        % LDPC 译码
        rx_block = ldpcDecode(demodsignal, cfgDec, maxnumiter);

        rx_bits_all(idx) = rx_block;
    end

    % 去除 padding
    rx_bits = rx_bits_all(1:img_len);

    % bit → 像素
    rx_bits_matrix = reshape(rx_bits, [], 8);
    rx_pixels = bi2de(rx_bits_matrix, 'left-msb');
    rx_img = reshape(uint8(rx_pixels), size(img));

    % -------- 显示恢复图像 --------
    nexttile;
    imshow(rx_img, 'Border', 'tight');   % 关键：去掉图像边框
    title(sprintf("SNR = %d dB", SNR), 'FontSize', 10);

    % --------计算 BER --------
    BER(si) = mean(rx_bits ~= img_bits);

end

%% -------- 让 tiledlayout 更紧凑 --------
tl = gcf;
set(gcf, 'Color', 'w');              % 白底
tiledlayout_handle = findall(gcf, 'Type', 'tiledlayout');
tiledlayout_handle.Padding = 'compact';
tiledlayout_handle.TileSpacing = 'compact';

%% -------- 保存结果图 --------
saveas(gcf, "result_BPSK_H1.jpg");
fprintf("已保存结果图");