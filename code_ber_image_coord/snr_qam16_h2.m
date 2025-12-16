 clear; clc; close all;

%% =============================
%     输入输出路径设定
%% =============================
tx_img_dir   = "tx/images";
tx_coord_dir = "tx/coords";

rx_root = "qam16_h2_img_ber";
if ~exist(rx_root,'dir'), mkdir(rx_root); end

%     LDPC 初始化

H1 = load("H2.mat");
H1 = sparse(H1.H ~= 0);
[m1, n1] = size(H1);
k1 = n1 - m1;       % 信息位长度
cfgEnc1 = ldpcEncoderConfig(H1);
cfgDec1 = ldpcDecoderConfig(H1);
maxnumiter = 20;

H2 = load("H2.mat");
H2 = sparse(H2.H ~= 0);
[m2, n2] = size(H2);
k2 = n2 - m2;       % 信息位长度
cfgEnc2 = ldpcEncoderConfig(H2);
cfgDec2 = ldpcDecoderConfig(H2);

%% =============================
%       遍历所有发送文件
%% =============================
tx_files = dir(fullfile(tx_img_dir, "*.jpg"));

SNR_list = 0:2:16; 

% 统计结果保存
    ber_root = fullfile(rx_root, "ber");
    if ~exist(ber_root,'dir'), mkdir(ber_root); end

    BER_coord = zeros(length(SNR_list), 1);   % 每个 SNR 下坐标误码率
    BER_img   = zeros(length(SNR_list), 1);   % 每个 SNR 下图像误码率
    BER_total = zeros(length(SNR_list), 1);   % 每个 SNR 下的总 BER

for si = 1:length(SNR_list)

    SNR = SNR_list(si);
    snr_dir = fullfile(rx_root, sprintf('SNR_%d', SNR));
    rx_img_dir   = fullfile(snr_dir, "images");
    rx_coord_dir = fullfile(snr_dir, "coords");
    if ~exist(rx_img_dir,'dir'), mkdir(rx_img_dir); end
    if ~exist(rx_coord_dir,'dir'), mkdir(rx_coord_dir); end
    
    coord_errors  = 0;
    img_errors  = 0;
    total_errors  = 0;

    MC = 16; 
    h0=0;

    for mc = 1:MC

    for fi = 1:length(tx_files)%length(tx_files)

    filename = tx_files(fi).name;
    base = erase(filename, ".jpg");

    fprintf("\n===== Processing %s =====\n", filename);

    % 读取图片
    img = imread(fullfile(tx_img_dir, filename));
    img_vec = img(:);                       % 列向量 [pixels*channels x 1]
    img_bits_mat = de2bi(double(img_vec), 8, 'left-msb'); % 每行一个像素的 8-bit
    img_bits = reshape(img_bits_mat.', [], 1);  % 按列堆叠 -> 列主序，与 de2bi(:) 相对称
    img_len = length(img_bits);

    % 读取坐标 txt (假设每行: x1 y1 x2 y2)
    coord = dlmread(fullfile(tx_coord_dir, base + ".txt")); % matrix Mx4
    coord_vec = coord(:);
    coord_bits_mat = de2bi(double(coord_vec), 10, 'left-msb'); % 每行一个数字 10-bit
    coord_bits = reshape(coord_bits_mat.', [], 1);
    coord_len = length(coord_bits);

    %% ======================================================
    %              Part A：坐标数据 TX
    %% ======================================================
    numBlocks_coord = ceil(coord_len / k1);
    pad_coord = numBlocks_coord*k1 - coord_len;
    coord_pad = [coord_bits; zeros(pad_coord,1)];

    tx_coord_mod_all = complex([] , []);  % 预分配为空复数向量

    for b = 1:1
        idx = (b-1)*k1 + 1 : b*k1;
        info = coord_pad(idx);

        % LDPC 编码
        cw = ldpcEncode(info, cfgEnc1);   % cw 应为长度 n 的 0/1 向量

        % BPSK 调制
        modsig = bpskmod(double(cw));    % 变成复数列
        tx_coord_mod_all = [tx_coord_mod_all; modsig];
    end

    %% ======================================================
    %              Part B：图片数据 TX
    %% ======================================================
    numBlocks_img = ceil(img_len / k2);
    pad_img = numBlocks_img*k2 - img_len;
    img_pad = [img_bits; zeros(pad_img,1)];

    tx_img_mod_all = complex([] , []);
    rx_bits_coord_all = zeros(numBlocks_img*k1,1);
    rx_bits_img_all = zeros(numBlocks_img*k2,1);
    s=0;
    for b = 1:numBlocks_img
        idx = (b-1)*k2 + 1 : b*k2;
        info = img_pad(idx);

        % LDPC
        cw = ldpcEncode(info, cfgEnc2);

        % BPSK
        modsig = qam16mod(double(cw));

        h = 1/sqrt(2) * (randn + 1i*randn);
        
        rx_coord_sig = tx_coord_mod_all * h;
        rx_coord_sig = awgn(rx_coord_sig, SNR, 'measured','dB');

        rx_img_sig = modsig * h;
        h0=h0+1;
        rx_img_sig = awgn(rx_img_sig, SNR, 'measured','dB');
        
        var = 1/(10^(SNR/10));
        rx_coord_llr = bpskdemod(rx_coord_sig, h, var, 'llr');
        rx_img_llr   = qam16demod_1(rx_img_sig,   h, 10*var, 'llr');

        dec1 = ldpcDecode(rx_coord_llr, cfgDec1, maxnumiter);
        info1 = dec1(:);
        rx_bits_coord_all((b-1)*k1 + 1 : b*k1) = info1;
        
        dec2 = ldpcDecode(rx_img_llr, cfgDec2, maxnumiter);
        info2 = dec2(:); 
        rx_bits_img_all((b-1)*k2 + 1 : b*k2) = info2;

    end

    rx_bits_coord_mat = reshape(rx_bits_coord_all, k1, numBlocks_img);
    rx_coord_bits = mode(rx_bits_coord_mat, 2);
    rx_coord_bits = rx_coord_bits(1:length(coord_bits));
    rx_img_bits = rx_bits_img_all(1:img_len);

    % 还原坐标数值
    rx_coord_mat = reshape(rx_coord_bits, 10, []).';   % 每行一个数
    coord_rx = bi2de(rx_coord_mat, 'left-msb');        % 列向量
    coord_rx = reshape(coord_rx, size(coord));        % 还原成原始 coord 尺寸
    coord_rx = max(0, min(640, coord_rx));  % 确保所有坐标值在 [0, 640] 范围内

    % 打印前几个坐标做校验
    fprintf("coord 原始前 3 行:\n");
    disp(coord(1:min(3,size(coord,1)),:));
    fprintf("coord 接收前 3 行:\n");
    disp(coord_rx(1:min(3,size(coord_rx,1)),:));

    %% 保存坐标
    fid = fopen(fullfile(rx_coord_dir, base + ".txt" ), "w");
    for r = 1:size(coord_rx,1)
        fprintf(fid, "%d %d %d %d\n", coord_rx(r,:));
    end
    fclose(fid);

    %% ======================================================
    %        Part B：图片 RX
    %% ======================================================
    

    %% bits → pixel (保持每行一个像素 8-bit)
    rx_img_mat = reshape(rx_img_bits, 8, []).';   % rows = pixels, cols = 8 bits
    rx_pixels  = bi2de(rx_img_mat, 'left-msb');   % 列向量像素值
    rx_img     = reshape(uint8(rx_pixels), size(img));  % 恢复到原图尺寸

    %% 保存恢复图片
    imwrite(rx_img, fullfile(rx_img_dir, filename));
    fprintf("Saved → %s\n", filename);
    % ==========================
    %   统计坐标误码率
    % ==========================
    coord_bits_tx = coord_bits;           % 原始发送
    coord_bits_rx = rx_coord_bits;        % 接收端
    coord_errors  = coord_errors + sum(coord_bits_tx ~= coord_bits_rx);

    % ==========================
    %   统计图像误码率
    % ==========================
    img_bits_tx = img_bits;
    img_bits_rx = rx_img_bits;
    img_errors  = img_errors + sum(img_bits_tx ~= img_bits_rx);
    
    % ==========================
    %   统计总 BER（坐标 + 图像）
    % ==========================
    total_tx_bits = [coord_bits_tx; img_bits_tx];
    total_rx_bits = [coord_bits_rx; img_bits_rx];
    total_errors  = total_errors + sum(total_tx_bits ~= total_rx_bits);

    end
    
    end
    fprintf("ber at MC = %d, h0 = %d\n", MC, h0);
    BER_coord(si) = coord_errors / (length(coord_bits_tx)*length(tx_files)*MC);
    BER_img(si) = img_errors / (length(img_bits_tx)*length(tx_files)*MC);
    BER_total(si) = total_errors / (length(total_tx_bits)*length(tx_files)*MC);

end

% ==========================
%   保存 BER 结果到 MAT 文件
% ==========================
out_mat = fullfile(ber_root, "ber_results.mat");

save(out_mat, "SNR_list", "BER_coord", "BER_img", "BER_total");

fprintf("=== BER 统计已保存到 %s ===\n", out_mat);

fprintf("\n==== RX 保存完成 ====\n");
