function [Xsub,Ysub]=lowpass(Xdata,Ydata,Nenough,Hires)

    if nargin<4
        Hires = 0;
    end;
    
    Xsub = [];
    Ysub = [];

    n=length(Xdata);
    
    if (n==0)
        return;
    end;
    
    Nfilt = round(2*n/Nenough);
    if Nfilt<=1
        Xsub = Xdata;
        Ysub = Ydata;
        return;
    elseif Nfilt<=n
        b = zeros([1 Nfilt]);
        pt = pascal(Nfilt);
        for i=1:Nfilt
            i_1 = i-1;
            b(i) = pt(Nfilt-i_1,1+i_1);
        end;
        b=b/sum(b);
    else
        Xsub = sum(Xdata)/n;
        Ysub = sum(Ydata)/n;
        return;
    end;

    N=length(Ydata);
    Xtmp=zeros([1 3*N]);
    Xtmp(N+1:2*N)=Xdata(1:N);
    Ytmp=zeros([1 3*N]);
    Ytmp(N+1:2*N)=Ydata(1:N);
    for i=1:N
        Xtmp(N-i+1)=2*Xdata(1)-Xdata(i);
        Xtmp(2*N+i)=2*Xdata(N)-Xdata(N-i+1);
%         Ytmp(N-i+1)=Ydata(i);
%         Ytmp(2*N+i)=Ydata(N-i+1);
    end;
    Ytmp(2*N+1:3*N) = Ytmp(2*N);
    Ytmp(1:N) = Ytmp(N+1);
%    Ytmp = interp1(Xdata,Ydata,Xtmp,'nearest','extrap');
%     plot(Xdata,Ydata,'o');
%     hold on;
%     plot(Xtmp,Ytmp,'-');
%     hold off;
    
    Ytmp2=filtfilt(b,1,Ytmp);
    
    if Hires
        Xsub = Xtmp(N+Nfilt:2*N-Nfilt);
        Ysub = Ytmp2(N+Nfilt:2*N-Nfilt);
%         Xsub = Xtmp(N+1:2*N);
%         Ysub = Ytmp2(N+1:2*N);
    else
        p=0;
        Xfilt = [];
        Yfilt = [];
        iprog = 1/Nenough;
        idx = 1;
        idx1 = N + round(-Nfilt/2);
        idx2 = idx1 + Nfilt-1;
        while idx2<3*N
            Xfilt(idx) = sum(Xtmp(idx1:idx2).*b(1:Nfilt));
            Yfilt(idx) = sum(Ytmp2(idx1:idx2).*b(1:Nfilt));
            idx=idx+1;

            np = min(100,round(100*(idx1-N)*iprog));
            if np>p
                waitbar(np/100);
            end;
            
            idx1 = N + round((idx-1)*Nfilt/2);
            idx2 = idx1 + Nfilt-1;
            
            if (idx1>2*N)
                break;
            end;
        end;
        
        idx1 = N + Nfilt;
        idx2 = 2*N - Nfilt;
        x1 = Xtmp(idx1);
        x2 = Xtmp(idx2);
        xstp = (x2-x1)/(Nenough-1);
        Xsub = [x1:xstp:x2];
        Ysub = interp1(Xfilt,Yfilt,Xsub,'linear');
    end;
    

function y = filtfilt(b,a,x)
%FILTFILT Zero-phase forward and reverse digital filtering.

    error(nargchk(3,3,nargin))
    if (isempty(b) || isempty(a) || isempty(x))
        y = [];
        return
    end

    [m,n] = size(x);
    if (n>1) && (m>1)
        y = x;
        for i=1:n  % loop over columns
           y(:,i) = filtfilt(b,a,x(:,i));
        end
        return
        % error('Only works for vector input.')
    end
    if m==1
        x = x(:);   % convert row to column
    end
    len = size(x,1);   % length of input
    b = b(:).';
    a = a(:).';
    nb = length(b);
    na = length(a);
    nfilt = max(nb,na);

    nfact = 3*(nfilt-1);  % length of edge transients

    if (len<=nfact),    % input data too short!
        error('Data must have length more than 3 times filter order.');
    end

% set up filter's initial conditions to remove dc offset problems at the 
% beginning and end of the sequence
    if nb < nfilt, b(nfilt)=0; end   % zero-pad if necessary
    if na < nfilt, a(nfilt)=0; end
% use sparse matrix to solve system of linear equations for initial conditions
% zi are the steady-state states of the filter b(z)/a(z) in the state-space 
% implementation of the 'filter' command.
    rows = [1:nfilt-1  2:nfilt-1  1:nfilt-2];
    cols = [ones(1,nfilt-1) 2:nfilt-1  2:nfilt-1];
    data = [1+a(2) a(3:nfilt) ones(1,nfilt-2)  -ones(1,nfilt-2)];
    sp = sparse(rows,cols,data);
    zi = sp \ ( b(2:nfilt).' - a(2:nfilt).'*b(1) );
% non-sparse:
% zi = ( eye(nfilt-1) - [-a(2:nfilt).' [eye(nfilt-2); zeros(1,nfilt-2)]] ) \ ...
%      ( b(2:nfilt).' - a(2:nfilt).'*b(1) );

% Extrapolate beginning and end of data sequence using a "reflection
% method".  Slopes of original and extrapolated sequences match at
% the end points.
% This reduces end effects.
    y = [2*x(1)-x((nfact+1):-1:2);x;2*x(len)-x((len-1):-1:len-nfact)];

% filter, reverse data, filter again, and reverse data again
    y = filter(b,a,y,zi*y(1));
    y = y(length(y):-1:1);
    y = filter(b,a,y,zi*y(1));
    y = y(length(y):-1:1);

% remove extrapolated pieces of y
    y([1:nfact len+nfact+(1:nfact)]) = [];

    if m == 1
        y = y.';   % convert back to row if necessary
    end
