img = imread('test.jpg');                  % 读入图片
imshow(img); title('原图');
SNR=10;
img_vec = img(:);                          % 展平为一维
img_bits = de2bi(img_vec, 8, 'left-msb');  % 每个像素 8bit
img_bits = img_bits(:);                    % 拉成比特序列
img_bits = int8(img_bits);

if SNR<15
   H= load('H1.mat');
   k = 240;  
else
    H= load('H2.mat');
    k = 336; 
end
% 信息位长度

 H = H.H;
 H=sparse(H ~=0);
 cfgEnc = ldpcEncoderConfig(H);
 maxnumiter=20;
 cfgDec = ldpcDecoderConfig(H);


n = 480;           % 码字长度
%M = 16

img_len = length(img_bits);
numBlocks = ceil(img_len / k);

% 如果最后一个块不足 k，进行 0 填充
pad_len = numBlocks*k - img_len;
img_bits_padded = [img_bits; zeros(pad_len,1)];



for i = 1:numBlocks
    idx = (i-1)*k + 1 : i*k;
    info_block = img_bits_padded(idx);          % 480-bit
    
    h= 1/sqrt(2)*(randn + 1i*randn);
    cw = ldpcEncode(info_block, cfgEnc); % 编码成 960-bit

    modsignal=bpskmod(cw);

    modsignal=h* modsignal;
    noSig = awgn( modsignal, SNR, 'measured'); 

var=10/(10^(SNR/10));
demodsignal=bpskdemod(noSig,h,var,'llr');


rx_block = ldpcDecode(demodsignal, cfgDec, maxnumiter);
rx_bits_all((i-1)*k+1 : i*k) = rx_block;
end



rx_bits = rx_bits_all(1:img_len);   % 去掉最后 padding


 
rx_bits_matrix = reshape(rx_bits, [], 8);
rx_pixels = bi2de(rx_bits_matrix, 'left-msb');

rx_img = reshape(uint8(rx_pixels), size(img));
imshow(rx_img); title('恢复图像');
imwrite(rx_img, 'rx_image.jpg');   



 





