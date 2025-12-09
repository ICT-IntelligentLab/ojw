function modSig = bpskmod(bitSeq)
    % bitSeq: 输入比特序列 (0/1)
    % modSig: 输出BPSK符号 (-1 / +1)

    if any(bitSeq~=0 & bitSeq~=1)
        error('输入必须是0/1比特！');
    end

    % BPSK 映射：0 → +1, 1 → -1
    modSig = 1 - 2*bitSeq;
    modSig = double(modSig) + 0i;
end
