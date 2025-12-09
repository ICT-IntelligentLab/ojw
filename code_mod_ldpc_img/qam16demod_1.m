function demodsignal=qam16demod_1(signal,h,noiseVar,outputType)

  if noiseVar == 0
        error('noiseVar不能为零');
  end 

  if h == 0
        error('h不能为零');
  end 

  n=length(signal);
  demodsignal=zeros(4*n,1);
  A=[1+1i 1-1i 1+3i 1-3i -1+1i -1-1i -1+3i -1-3i 3+1i 3-1i 3+3i 3-3i -3+1i -3-1i -3+3i -3-3i];
  %计算LLR
  for i=1:n
      signal(i)=signal(i)/h;
      D=-abs(h)^2*abs(signal(i)-A).^2/(2*noiseVar);

      demodsignal(4*i-3)=1/sqrt(2*pi*noiseVar)*(max(D([1:4, 9:12]))-max(D([5:8, 13:16])));
      demodsignal(4*i-2)=1/sqrt(2*pi*noiseVar)*(max(D(9:16))-max(D(1:8)));
      demodsignal(4*i-1)=1/sqrt(2*pi*noiseVar)*(max(D(1:2:end))-max(D(2:2:end))); 
      idx1 = [3, 4, 7, 8, 11, 12, 15, 16];
      idx2 = [1, 2, 5, 6, 9, 10, 13, 14];
      demodsignal(4*i)=1/sqrt(2*pi*noiseVar)*(max(D(idx1))-max(D(idx2)));
  end

  % 判断输出类型
  if nargin < 4
      outputType = 'llr';  % 如果用户没指定，默认输出bit
  end

  if strcmpi(outputType, 'bit')
      % 硬判决
      for i = 1:4*n
          if demodsignal(i) < 0
              demodsignal(i) = 1;
          else
              demodsignal(i) = 0;
          end
      end
  elseif strcmpi(outputType, 'llr')
      % 什么也不做，保留LLR
  else
      error('outputType必须是"bit"或"llr"');
  end

end