function modsignal=qam16mod(bits)
  
if mod(length(bits), 4) ~= 0
        error('输入比特流的长度必须是4的倍数');
end 
  bits=double(bits);
  n=length(bits)/4;
  modsignal=zeros(n,1);
  for i=1:n
  modsignal(i)=(1-2*bits(4*i-3))*(3-2*bits(4*i-2))+1i*(1-2*bits(4*i-1))*(3-2*bits(4*i));
  end
end