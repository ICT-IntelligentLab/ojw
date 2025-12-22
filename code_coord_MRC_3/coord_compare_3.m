clear; clc; close all;

%% =============================
%     输入输出路径设定
%% =============================
tx_img_dir   = "tx/images";
tx_coord_dir = "tx/coords";

rx_root = "h5_h3_coord_ber_3";
if ~exist(rx_root,'dir'), mkdir(rx_root); end

%% =============================
%     LDPC 初始化
%% =============================
H1 = load("H2.mat");
H1 = sparse(H1.H ~= 0);
[m1, n1] = size(H1);
k1 = n1 - m1;
cfgEnc1 = ldpcEncoderConfig(H1);
cfgDec1 = ldpcDecoderConfig(H1);
maxnumiter = 20;

H2 = load("H2.mat");
H2 = sparse(H2.H ~= 0);
[m2, n2] = size(H2);
k2 = n2 - m2;
cfgEnc2 = ldpcEncoderConfig(H2);
cfgDec2 = ldpcDecoderConfig(H2);

%% =============================
%       仿真参数
%% =============================
tx_files = dir(fullfile(tx_img_dir, "*.jpg"));

SNR_list = 0:2:16;
m_list   = [3 5 7 9];%[1 3 5 7 9]

Ns = length(SNR_list);
Nm = length(m_list);

BER_coord = zeros(Ns, Nm);
BER_img   = zeros(Ns, Nm);
BER_total = zeros(Ns, Nm);

MC = 16;%16

ber_root = fullfile(rx_root, "ber");
if ~exist(ber_root,'dir'), mkdir(ber_root); end

%% =============================
%       SNR × m 双循环
%% =============================
for si = 1:Ns

    SNR = SNR_list(si);
    fprintf("\n===== SNR = %d dB =====\n", SNR);

    for mi = 1:Nm

        m = m_list(mi);
        fprintf("  → m = %d\n", m);

        coord_errors = 0;
        img_errors   = 0;
        total_errors = 0;

        for mc = 1:MC
            for fi = 1:length(tx_files)

                %% =============================
                %     读取图片
                %% =============================
                filename = tx_files(fi).name;
                base = erase(filename, ".jpg");

                img = imread(fullfile(tx_img_dir, filename));
                img_vec = img(:);
                img_bits_mat = de2bi(double(img_vec), 8, 'left-msb');
                img_bits = reshape(img_bits_mat.', [], 1);
                img_len = length(img_bits);

                %% =============================
                %     读取坐标
                %% =============================
                coord = dlmread(fullfile(tx_coord_dir, base + ".txt"));
                coord_vec = coord(:);
                coord_bits_mat = de2bi(double(coord_vec), 10, 'left-msb');
                coord_bits = reshape(coord_bits_mat.', [], 1);
                coord_len = length(coord_bits);

                %% =============================
                %     Part A：coord TX
                %% =============================
                numBlocks_coord = ceil(coord_len / k1);
                pad_coord = numBlocks_coord*k1 - coord_len;
                coord_pad = [coord_bits; zeros(pad_coord,1)];

                info = coord_pad(1:k1);
                cw = ldpcEncode(info, cfgEnc1);
                tx_coord_mod_all = qammod(double(cw),16,InputType='bit', ...
                UnitAveragePower=true);

                %% =============================
                %     Part B：image TX（coord 插入）
                %% =============================
                numBlocks_img = ceil(img_len / k2);
                pad_img = numBlocks_img*k2 - img_len;
                img_pad = [img_bits; zeros(pad_img,1)];

                rx_bits_coord_all = zeros(m*k1,1);
                rx_bits_img_all   = zeros(numBlocks_img*k2,1);

                insert_period = ceil(numBlocks_img / m);
                coord_cnt = 0;

                for b = 1:numBlocks_img

                    %% --- image ---
                    idx = (b-1)*k2 + 1 : b*k2;
                    cw = ldpcEncode(img_pad(idx), cfgEnc2);
                    modsig = qam16mod(double(cw));

                    h1 = 1/sqrt(2)*(randn + 1i*randn);
                    rx_img_sig = awgn(modsig*h1, SNR, 'measured','dB');

                    var = 1/(10^(SNR/10));
                    rx_img_llr = qam16demod_1(rx_img_sig, h1, 10*var, 'llr');
                    dec2 = ldpcDecode(rx_img_llr, cfgDec2, maxnumiter);

                    rx_bits_img_all((b-1)*k2 + 1 : b*k2) = dec2(:);

                    %% --- coord 插入 ---
                    if mod(b-1, insert_period) == 0 && coord_cnt < m
                        coord_cnt = coord_cnt + 1;
                        %h2 = 1/sqrt(2)*(randn + 1i*randn);
                        rx_coord_sig = awgn(tx_coord_mod_all*h1, SNR, 'measured','dB');
                        rx_coord_sig = rx_coord_sig./h1;
                        rx_coord_llr = qamdemod( ...
                            rx_coord_sig, ...
                            16, ...
                            'UnitAveragePower', true, ...
                            'OutputType', 'llr', ...
                            'NoiseVariance', var);
                        dec1 = ldpcDecode(rx_coord_llr, cfgDec1, maxnumiter);

                        rx_bits_coord_all((coord_cnt-1)*k1 + 1 : coord_cnt*k1) = dec1(:);
                    end
                end

                %% =============================
                %     coord 投票恢复
                %% =============================
                rx_bits_coord_mat = reshape(rx_bits_coord_all, k1, m);
                rx_coord_bits = mode(rx_bits_coord_mat, 2);
                rx_coord_bits = rx_coord_bits(1:coord_len);
                rx_img_bits   = rx_bits_img_all(1:img_len);

                %% =============================
                %     误码统计
                %% =============================
                coord_errors = coord_errors + sum(coord_bits ~= rx_coord_bits);
                img_errors   = img_errors   + sum(img_bits   ~= rx_img_bits);

                total_tx = [coord_bits; img_bits];
                total_rx = [rx_coord_bits; rx_img_bits];
                total_errors = total_errors + sum(total_tx ~= total_rx);

            end
        end

        %% =============================
        %     BER 计算
        %% =============================
        BER_coord(si,mi) = coord_errors / ...
            (length(coord_bits) * m * length(tx_files) * MC);
        fprintf("\n=== BER coord %d ===\n",BER_coord(si,mi));
        BER_img(si,mi) = img_errors / ...
            (length(img_bits) * length(tx_files) * MC);

        BER_total(si,mi) = total_errors / ...
            ((length(coord_bits)*m + length(img_bits)) ...
             * length(tx_files) * MC);
    end
end

%% =============================
%     保存结果
%% =============================
out_mat = fullfile(ber_root, "ber_m_compare.mat");
save(out_mat, ...
     "SNR_list", ...
     "m_list", ...
     "BER_coord", ...
     "BER_img", ...
     "BER_total");

fprintf("\n=== BER 统计完成，已保存 ===\n");
