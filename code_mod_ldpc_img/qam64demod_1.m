function demodsignal=qam64demod_1(signal,h,noiseVar,outputType)

  if noiseVar == 0
        error('noiseVar不能为零');
  end 

  if h == 0
        error('h不能为零');
  end 

  n=length(signal);
  demodsignal=zeros(6*n,1);
  A=[3+3i 3-3i 3+5i 3-5i 3+7i 3-7i 3+1i 3-1i 5+3i 5-3i 5+5i 5-5i 5+7i 5-7i 5+1i 5-1i  7+3i 7-3i 7+5i 7-5i 7+7i 7-7i 7+1i 7-1i 1+3i 1-3i 1+5i 1-5i 1+7i 1-7i 1+1i 1-1i  -3+3i -3-3i -3+5i -3-5i -3+7i -3-7i -3+1i -3-1i -5+3i -5-3i -5+5i -5-5i -5+7i -5-7i -5+1i -5-1i -7+3i -7-3i -7+5i -7-5i -7+7i -7-7i -7+1i -7-1i -1+3i -1-3i -1+5i -1-5i -1+7i -1-7i -1+1i -1-1i];
  %计算LLR
  for i=1:n    
      signal(i)=signal(i)/h;
      D=-abs(h)^2*abs(signal(i)-A).^2/(2*noiseVar);

      demodsignal(6*i-5)=1/sqrt(2*pi*noiseVar)*(max(D(1:32))-max(D(33:64)));
      demodsignal(6*i-4)=1/sqrt(2*pi*noiseVar)*(max(D([9:24, 41:56]))-max(D([1:8, 25:40, 57:64])));
      demodsignal(6*i-3)=1/sqrt(2*pi*noiseVar)*(max(D([17:32, 49:64]))-max(D([1:16, 33:48])));
      demodsignal(6*i-2)=1/sqrt(2*pi*noiseVar)*(max(D(1:2:end))-max(D(2:2:end)));
      idx1 = [1, 2, 3, 4, 9, 10, 11, 12, 17, 18, 19, 20, 25, 26, 27, 28, 33, 34, 35, 36, 41, 42, 43, 44, 49, 50, 51, 52, 57, 58, 59, 60]+2;
      idx2 = [5, 6, 7, 8, 13, 14, 15, 16, 21, 22, 23, 24, 29, 30, 31, 32, 37, 38, 39, 40, 45, 46, 47, 48, 53, 54, 55, 56, 61, 62, -1, 0]+2;
      demodsignal(6*i-1)=1/sqrt(2*pi*noiseVar)*(max(D(idx1))-max(D(idx2)));
      idx1 = [5, 6, 7, 8, 13, 14, 15, 16, 21, 22, 23, 24, 29, 30, 31, 32, 37, 38, 39, 40, 45, 46, 47, 48, 53, 54, 55, 56, 61, 62, 63, 64];
      idx2 = [1, 2, 3, 4, 9, 10, 11, 12, 17, 18, 19, 20, 25, 26, 27, 28, 33, 34, 35, 36, 41, 42, 43, 44, 49, 50, 51, 52, 57, 58, 59, 60];
      demodsignal(6*i)=1/sqrt(2*pi*noiseVar)*(max(D(idx1))-max(D(idx2)));
  end

  % 判断输出类型
  if nargin < 4
      outputType = 'llr';  % 如果用户没指定，默认输出bit
  end

  if strcmpi(outputType, 'bit')
      % 硬判决
      for i = 1:6*n
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