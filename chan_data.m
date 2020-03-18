classdef chan_data<handle

    properties %(SetAccess = private)
        data=[nan nan];
    end

    methods
        function obj = chan_data
        end
        
        function N=count(obj)
            N = length(obj.data);

            if N>0
              if isnan(obj.data(1,1))
                N = 0;
              end;
            end;
        end;
        
        function obj = clear(obj)
            obj.data = [nan nan];
        end;
        
        function X = getX(obj,idx)
            X = obj.data(idx,1);
        end;
        
        function X = getY(obj,idx)
            X = obj.data(idx,2);
        end;
        
        function X = getXs(obj)
            X = obj.data(:,1);
        end;
        
        function Y = getYs(obj)
            Y = obj.data(:,2);
        end;
        
        function [Xmin,Xmax] = getXrang(obj)
            Xmin = min(obj.getXs());
            Xmax = max(obj.getXs());
        end;
        
        function [Ymin,Ymax] = getYrang(obj)
            Ymin = min(obj.getYs());
            Ymax = max(obj.getYs());
        end;
        
        function copyTo(obj,obj_to)
            obj_to.data = obj.data;
        end;
        
        function obj = assign(obj,X,Y)
            Nx = length(X);
            Ny = length(Y);
            
            if (Nx~=Ny) || (Nx==0) || (Ny==0)
                return;
            end;
            
            obj.clear();
            obj.data = zeros(Nx,2);
            obj.data(1:Nx,1) = X(1:Nx);
            obj.data(1:Nx,2) = Y(1:Nx);
        end;
        
        function dobj = deriv(obj)
            dobj = chan_data();
            
            X = obj.getXs();
            N = length(X);
            if N<2
                return;
            end;

            dX = X(2)-X(1);
            if dX==0
                return;
            end;
            invdX = 1/(2*dX);

            Y = obj.getYs();
            Yres(1) = (Y(2)-Y(1))/dX;
            Yres(N) = (Y(N)-Y(N-1))/dX;
            for i=2:N-1
                Yres(i) = (Y(i+1)-Y(i-1))*invdX;
            end;
            
            dobj.assign(X,Yres);
        end;

        function [x,y,idx] = findY(obj,xx)
            x = 0;
            y = 0;
            idx = 0;
            
            if (obj.count()==0) || isnan(xx)
                return;
            end;
            
            Xs = obj.getXs();
%             xmin = min(Xs);
%             xmax = max(Xs);
%             if (xx<xmin) || (xx>xmax)
%                 return;
%             end;
            
            tmpdif = abs(Xs-xx);
            [tmp,idx] = min(tmpdif);
            x = obj.getX(idx);
            y = obj.getY(idx);
        end;
    end
    
    methods(Static)
        function show_chans( handles )

            global ChanData Selection;

            plot(handles.axChanAB,[-1 1],[-1 1],'w.','MarkerSize',0.1);

            if ChanData{2}.count()>1
                plot(handles.axChanAB,ChanData{2}.getXs(),ChanData{2}.getYs(),'b-','LineWidth',6);
                hold(handles.axChanAB,'on');
            end;
            if ChanData{1}.count()>1
                plot(handles.axChanAB,ChanData{1}.getXs(),ChanData{1}.getYs(),'r-','LineWidth',2);
                hold(handles.axChanAB,'on');
            end;

            if get(handles.cbSelectOn,'Value')
                plot(handles.axChanAB,Selection(:,1),Selection(:,2),'ko','MarkerSize',11,'MarkerFaceColor','y');
                for i=1:4
                     if ~isnan(Selection(i,1))
                        text(Selection(i,1),Selection(i,2),num2str(i),'Parent',handles.axChanAB,'FontSize',8,'HorizontalAlignment','Center');
                     end;
                end;
            end;

            xl = get(handles.axChanAB,'XLim');
            set(handles.axChanAB,'XTick',linspace(xl(1),xl(2),5));
            yl = get(handles.axChanAB,'YLim');
            set(handles.axChanAB,'YTick',linspace(yl(1),yl(2),5));

            set(handles.axChanAB,'Color',[0.8,0.8,0.8]);
            hold(handles.axChanAB,'off');

            plot(handles.axChanRes,[-1 1],[-1 1],'w.','MarkerSize',0.1);

            Xf = [];
            if ChanData{4}.count()>1
                Xf = ChanData{4}.getXs();
                Yf = ChanData{4}.getYs();
                minXf = min(Xf);
                maxXf = max(Xf);
            end;
            if ChanData{3}.count()>1
                if isempty(Xf)
                    plot(handles.axChanRes,ChanData{3}.getXs(),ChanData{3}.getYs(),'ko-','MarkerSize',6);
                else
                    Xr = ChanData{3}.getXs();
                    Yr = ChanData{3}.getYs();
                    if ~isempty(Xf)
                        Yr = Yr((Xr>=minXf) & (Xr<=maxXf));
                        Xr = Xr((Xr>=minXf) & (Xr<=maxXf));
                    end;
                    plot(handles.axChanRes,Xr,Yr,'ko-','MarkerSize',6);
                end;
                hold(handles.axChanRes,'on');
            end;
            if ChanData{4}.count()>1
                plot(handles.axChanRes,Xf,Yf,'r-','LineWidth',2);
                hold(handles.axChanRes,'on');
                
                global Polyfit;
                xl = get(handles.axChanRes,'XLim');
                yl = get(handles.axChanRes,'YLim');
                if ~isempty(Polyfit.barcoefs)
                    xr = xl(2) - xl(1);
                    yr = yl(2) - yl(1);
                    xc = xl(1) + xr/2;
                    yt = yl(1) + 0.92*yr;
                    text(xc,yt,sprintf('junction area ~ 10^{%d} um^2',round(log10(Polyfit.barcoefs(1)))),'Parent',handles.axChanRes,'FontSize',9,'HorizontalAlignment','Center','Color','k');
                    yt = yl(1) + 0.85*yr;
                    text(xc,yt,sprintf('parallel resistance: %s Ohm',frmnum(Polyfit.barcoefs(2))),'Parent',handles.axChanRes,'FontSize',9,'HorizontalAlignment','Center','Color','k');
                    yt = yl(1) + 0.78*yr;
                    text(xc,yt,sprintf('barrier width: %.3f nm',0.1*Polyfit.barcoefs(3)),'Parent',handles.axChanRes,'FontSize',9,'HorizontalAlignment','Center','Color','k');
                    yt = yl(1) + 0.71*yr;
                    text(xc,yt,sprintf('barrier L-height: %.3f eV',Polyfit.barcoefs(4)),'Parent',handles.axChanRes,'FontSize',9,'HorizontalAlignment','Center','Color','k');
                    yt = yl(1) + 0.64*yr;
                    text(xc,yt,sprintf('barrier R-height: %.3f eV',Polyfit.barcoefs(5)),'Parent',handles.axChanRes,'FontSize',9,'HorizontalAlignment','Center','Color','k');
%                     yt = yl(1) + 0.57*yr;
%                     text(xc,yt,sprintf('adj.R^{2}: %.6f',Polyfit.barcoefs(6)),'Parent',handles.axChanRes,'FontSize',9,'HorizontalAlignment','Center','Color','k');
                end;
            end;

            xl = get(handles.axChanRes,'XLim');
            set(handles.axChanRes,'XTick',linspace(xl(1),xl(2),5));
            yl = get(handles.axChanRes,'YLim');
            set(handles.axChanRes,'YTick',linspace(yl(1),yl(2),5));

            hold(handles.axChanRes,'off');
        end

        function [sorted_data]=sort_rows(data,x_col)
            if nargin<2
                x_col = 1;
            end;
            
            sorted_data=sortrows(data,x_col);
            
            % removes duplicit data in x_col
            N = length(sorted_data(:,x_col));
            x_min = min(sorted_data(:,x_col));
            for i=1:N-1
                if (sorted_data(i,x_col)==sorted_data(i+1,x_col))
                    sorted_data(i,x_col) = x_min-1;
                end;
            end;
            idx=1;
            while (idx<=N)
                if (sorted_data(idx,x_col)<x_min)
                    sorted_data(idx,:) = [];
                    N = length(sorted_data(:,x_col));
                else
                    idx=idx+1;
                end;
            end;
        end;

        function [Xi,Yi] = interp_data(x,y,xmin,xmax,stp,method)
            if nargin<6
                method = 'quick';
            end;
            
            if nargin<5
                xmin = min(x);
                xmax = max(x);
                xrng = xmax-xmin;
                xmin_stp = xrng/10000;
                
                tmp = abs(diff(x));
                ps = prctile(tmp,[5]);
                stp = max(xmin_stp,ps(1));
            end;

            if nargin<3
                xmin = min(x);
                xmax = max(x);
            end;
            
            Xi = [xmin:stp:xmax];
            if strcmp(method,'quick')
                Yi = interp1q(x,y,Xi')';
            else
                Yi = interp1(x,y,Xi,method);
            end;
        end;
    end;
end
