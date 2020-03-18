function [ str ] = frmnum( num,keepE )

    if nargin<2
        keepE = 0;
    end;
    
    tmpE = sprintf('%.3e',num);
    str = strrep(tmpE,'e',' ');
    [a,b] = strread(str,'%f %d');
    
    if keepE
        str = sprintf('%.3fe%d',a,b);
    else
        if b~=0
            str = sprintf('%.3f x 10^{%d}',a,b);
        else
            str = sprintf('%.3f',a);
        end;
    end;
end
