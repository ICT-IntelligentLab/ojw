clear; clc;

%% 参数设置
imgFolder = "images/test";   % 图片目录
SNR_list = 0:2:20;           % 信噪比范围
maxnumiter = 20;             % LDPC 解码最大迭代

% 结果存放
BER_all = zeros(length(SNR_list), 1);
BLER_all = zeros(length(SNR_list), 1);

%% 扫描图片
imgFiles = dir(fullfile(imgFolder, "*.jpg"));
if isempty(imgFiles)
    error("目录 %s 下没有 jpg 文件！", imgFolder);
end

fprintf("共检测到 %d 张图像.\n", length(imgFiles));

%% ==========================================================
%                遍历所有 SNR 计算 BER/BLER
%% ==========================================================
for si = 1:length(SNR_list)

    SNR = SNR_list(si);
    fprintf("\n=== 处理 SNR = %d dB ===\n", SNR);

    total_errors = 0;   % BER numerator
    total_bits   = 0;   % BER denominator

    total_blocks = 0;   % BLER denominator
    error_blocks = 0;   % BLER numerator

    %% 遍历所有图片
    for f = 1:length(imgFiles)

        imgName = imgFiles(f).name;
        imgPath = fullfile(imgFolder, imgName);

        img = imread(imgPath);

        % 跳过纯色图
        if std(double(img(:))) == 0
            fprintf("跳过空白图：%s\n", imgName);
            continue;
        end

        % 图像 → bit
        img_vec = img(:);
        img_bits = de2bi(img_vec, 8, 'left-msb')';
        img_bits = img_bits(:);
        img_bits = int8(img_bits);
        img_len = length(img_bits);

        %% ----------------- LDPC 选择 -----------------
        
            Hs = load('H1.mat');  k = 240;
        

        H = sparse(Hs.H ~= 0);
        cfgEnc = ldpcEncoderConfig(H);
        cfgDec = ldpcDecoderConfig(H);

        %% ----------------- 分块 ----------------------
        numBlocks = ceil(img_len / k);
        pad_len = numBlocks*k - img_len;
        bits_pad = [img_bits; zeros(pad_len,1)];

        rx_bits_all = zeros(numBlocks*k, 1);

        %% ==================================================
        %           对该图像进行所有块的传输
        %% ==================================================
        for bi = 1:numBlocks
            idx = (bi-1)*k + 1 : bi*k;
            info_block = bits_pad(idx);

            % 瑞丽信道
            h = (randn + 1i*randn) / sqrt(2);

            % LDPC 编码
            cw = ldpcEncode(info_block, cfgEnc);

            % BPSK 调制
            modsignal = bpskmod(cw);

            % 信道
            modsignal = h * modsignal;
            noSig = awgn(modsignal, SNR, 'measured');

            % 噪声方差
            var = 10/(10^(SNR/10));

            % LLR 解调
            demodsignal = bpskdemod(noSig, h, var, 'llr');

            % LDPC 解码
            rx_block = ldpcDecode(demodsignal, cfgDec, maxnumiter);

            rx_bits_all(idx) = rx_block;

            %% ---- 统计误块率 BLER ----
            total_blocks = total_blocks + 1;
            if any(rx_block ~= info_block)
                error_blocks = error_blocks + 1;
            end
        end

        %% 恢复 bit（仅用于计算误码率）
        rx_bits = rx_bits_all(1:img_len);

        %% ---- 统计误码率 BER ----
        bit_errors = sum(rx_bits ~= img_bits);
        total_errors = total_errors + bit_errors;
        total_bits = total_bits + img_len;

    end

    %% ================= 保存该 SNR 的 BER/BLER ================
    BER_all(si) = total_errors / total_bits;
    BLER_all(si) = error_blocks / total_blocks;

    fprintf("SNR=%d dB: BER=%.3e, BLER=%.3e\n", ...
        SNR, BER_all(si), BLER_all(si));
end

%% ==========================================================
%                      绘图保存结果
%% ==========================================================

figure;
plot(SNR_list, BER_all, '-o', 'LineWidth', 2);
xlabel("SNR (dB)"); ylabel("BER");
title("误码率 BER vs SNR");
grid on;
saveas(gcf, "BER_curve.jpg");

figure;
plot(SNR_list, BLER_all, '-s', 'LineWidth', 2);
xlabel("SNR (dB)"); ylabel("BLER");
title("误块率 BLER vs SNR");
grid on;
saveas(gcf, "BLER_curve.jpg");

fprintf("\n已保存：BER_curve.jpg  和  BLER_curve.jpg\n");
