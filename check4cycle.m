%%检测矩阵中存在四循环的个数和位置
function [cycle4num,cycle4]=check4cycle(H)

    %确定矩阵参数
    dim=size(H);
    rows=dim(1);
    cols=dim(2);
    
    cycle4num = 0;
    cycle4(:,8)=0;
    
    for irow1 = 1:rows
        for jcol1 = 1:cols
            if H(irow1,jcol1) ==1
                onesInRow1 = find(H(irow1,:));
                for ilevel1=1:length(onesInRow1)
                    jcol2 = onesInRow1(ilevel1);
                    if jcol2 > jcol1
                        onesInCol2 = find(H(:,jcol2));
                        for jvertical1 = 1:length(onesInCol2)
                            irow2 = onesInCol2(jvertical1);
                            if irow2>irow1
                                onesInRow2 = find(H(irow2,:));
                                for ilevel2 = 1:length(onesInRow2)
                                    jcol3 = onesInRow2(ilevel2);
                                    if jcol3 ==jcol1&&jcol2~=jcol3
                                        cycle4num = cycle4num + 1;
                                        cycle4(cycle4num,:) = [irow1,jcol1,irow1,jcol2,irow2,jcol2,irow2,jcol3];
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
end


