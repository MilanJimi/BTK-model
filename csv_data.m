classdef csv_data<handle

    properties (SetAccess = private)
        data=[];
        start_row=0;
        header={};
        file_name='';
        cols_stat={};
        turns_idx=[];
    end

    methods
        function obj = csv_data
        end
        
        function N=cols_count(obj)
            [m,N] = size(obj.data);
        end;
        
        function N=rows_count(obj)
            [N,m] = size(obj.data);
        end;
        
        function FN=filename(obj)
            FN = obj.file_name;
        end;
        
        function obj=load(obj,file_path)
            idx=0; m=0; n=0;
            
            [tmp,file_name,ext] = fileparts(file_path);
            obj.file_name = strcat(file_name,ext);

            obj.data=[];
            while ((m==0)&&(n==0)&&(idx<100))
                try
                    obj.data=dlmread(file_path,'',idx,0); %od riadku idx a stlpca 0
                    [m,n]=size(obj.data);
                catch 
                    %if (strcmp(lasterror.identifier,'MATLAB:dlmread:FileNotOpened'))
                    %    msgbox('File not found!','Warning','warn','modal');
                    %    return;
                    %end
                    idx=idx+1;
                end;
            end;

            [m,n]=size(obj.data);
            
            obj.turns_idx = [];
            obj.turns_idx(1,1) = 1;
            obj.turns_idx(1,2) = m;
            
            obj.start_row=idx;
            if (idx>=0)
                fid=fopen(file_path,'r');
                for i=1:idx+min(10,m)
                    obj.header{i}=fgetl(fid);
                end;
                fclose(fid);
            end;
        end;
        
        function [X,Xidx]=get_col_data(obj,col_idx,chop_idx)
            X=[]; Xidx=[];
            
            if (rows_count(obj)==0) || (col_idx<1) || (col_idx>cols_count(obj))
                return;
            end;
            
            if (nargin<3)
                fidx = 1;
                lidx = rows_count(obj);
            else
                fidx = obj.turns_idx(chop_idx,1);
                lidx = obj.turns_idx(chop_idx,2);
            end;
            
            Xidx = [fidx:lidx];
            X = obj.data(fidx:lidx,col_idx);
        end;

        function [X,Y]=get_xy_data(obj,x_col,y_col,chop_idx)
            X=[]; Y=[];
            
            if (rows_count(obj)==0) || (x_col<1) || (x_col>cols_count(obj)) || (y_col<1) || (y_col>cols_count(obj))
                return;
            end;
            
            if (nargin<4)
                fidx = 1;
                lidx = rows_count(obj);
            else
                fidx = obj.turns_idx(chop_idx,1);
                lidx = obj.turns_idx(chop_idx,2);
            end;
            
            X = obj.data(fidx:lidx,x_col);
            Y = obj.data(fidx:lidx,y_col);
        end;
        
        function [obj,n_tol,n_min]=chop_data(obj,x_col,Ntol,Nmin,Nmax)
            if rows_count(obj)==0
                return;
            end;
            
            if nargin<3
                Ntol = 10;
                Nmin = 100;
            end;
            if nargin<4
                Nmin = 10*Ntol;
            end;

            X = obj.data(:,x_col);
            N = length(X);
            
            n_tol = min(max(Ntol+1,1), round(N/10));
            n_min = max(Nmin, n_tol);
            n_min2 = max(n_min,2*n_tol);

            obj.turns_idx = [];
            tidx = 1;
            li = 1;
            x_min = X(li);
            x_max = X(li);
            for i=1+n_tol:N
                x_max = max(x_max,X(i-n_tol));
                x_min = min(x_min,X(i-n_tol));
                if (X(i)>x_min) && (X(i)<x_max) 
                    if (i-li-1>n_min2)
                        obj.turns_idx(tidx,1) = min(N,li+n_tol);
                        obj.turns_idx(tidx,2) = max(1,i-n_tol);
                        tidx = tidx+1;
                        li = i-n_tol;
                    else
                        li = i;
                    end;
                    x_min = X(li);
                    x_max = X(li);
                end;
            end;
            if tidx==1
                obj.turns_idx(tidx,1) = 1;
                obj.turns_idx(tidx,2) = N;
            else
                new_idx = obj.turns_idx(tidx-1,2)+2*n_tol;
                if (N-new_idx+1>n_min)
                    obj.turns_idx(tidx,1) = new_idx;
                    obj.turns_idx(tidx,2) = N;
                end;
            end;

            if nargin>=5
                Nturns = obj.turns_count();
%                 [Nturns,tmp]=size(obj.turns_idx);
                for i=1:Nturns
                    Npoints = obj.turns_idx(i,2)-obj.turns_idx(i,1)+1;
                    obj.turns_idx(i,3) = Npoints;
                end;
                [tmp,idx]=sortrows(obj.turns_idx,3);
                if Nturns>Nmax
                  for i=1:Nturns-Nmax
                    obj.turns_idx(idx(i),1) = nan;
                  end;
                end;
                idx=1;
                while idx<=Nturns
                  if isnan(obj.turns_idx(idx,1))
                    obj.turns_idx(idx,:) = [];
                    Nturns=Nturns-1;
                  else
                    idx=idx+1;
                  end;
                end;
            end;
        end;
        
        function N=turns_count(obj)
            [N,tmp]=size(obj.turns_idx);
        end;
        
        function plot_preview(obj,hAxes,x_col,y_col)
            if rows_count(obj)==0
                return;
            end;
            
            if nargin<4
                Y = obj.data(:,x_col);
                X = [1:length(Y)];
            else
                X = obj.data(:,x_col);
                Y = obj.data(:,y_col);
            end;

            plot(hAxes,X,Y,'.');
            obj.set_xy_lims(hAxes,X,Y);
            zoom(hAxes,'off');
            set(hAxes,'XTickLabel','');
            set(hAxes,'YTickLabel','');
        end;
        
        function plot_chop(obj,hAxes,chop_idx,x_col,y_col)
            if rows_count(obj)==0
                return;
            end;
            
            if nargin<5
                [Y,X]=obj.get_col_data(x_col,chop_idx);
            else
                [X,Y]=obj.get_xy_data(x_col,y_col,chop_idx);
            end;

            hold(hAxes,'on');
            plot(hAxes,X,Y,'r.');
%            plot(hAxes,X,Y,'r-','LineWidth',2);
            hold(hAxes,'off');
        end;
        
    end
    
    methods(Static)
        function set_xy_lims(hAxes,X,Y)
            Xmin = min(X); Xmax=max(X); Xrng=Xmax-Xmin;
            Ymin = min(Y); Ymax=max(Y); Yrng=Ymax-Ymin;
            if (Xmin~=Xmax)
                xlim(hAxes,[Xmin-0.05*Xrng Xmax+0.05*Xrng]);
            end;
            if (Ymin~=Ymax)
                ylim(hAxes,[Ymin-0.05*Yrng Ymax+0.05*Yrng]);
            end;
        end;

        function set_x_lims(hAxes,X)
            Xmin = min(X); Xmax=max(X); Xrng=Xmax-Xmin;
            if (Xmin~=Xmax)
                xlim(hAxes,[Xmin-0.05*Xrng Xmax+0.05*Xrng]);
            end;
        end;

        function set_logy_lims(hAxes,Y)
            Ymin = log10(min(Y)); Ymax=log10(max(Y)); Yrng=Ymax-Ymin;
            if (Ymin~=Ymax)
                ylim(hAxes,[10^(Ymin-0.05*Yrng) 10^(Ymax+0.05*Yrng)]);
            end;
        end;
        
        function [stat] = get_col_stat(X)
            N = length(X);

            stat.N = N;
            stat.min = min(X);
            stat.absmin = min(abs(X));
            stat.max = max(X);
            stat.rng = stat.max-stat.min;
            stat.avg = sum(X)/N;
            stat.dev = std(X);

            ps = prctile(X,[5 50 95]);
            stat.prc5 = ps(1);
            stat.med = ps(2);
            stat.prc95 = ps(3);
        end;
        
    end;
        
end
