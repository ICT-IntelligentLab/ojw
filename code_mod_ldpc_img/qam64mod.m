function modsignal=qam64mod(bits)
  
if mod(length(bits), 6) ~= 0
        error('输入比特流的长度必须是6的倍数');
end 
  bits=double(bits);
  n=length(bits)/6;
  modsignal=zeros(n,1);
  for i=1:n
      I_bits = bits(6*i-5 : 6*i-3);  % 取前3比特
      Q_bits = bits(6*i-2 : 6*i);    % 取后3比特

      I_dec = bi2de(I_bits', 'left-msb');  % 转成十进制
      Q_dec = bi2de(Q_bits', 'left-msb');  % 转成十进制

      I=qam64_mapping(I_dec);
      Q=qam64_mapping(Q_dec);
      modsignal(i)=I+1i*Q;
  end
end