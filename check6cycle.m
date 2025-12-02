%%检测矩阵中存在六循环的个数和位置
function [cycle6num,cycle6]=check6cycle(H)
    
    %确定矩阵参数
    dim=size(H);
    rows=dim(1);
    cols=dim(2);
    
    cycle6num = 0;
    cycle6(:,12) = 0;
    
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
                                    if jcol3 ~= jcol2&&jcol3~=jcol1
                                        onesInCol3 = find(H(:,jcol3));
                                        for jvertical2 = 1:length(onesInCol3)
                                            irow3 = onesInCol3(jvertical2);
                                            if irow3~=irow2&&irow3~=irow1
                                                onesInRow3 = find(H(irow3,:));
                                                for ilevel3 = 1:length(onesInRow3)
                                                    jcol4 = onesInRow3(ilevel3);
                                                 
                                                    if jcol4 ==jcol1&&jcol4~=jcol3
                                                        cycle6num = cycle6num + 1;
                                                        cycle6(cycle6num,:) = [irow1,jcol1,irow1,jcol2,irow2,jcol2,irow2,jcol3,irow3,jcol3,irow3,jcol1];
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
            end
        end
    end

end
