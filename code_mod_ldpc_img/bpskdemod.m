function demodBits = bpskdemod(signal, h, noiseVar, outputType)

    if noiseVar == 0
        error('noiseVar不能为0');
    end

    if h == 0
        error('h不能为0');
    end

    n = length(signal);
    demodBits = zeros(n,1);

    % 默认输出LLR
    if nargin < 4
        outputType = 'llr';
    end

    % ----------- BPSK 软判决 LLR 计算 -----------
    % BPSK 星座： +1 ↔ bit=0,   -1 ↔ bit=1
    % 接收信号： y = h*x + n
    % LLR = log( p(y|x=+1) / p(y|x=-1) )
    %      = (2/σ²)*Re{ y * conj(h) }
    %
    % -------------------------------------------------

    for i = 1:n
        y = signal(i);

        % 消除信道
        y_eq = y / h;

        % LLR = (2/σ^2)*real(y_eq)
        demodBits(i) = (2 / noiseVar) * real(y_eq);
    end

    % ----------- 输出类型选择 -----------
    if strcmpi(outputType, 'bit')

        % 硬判决：LLR<0 → bit=1 ; LLR>=0 → bit=0
        for i = 1:n
            if demodBits(i) < 0
                demodBits(i) = 1;
            else
                demodBits(i) = 0;
            end
        end

    elseif strcmpi(outputType, 'llr')
        % 保留LLR不变

    else
        error('outputType必须是"bit"或"llr"');
    end
end
