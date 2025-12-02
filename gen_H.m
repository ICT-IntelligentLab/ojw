    %码率
    r=0.7;
 
    %码长
    n=480;
  
    %列重
    dv=2;
    
    k=n*r;
    m=n-k;
    b=1;
    while(b)
        %生成基矩阵
        H_b=gen_H_b(m,k,dv);

        %检测四循环
        [cycle4num,~]=check4cycle(H_b);

        %检测六循环
        [cycle6num,~]=check6cycle(H_b);

        if cycle4num==0&&cycle6num==0      
            b=0;
        end
    end
    fprintf('存在%d个四循环\n', cycle4num);
    fprintf('存在%d个六循环\n', cycle6num);  
   
    P=eye(size(H_b,1));
    H=[H_b,P];
    %生成矩阵名称 
    H_Name = sprintf('H%d',2);
    % 将生成的矩阵保存到对应的 .mat 文件中
    save([H_Name, '.mat'], 'H');
    fprintf('校验矩阵H%d已保存\n',1);
   