%%使用PEG算法生成QC_LDPC基矩阵
function H_b=gen_H_b(m,g,dv)
    
    
    h=zeros(m, g);
    dc=zeros(1,m);
    %下面展开PEG算法，将每一个变量节点展成1层子图，构造Tanner图
    for j=1:g           %对于每一个变量节点循环
        for k=1:dv  %对于度分布循环，控制边的数口
            if k==1
                %若为第一条边，直接寻找最小度分布的校验节点
                k1=find(dc==min(dc));
                h(k1(1),j)=1;
                dc(k1(1))=dc(k1(1))+1;
            else 
                %若不是第一条边，则展成1层子图，寻找在1层最小度分布的校验节点
                flag=1;
                l=1;
                %这里对每一个校验节点是否存在于第1层做标记，最大展开层数待定
                dcf=zeros(g,m);
                row=find(h(:,j));       %列搜索，搜索为1的行标
                dcf(l, row)=1;          %展开第一层
                while(flag)
                      l=l+1;
                      h_row=h(row,:);
                      if  length(row)==1
                          col=find(h_row);
                      else
                          col=find(any(h_row(:, 1:g)));   %行搜索，寻找为1的列标
                      end
                      h_col=(h(:,col))';
                      if  length(col)==1
                          row1=find(h_col);
                      else
                          row1=find(any(h_col(:,1:m)));
                      end
                      row=row1;
                      dcf(l,row)=1;
                      if  l>=2
                          %停止展开第一种条件：集合元素停止增长
                          if  dcf(l,:)==dcf(l-1,:)
                              nc_all=find(dcf(l,:)==0);
                              ndc=dc(nc_all);
                              nc=find(ndc==min(ndc));
                              h(nc_all(nc(1)),j)=1;
                              dc(nc_all(nc(1)))=dc(nc_all(nc(1)))+1;
                              break;
                          %停止展开第二种情况：集合元素饱和
                          elseif  (sum(dcf(l-1,:))<m) && (sum (dcf(l,:))==m)
                                  nc1_all=find((dcf(l-1,:)&dcf(l,:))==0);
                                  ndc1=dc(nc1_all);
                                  nc1=find(ndc1==min(ndc1));
                                  h(nc1_all(nc1(1)),j)=1;
                                  dc(nc1_all(nc1(1)))=dc(nc1_all(nc1(1)))+1;
                                  break;
                           end
                     end
                end
            end
        end
    end
    
    H_b=h;
end