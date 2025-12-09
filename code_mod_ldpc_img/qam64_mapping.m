function Q=qam64_mapping(num)
    
    switch num
    case 0
        Q = 7;
    case 1
        Q = 5;
    case 3
        Q = 3;
    case 2
        Q = 1;
    case 4
        Q = -7;
    case 5
        Q = -5;
    case 7
        Q = -3;
    case 6
        Q = -1;
    end
end