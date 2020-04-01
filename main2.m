function varargout = main2(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @main2_OpeningFcn, ...
                   'gui_OutputFcn',  @main2_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


function main2_OpeningFcn(hObject, eventdata, handles, varargin)
    % Choose default command line output for main2
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);

    global ID_D1 ID_D2 ID_W ID_Z1 ID_Z2 ID_G1 ID_G2 ID_P ID_PD;
    
    ID_D1 = 1;
    ID_Z1 = 2;
    ID_G1 = 3;
    ID_D2 = 4;
    ID_Z2 = 5;
    ID_G2 = 6;
    ID_W  = 7;
    ID_P = 8;
    ID_PD = 9;
    
    global ARR_COLOR BG_COLOR;
    ARR_COLOR = [0.5 0.5 0.5];
    BG_COLOR = [0.941 0.941 0.941];
    
    x=[0 1];
    y=[0 1];
%     rectangle('position',[0.40 0.29 0.10 0.20],'edgecolor',ARR_COLOR); % A+,-,x,:B
    drawArrow(handles.bDataToChanA, handles.pChanAB, 'top');
    drawArrow(handles.bDataToChanB, handles.pChanAB, 'top');
    drawArrow(handles.bResToChanA, handles.pChanAB, 'right');
    drawArrow(handles.bFitToChanB, handles.pChanAB, 'right');
    drawArrow(handles.bAdivB, handles.pChanRes, 'left');
    drawArrow(handles.bAmulB, handles.pChanRes, 'left');
    drawArrow(handles.bAsubB, handles.pChanRes, 'left');
    drawArrow(handles.bAaddB, handles.pChanRes, 'left');

    axes(handles.axPreview);
    set(gca,'Color','w');
    set(gca,'XTickLabel','');
    set(gca,'YTickLabel','');
    
    % centralizuj hlavne okno
    res=get(0,'screensize');
    pos=get(handles.mainFigure,'Position');
    set(handles.mainFigure,'Position',[0.5*(res(3)-pos(3)),0.5*(res(4)-pos(4)),pos(3),pos(4)]);

%     global modelAxes;
%     modelAxes = handles.axChanRes;
    
    
function mainFigure_CreateFcn(hObject, eventdata, handles)

    global maxN ChopN SelectN Selection Lists UndoData;
    global DataFile ChanData BTKmodel BTKparams btk_hwnd Polyfit;
    
    BTKmodel = 0;
    BTKparams.DGZW = [5 0 0 0 0 0 0 0 5];
    BTKparams.T = 10;
    BTKparams.R2 = 0;
    BTKparams.N = 100;
    BTKparams.Erng = 20;
    Polyfit.x0 = 0;
    Polyfit.coefs1 = [];
    Polyfit.coefs2 = [];
    Polyfit.barcoefs = [];
    
    btk_hwnd = 0;
    DataFile = 0;
    Lists = {};
    SelectN = 1;
    maxN = 10000;
    ChopN = [1 1];
    Selection = [nan nan;nan nan;nan nan;nan nan];
    ChanData = {};
    UndoData = {};
    for i=1:4
        ChanData{i} = chan_data();
        UndoData{i} = chan_data();
    end;

    
function [in_box,mx,my,mbut] = mouseInAxes(hObject,hAxes)

    pos=get(hObject,'CurrentPoint'); 
    x=pos(1);
    y=pos(2);
    box=get(hAxes,'Position'); 
    l=box(1);
    t=box(2); 
    w=box(3);
    h=box(4);
    in_box = (x>l-10) && (x<l+w+10) && (y>t-10) && (y<t+h+10);
    
    mx = 0; my = 0; mbut = '';
    
    if in_box>0
        xlim = get(hAxes,'XLim');
        ylim = get(hAxes,'YLim');
        ww = xlim(2)-xlim(1);
        hh = ylim(2)-ylim(1);
        mx = ww*(x-l)/w + xlim(1);
        my = hh*(y-t)/h + ylim(1);
        mbut = get(hObject,'SelectionType');
    end;
    

function [yy,idx,x]=findPoint(ch_id,xx)

    global ChanData;
    
    [x,yy,idx] = ChanData{ch_id}.findY(xx);
    

function mainFigure_WindowButtonDownFcn(hObject, eventdata, handles)

    global Selection SelectN;
    
    if ~get(handles.cbSelectOn,'Value')
        return;
    end;

    [in_box,mx,my] = mouseInAxes(hObject,handles.axChanAB);
    
    if (in_box) && ~channelIsEmpty(1)
        [yy,idx,x] = findPoint(1,mx);
        
        if SelectN<=4
            Selection(SelectN,:) = [x yy];
        
            if (SelectN<4) && isnan(Selection(4,1))
                SelectN = SelectN+1;
            end;
            setSelectN(handles,SelectN);
        else
        end;
        
        chan_data.show_chans(handles);
    end;
    

function mainFigure_WindowButtonMotionFcn(hObject, eventdata, handles)

    [in_box,mx,my] = mouseInAxes(hObject,handles.axChanAB);

    if ~get(handles.cbCoordOn,'Value')
        set(handles.lX,'Visible','off');
        set(handles.lY,'Visible','off');
    end;
        
    if (in_box) 
        if get(handles.cbCoordOn,'Value')
            set(handles.lX,'Visible','on');
            set(handles.lY,'Visible','on');
            set(handles.lX,'String',sprintf('X: %s',frmnum(mx)));
            set(handles.lY,'String',sprintf('Y: %s',frmnum(my)));
        end;
    end;

    
function setSelectN(handles,val)

    global SelectN;
    
    SelectN = val;
    set(handles.lSelectN,'String',num2str(val));
    
    
function mainFigure_KeyReleaseFcn(hObject, eventdata, handles)

    if ~get(handles.cbSelectOn,'Value')
        return;
    end;

    key = char(get(hObject,'CurrentKey'));
    
    for i=1:4
        if strcmp(key,num2str(i)) || strcmp(key,strcat('numpad',num2str(i)))
            setSelectN(handles,i);
        end;
    end;
    
    
function mainFigure_WindowKeyPressFcn(hObject, eventdata, handles)

    mainFigure_KeyReleaseFcn(hObject, eventdata, handles)
    
    
function varargout = main2_OutputFcn(hObject, eventdata, handles) 

    varargout{1} = handles.output;


function drawArrow(hButton, hPanel, PanelSide);

    global ARR_COLOR;
    
    fig_pos = get(gcf,'Position');
    pan_pos = get(hPanel,'Position');
    fig_wid = fig_pos(3);
    fig_hig = fig_pos(4);
    but_pos = get(hButton,'Position');
    arr_x1 = (but_pos(1)+0.5*but_pos(3))/fig_wid;
    arr_y1 = (but_pos(2)+0.5*but_pos(3))/fig_hig;
    arr_x2 = arr_x1;
    arr_y2 = arr_y1;
    
    if strcmp(PanelSide,'top')
        arr_y2 = (pan_pos(2)+pan_pos(4))/fig_hig;
    elseif strcmp(PanelSide,'bottom')
        arr_y2 = (pan_pos(2)-2)/fig_hig;
    elseif strcmp(PanelSide,'left')
        arr_x2 = (pan_pos(1)-2)/fig_wid;
    else
        arr_x2 = (pan_pos(1)+pan_pos(3))/fig_wid;
    end;
    
    ARR=annotation('arrow',[arr_x1 arr_x2],[arr_y1 arr_y2],'color',ARR_COLOR);

    
function bBrowse_Callback(hObject, eventdata, handles)

    global LOCAL_DIR Lists;
    
    if isempty('LOCAL_DIR')
        LOCAL_DIR = '..';
    end;

    tmpdir = uigetdir(LOCAL_DIR,'Pick a directory');
    
    if (tmpdir==0)
        return;
    else
        LOCAL_DIR = tmpdir;
    end;
        
    files=dir(strcat(LOCAL_DIR,'\*.dat'));

    remain = LOCAL_DIR;
    strs = {};
    idx = 1;
    while length(remain)>1
        [str, remain] = strtok(remain, filesep);
        strs{idx} = str;
        idx = idx + 1;
    end
    set(handles.lDirName,'String',strcat(filesep,strs{length(strs)}));
    
    Lists{1} = strings(handles.lbFiles);
    for i=1:length(files)
        Lists{1}.add_string(files(i).name);
    end;
    Lists{1}.sort();
    Lists{1}.display();
    
    if Lists{1}.count()>0
        lbFiles_Callback(hObject, eventdata, handles);
    end;


function lbFiles_Callback(hObject, eventdata, handles)

    global LOCAL_DIR Lists DataFile;
    
    idx=get(hObject,'Value');
    FN=Lists{1}.get_string(idx);
    fpath=strcat(LOCAL_DIR,'\',FN);
    
    DataFile=csv_data();
    DataFile.load(fpath);
    
    first_file=(length(Lists)==1);
    
    if first_file
        Lists{2} = strings(handles.lbXCol);
        Lists{3} = strings(handles.lbYCol);
%        Lists{4} = strings(handles.lbChops);
    end;

    Lists{2}.clear();
    Lists{3}.clear();
    for i=1:DataFile.cols_count()
        Lists{2}.add_string(num2str(i));
        Lists{3}.add_string(num2str(i));
    end;
    Lists{2}.display();
    Lists{3}.display();
    if first_file
        Lists{3}.select(2);
    end;
    
    set(handles.tPointsNum,'String',sprintf('Points: %d',DataFile.rows_count()));
    
    setChopN(handles,1,1);
    lbChops_Callback(hObject, eventdata, handles);
    
function lbFiles_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function sChopN_Callback(hObject, eventdata, handles)

    ch_idx = round(get(handles.sChopN,'Value'));
    setChopN(handles,ch_idx);
    lbChops_Callback(hObject, eventdata, handles);
    
    
function sChopN_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor',[.9 .9 .9]);

    
function setChopN(handles,N,Nmax)

    global ChopN;
    
    if nargin<3
        Nmax = ChopN(2);
    end;
    ChopN = [N Nmax];
%     set(handles.sChopN,'Min',1);
    set(handles.sChopN,'Min',min(Nmax-1,1));
    set(handles.sChopN,'Max',Nmax);
    set(handles.sChopN,'SliderStep',[1/Nmax 1/Nmax]);
    set(handles.sChopN,'Value',N);
    set(handles.tChopN,'String',sprintf('%d/%d',N,Nmax));
    
    if Nmax>1
        set(handles.sChopN,'Enable','on');
        set(handles.sChopN,'Visible','on');
        set(handles.lChopN,'Visible','on');
        set(handles.tChopN,'Visible','on');
    else
        set(handles.sChopN,'Visible','off');
        set(handles.lChopN,'Visible','off');
        set(handles.tChopN,'Visible','off');
    end;
    

function bChop_Callback(hObject, eventdata, handles)

    global DataFile Lists;
    
    Ntol = round(str2num(get(handles.eChopTol,'String')));
    Nmin = round(str2num(get(handles.eMinLen,'String')));
    DataFile.chop_data(Lists{2}.get_selected,Ntol,Nmin);
    
    Lists{4}.clear();
    [N,m]=size(DataFile.turns_idx);
    for i=1:N
        Lists{4}.add_string(num2str(i));
    end;
    Lists{4}.display();
    Lists{4}.select(1);

    lbChops_Callback(hObject, eventdata, handles);
    
    
function eChopTol_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');
   
function eMinLen_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');

function sChopTol_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor',[.9 .9 .9]);


function lbXCol_Callback(hObject, eventdata, handles)

    lbChops_Callback(hObject, eventdata, handles);
    
    
function lbXCol_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function lbYCol_Callback(hObject, eventdata, handles)

    lbChops_Callback(hObject, eventdata, handles);
    
function lbYCol_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function lbChops_Callback(hObject, eventdata, handles)

    global DataFile Lists ChopN;
    
    DataFile.plot_preview(handles.axPreview,Lists{2}.get_selected,Lists{3}.get_selected);
    DataFile.plot_chop(handles.axPreview,ChopN,Lists{2}.get_selected,Lists{3}.get_selected);
    
function lbChops_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');

    
function bDataToChanA_Callback(hObject, eventdata, handles)

    global DataFile Lists ChanData ChopN maxN;
    
    if (DataFile==0)
        return;
    end;
    
    [X,Y] = DataFile.get_xy_data(Lists{2}.get_selected,Lists{3}.get_selected,ChopN);
    
    if length(X)>maxN
        [XsYs] = chan_data.sort_rows([X(1:maxN) Y(1:maxN)]);
    else
        [XsYs] = chan_data.sort_rows([X Y]);
    end;
    
    [Xi,Yi] = chan_data.interp_data(XsYs(:,1),XsYs(:,2));
    
    backupChans(handles);
    ChanData{1}.assign(Xi,Yi);
    turnOffZoom(handles);
    chan_data.show_chans(handles);
    
    
function bDataToChanB_Callback(hObject, eventdata, handles)

    global DataFile Lists ChanData ChopN;
    
    if (DataFile==0)
        return;
    end;
    
    [X,Y] = DataFile.get_xy_data(Lists{2}.get_selected,Lists{3}.get_selected,ChopN);
    [XsYs] = chan_data.sort_rows([X Y]);
    [Xi,Yi] = chan_data.interp_data(XsYs(:,1),XsYs(:,2));

    backupChans(handles);
    ChanData{2}.assign(Xi,Yi);
    turnOffZoom(handles);
    chan_data.show_chans(handles);

    
function bClearA_Callback(hObject, eventdata, handles)

    global ChanData;
    
    backupChans(handles);
    ChanData{1}.clear();
    chan_data.show_chans(handles);

    
function bClearB_Callback(hObject, eventdata, handles)

    global ChanData;
    
    backupChans(handles);
    ChanData{2}.clear();
    chan_data.show_chans(handles);

    
function bClearR_Callback(hObject, eventdata, handles)

    global ChanData;
    
    backupChans(handles);
    ChanData{3}.clear();
    chan_data.show_chans(handles);

    
function bClearFit_Callback(hObject, eventdata, handles)

    global ChanData;
    
    backupChans(handles);
    ChanData{4}.clear();
    chan_data.show_chans(handles);

    
function bClearAB_Callback(hObject, eventdata, handles)

    global ChanData;
    
    backupChans(handles);
    ChanData{1}.clear();
    ChanData{2}.clear();
    chan_data.show_chans(handles);


function bClearRes_Callback(hObject, eventdata, handles)

    global ChanData;
    
    backupChans(handles);
    ChanData{3}.clear();
    ChanData{4}.clear();
    chan_data.show_chans(handles);
    

function bResToChanA_Callback(hObject, eventdata, handles)

    global ChanData;
    
    backupChans(handles);
    ChanData{3}.copyTo(ChanData{1});
    turnOffZoom(handles);
    chan_data.show_chans(handles);

    
function bFitToChanB_Callback(hObject, eventdata, handles)

    global ChanData;
    
    backupChans(handles);
    ChanData{4}.copyTo(ChanData{2});
    turnOffZoom(handles);
    chan_data.show_chans(handles);

    
function bAaddB_Callback(hObject, eventdata, handles)

    doBinary(handles,1);
    chan_data.show_chans(handles);


function bAsubB_Callback(hObject, eventdata, handles)

    doBinary(handles,2);
    chan_data.show_chans(handles);
    

function bAmulB_Callback(hObject, eventdata, handles)

    doBinary(handles,3);
    chan_data.show_chans(handles);


function bAdivB_Callback(hObject, eventdata, handles)

    doBinary(handles,4);
    chan_data.show_chans(handles);
    

function bFileInfo_Callback(hObject, eventdata, handles)

    global DataFile;
    
    if (DataFile~=0)
        h=file_info(handles);
        set(h,'WindowStyle','modal');
        uiwait(h);
        
        Nturns = DataFile.turns_count();
        if Nturns>1
            setChopN(handles,1,Nturns);
            lbChops_Callback(hObject, eventdata, handles);
        end;
    else
        msgbox('Select a file!','Warning','warn','modal');
    end;
    

function [val,ok]=getValue(hEdit)

    val = str2num(get(hEdit,'String'));
    if length(val)==0
        msgbox('Type a number!','Warning','warn','modal');
        ok = 0;
        return;
    end;
    ok = 1;
    
    
function setValue(hEdit,val)

    set(hEdit,'String',frmnum(val,1));
%    set(hEdit,'String',sprintf('%.3e',val));
    
    
function [ok]=doUnitary(handles,xy_id,op_id,val)

    global ChanData;
    
    ok = 0;
    
    if channelIsEmpty(1)
        return;
    end;

    backupChans(handles);
    
    ch_id = getActiveOutputChannel(handles);
    if (ch_id~=1)
        ChanData{1}.copyTo(ChanData{ch_id});
    end;
    
    if op_id==1
        ChanData{ch_id}.data(:,xy_id) = ChanData{1}.data(:,xy_id) + val;
    elseif op_id==2
        ChanData{ch_id}.data(:,xy_id) = ChanData{1}.data(:,xy_id)*val;
    elseif op_id==3
        ChanData{ch_id}.data(:,xy_id) = ChanData{1}.data(:,xy_id)/val;
    elseif op_id==4
        ChanData{ch_id}.data(:,xy_id) = 1./ChanData{1}.data(:,xy_id);
    end;
    
    ok = 1;

    
function doBinary(handles,op_id)

    global ChanData;
    
    if channelIsEmpty(1) || channelIsEmpty(2)
        return;
    end;
    
    X1 = ChanData{1}.getXs();
    Y1 = ChanData{1}.getYs();
    X2 = ChanData{2}.getXs();
    Y2 = ChanData{2}.getYs();
    
    Amin=min(X1); Bmin=min(X2); Rmin=max(Amin,Bmin);
    Amax=max(X1); Bmax=max(X2); Rmax=min(Amax,Bmax);
    AX = X1((X1>=Rmin)&(X1<=Rmax));
    AY = Y1((X1>=Rmin)&(X1<=Rmax));
    BX = X2((X2>=Rmin)&(X2<=Rmax));
    BY = Y2((X2>=Rmin)&(X2<=Rmax));

    Na=length(AX);
    Nb=length(BX);
    
    if (Na==0) || (Nb==0)
        msgbox('Channels A & B must have some common range!','Warning','warn','modal');
        return;
    end;
    
    backupChans(handles);
    
    ChanData{3}.clear();
    
    Nda = Na; Ndb = Nb;
    if get(handles.cbHiRes,'Value')
        Nda = Nb; Ndb = Na;
    end;
    
    if Nda<Ndb
        N = Na;
        ChanData{3}.data(1:N,1) = AX;
        tmpY = interp1(BX,BY,AX,'linear','extrap');
        BY = tmpY;
    else
        N = Nb;
        ChanData{3}.data(1:N,1) = BX;
        tmpY = interp1(AX,AY,BX,'linear','extrap');
        AY = tmpY;
    end;
    
    if op_id==1
        ChanData{3}.data(1:N,2) = AY(1:N) + BY(1:N);
    elseif op_id==2
        ChanData{3}.data(1:N,2) = AY(1:N) - BY(1:N);
    elseif op_id==3
        ChanData{3}.data(1:N,2) = AY(1:N).*BY(1:N);
    elseif op_id==4
        ChanData{3}.data(1:N,2) = AY(1:N)./BY(1:N);
    end;
    
    
function [ch_id]=getActiveOutputChannel(handles)

    ch_id = get(handles.rbResToA,'Value') + 2*get(handles.rbResToB,'Value') + 3*get(handles.rbResToRes,'Value');

    
function [ax_id]=getActiveAxis(handles)

    ax_id = get(handles.rbUnitX,'Value') + 2*get(handles.rbUnitY,'Value');
    
    
function bUnitAdd_Callback(hObject, eventdata, handles)

    [val,ok] = getValue(handles.eValue);
    if ok 
        ax_id = getActiveAxis(handles);
        ok = doUnitary(handles,ax_id,1,val);
        if ok
            chan_data.show_chans(handles);
        end;
    end;


function bUnitSub_Callback(hObject, eventdata, handles)

    [val,ok] = getValue(handles.eValue);
    if ok 
        ax_id = getActiveAxis(handles);
        ok = doUnitary(handles,ax_id,1,-val);
        if ok
            chan_data.show_chans(handles);
        end;
    end;
    
    
function bUnitMul_Callback(hObject, eventdata, handles)

    [val,ok]=getValue(handles.eValue);
    if ok 
        ax_id = getActiveAxis(handles);
        ok = doUnitary(handles,ax_id,2,val);
        if ok
            chan_data.show_chans(handles);
        end;
    end;


function bUnitDiv_Callback(hObject, eventdata, handles)

    [val,ok]=getValue(handles.eValue);
    if ok 
        ax_id = getActiveAxis(handles);
        ok = doUnitary(handles,ax_id,3,val);
        if ok
            chan_data.show_chans(handles);
        end;
    end;
    

function bUnitPM_Callback(hObject, eventdata, handles)

    ax_id = getActiveAxis(handles);
    ok = doUnitary(handles,ax_id,2,-1);
    if ok
        chan_data.show_chans(handles);
    end;

    
function bUnitInv_Callback(hObject, eventdata, handles)

    ax_id = getActiveAxis(handles);
    ok = doUnitary(handles,ax_id,4);
    if ok
        chan_data.show_chans(handles);
    end;

    
function eValue_Callback(hObject, eventdata, handles)

function eValue_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function [empty]=channelIsEmpty(ch_id)

    global ChanData;
    
    empty = ChanData{ch_id}.count()==0;
    

function cbCoordOn_Callback(hObject, eventdata, handles)

    mainFigure_WindowButtonMotionFcn(handles.mainFigure, eventdata, handles)


function cbZoomOn_Callback(hObject, eventdata, handles)

    if get(handles.cbZoomOn,'Value')
        zoom(handles.axChanAB,'on');
        set(handles.cbSelectOn,'Enable','off');
    else
        turnOffZoom(handles);
    end;
    chan_data.show_chans(handles);


function turnOffZoom(handles)

    set(handles.cbZoomOn,'Value',0);
    zoom(handles.axChanAB,'off');
    set(handles.cbSelectOn,'Enable','on');
        
    
function cbSelectOn_Callback(hObject, eventdata, handles)

    global Selection;

    if get(handles.cbSelectOn,'Value')
        turnOffZoom(handles);
        set(handles.lSelectN,'Visible','on');
        set(handles.bTrim,'Enable','on');
        setSelectN(handles,1);
    else
        set(handles.lSelectN,'Visible','off');
        set(handles.bTrim,'Enable','off');
        Selection=[nan nan;nan nan;nan nan;nan nan];
    end;
    
    chan_data.show_chans(handles);


function bAswapB_Callback(hObject, eventdata, handles)

    global ChanData;
    
    backupChans(handles);
    
    tmp = ChanData{1};
    ChanData{1} = ChanData{2};
    ChanData{2} = tmp;
    
    chan_data.show_chans(handles);
    

function bTrim_Callback(hObject, eventdata, handles)

    global ChanData Selection;
    
    if channelIsEmpty(1)
        return;
    end;
    
    for i=1:4
        [yy,idx(i)]=findPoint(1,Selection(i,1));
    end;
    
    if ~idx(1) || ~idx(2)
        return;
    end;
    
    idx = sort(idx,'descend');
    
    backupChans(handles);
    
    och_id = getActiveOutputChannel(handles);
    
    if ~idx(3) || ~idx(4)
        idx1 = idx(2); idx2 = idx(1); 
        N = idx2-idx1+1;
        tmp = ChanData{1}.data(idx1:idx2,1:2);
    else
        idx1 = idx(4); idx2 = idx(3); idx3 = idx(2); idx4 = idx(1); 
        N1 = idx2-idx1+1;
        tmp1 = ChanData{1}.data(idx1:idx2,1:2);
        N2 = idx4-idx3+1;
        tmp2 = ChanData{1}.data(idx3:idx4,1:2);
        tmp = [tmp1;tmp2];
    end;
    
    ChanData{och_id}.assign(tmp(:,1),tmp(:,2));
    
    chan_data.show_chans(handles);

    
function bDeriv_Callback(hObject, eventdata, handles)

    global ChanData;
    
    backupChans(handles);
    och_id = getActiveOutputChannel(handles);
    ChanData{1}.deriv().copyTo(ChanData{och_id});
    chan_data.show_chans(handles);
    
    
function bFilter_Callback(hObject, eventdata, handles)

    global ChanData;
    
    [Xmin,Xmax,Xstp]=eFilter_Callback(hObject, eventdata, handles);
    if Xstp==0
        return;
    end;
    
    Xrng = Xmax-Xmin;
    N = round(Xrng/Xstp);
    
    h=waitbar(0,'Processing ..','Name','Low pass filter');
    [tmpX,tmpY] = lowpass(ChanData{1}.getXs(), ChanData{1}.getYs(), N, get(handles.cbHiresLP,'Value'));
    delete(h);
%    return;
    
    backupChans(handles);
    och_id = getActiveOutputChannel(handles);
    ChanData{och_id}.assign(tmpX,tmpY);
    chan_data.show_chans(handles);


function sFilter_Callback(hObject, eventdata, handles)

    setValue(handles.eFilter,get(handles.sFilter,'Value'));
    
function sFilter_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor',[.9 .9 .9]);
    
    
function [Xmin,Xmax,Xstp]=eFilter_Callback(hObject, eventdata, handles)

    global ChanData;
    
    Xmin = 0;
    Xmax = 0;
    Xstp = 0;

    [val,ok]=getValue(handles.eFilter);
    if ~ok || channelIsEmpty(1)
        return;
    end;
    
    Npoints = ChanData{1}.count();
    Xs = ChanData{1}.getXs();
    Xmin = min(Xs);
    Xmax = max(Xs);
    Xrng = Xmax-Xmin;
    Xstp = Xrng/Npoints;
    
    stp_min = Xstp;
    stp_max = Xrng/10;
    
    set(handles.sFilter,'Min',stp_min);
    set(handles.sFilter,'Max',stp_max);

    Xstp = max(stp_min,min(stp_max,val));
    setValue(handles.eFilter,Xstp);
    set(handles.sFilter,'Value',Xstp);
    
function eFilter_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function backupChans(handles)

    global ChanData UndoData;
    
    set(handles.bUndo,'Enable','on');
    
    for i=1:4
        ChanData{i}.copyTo(UndoData{i});
    end;


function bUndo_Callback(hObject, eventdata, handles)

    global ChanData UndoData;
    
    for i=1:4
        UndoData{i}.copyTo(ChanData{i});
    end;
    
    set(handles.bUndo,'Enable','off');
    
    chan_data.show_chans(handles);


function cbHiRes_Callback(hObject, eventdata, handles)


function bPolyFit_Callback(hObject, eventdata, handles)

    global ChanData Polyfit;

    if channelIsEmpty(3)
        return;
    end;
    
    Nord=round(get(handles.sPolyFitN,'Value'));
    
    Xbg = ChanData{3}.getXs();
    Ybg = ChanData{3}.getYs();
    
    Nr = length(Xbg);
    if (Nr<=Nord)
        msgbox('Number of points insufficient for the fit.','Warning','warn','modal');
        return;
    end;
    
    backupChans(handles)
    
    if (Nord==1) && get(handles.cbQlinear,'Value')
        Xbg1 = Xbg(Xbg<=0);
        Ybg1 = Ybg(Xbg<=0);
        coefs1=polyfit(Xbg1,Ybg1,1);
        Xbg2 = Xbg(Xbg>=0);
        Ybg2 = Ybg(Xbg>=0);
        coefs2=polyfit(Xbg2,Ybg2,1);
        x0=(coefs1(2)-coefs2(2))/(coefs2(1)-coefs1(1));
        
        if (x0<min(Xbg)) || (x0>max(Xbg))
            msgbox('Quasi-linear fit failed!','Warning','warn','modal');
            return;
        end;
        
        Xmin = min(Xbg1);
        Xmax = max(Xbg2);
        Xstp = (Xmax-Xmin)/(10*Nr);
        Xf1 = [Xmin:Xstp:x0];
        Xf2 = [x0+Xstp:Xstp:Xmax];
        Yf1 = polyval(coefs1,Xf1);
        Yf2 = polyval(coefs2,Xf2);

        Xf = [Xf1 Xf2];
        Yf = [Yf1 Yf2];
        
        Polyfit.coefs1 = coefs1;
        Polyfit.coefs2 = coefs2;
        Polyfit.x0 = x0;
    else
        coefs = polyfit(Xbg,Ybg,Nord);
        
        Xmin = min(Xbg);
        Xmax = max(Xbg);
        Ymax = max(Ybg);
        Xstp = (Xmax-Xmin)/(10*Nr);
        Xf = [Xmin:Xstp:Xmax];
        Yf = polyval(coefs,Xf);
        
        Polyfit.coefs1 = coefs;
        Polyfit.coefs2 = [];
        Polyfit.barcoefs = [];
        Polyfit.x0 = 0;

        if get(handles.cbBarrierFit,'Value')
            Xs = [Xmin:(Xmax-Xmin)/(10):Xmax];
            Ys = polyval(coefs,Xs);
            Ntry = 9;
            
            if ~get(handles.cbBarrierArea,'Value')
                for i=0:Ntry-1
                    hold(handles.axChanRes,'off');
                    plot(handles.axChanRes,Xbg,Ybg,'ko');
                    hold(handles.axChanRes,'on');
                    if (i>0)
                        plot(handles.axChanRes,Xf,Yf,'g-');
                    end;
                    xl = get(handles.axChanRes,'XLim');
                    yl = get(handles.axChanRes,'YLim');
                    xr = xl(2) - xl(1);
                    yr = yl(2) - yl(1);
                    xc = xl(1) + xr/2;
                    yt = yl(1) + 0.92*yr;
                    if (i+1<9)
                        text(xc,yt,sprintf('estimating junction area .. %d/9',i+1),'Parent',handles.axChanRes,'FontSize',9,'HorizontalAlignment','Center','Color','k');
                    else
                        text(xc,yt,'fitting barrier .. 9/9','Parent',handles.axChanRes,'FontSize',9,'HorizontalAlignment','Center','Color','k');
                    end;
                    drawnow;

                    if Ntry>1
                        Ainit=power(10,-i+3);
                    end;
                    [A(i+1),R(i+1),d(i+1),F1(i+1),F2(i+1),adjR2(i+1),Gfit] = barrierfit(Ainit,Xs,Ys);

                    update=0;
                    if(i==0)
                        bestR2=adjR2(i+1);
                        update=1;
                        Xf = Xs;
                        Yf = Gfit;
                    else
                        if adjR2(i+1)>bestR2
                            bestR2=adjR2(i+1);
                            update=1;
                            Xf = Xs;
                            Yf = Gfit;
                        end;
                    end;
                end;
                hold(handles.axChanRes,'off'); % !!!

                [a,b]=max(adjR2);
                Aum2 = A(b);
            else
                hold(handles.axChanRes,'off');
                plot(handles.axChanRes,Xbg,Ybg,'ko');
                xl = get(handles.axChanRes,'XLim');
                yl = get(handles.axChanRes,'YLim');
                xr = xl(2) - xl(1);
                yr = yl(2) - yl(1);
                xc = xl(1) + xr/2;
                yt = yl(1) + 0.92*yr;
                text(xc,yt,'fitting barrier .. ','Parent',handles.axChanRes,'FontSize',9,'HorizontalAlignment','Center','Color','k');
                drawnow;
                hold(handles.axChanRes,'off'); % !!!
                
                Aum2 = str2num(get(handles.eBarrierArea,'String'));
            end;
            
            Xs = [Xmin:(Xmax-Xmin)/100:Xmax];
            Ys = polyval(coefs,Xs);
            [Af,Rf,df,F1f,F2f,adjR2f,Gfit] = barrierfit(Aum2,Xs,Ys,1);
            
            Polyfit.barcoefs(1) = Af;
            Polyfit.barcoefs(2) = Rf;
            Polyfit.barcoefs(3) = df;
            Polyfit.barcoefs(4) = F1f;
            Polyfit.barcoefs(5) = F2f;
            Polyfit.barcoefs(6) = adjR2f;
            
            Xf = Xs;
            Yf = Gfit;
        end;
    end;
    
    ChanData{4}.assign(Xf,Yf);
    
    chan_data.show_chans(handles);
    
%     if ~isempty(Polyfit.barcoefs)
%         str1 = sprintf('A  = %s um2 (junction area)',frmnum(Polyfit.barcoefs(1)));
%         str2 = sprintf('R  = %s Ohm (parallel resistance)',frmnum(Polyfit.barcoefs(2)));
%         str3 = sprintf('d  = %.3f nm (barrier width)',0.1*Polyfit.barcoefs(3));
%         str4 = sprintf('F1 = %.3f eV (barrier L-height)',Polyfit.barcoefs(4));
%         str5 = sprintf('F2 = %.3f eV (barrier R-height)',Polyfit.barcoefs(5));
%         msgbox({str1,str2,str3,str4,str5},'Barrier parameters','modal');
%     end;


function sPolyFitN_Callback(hObject, eventdata, handles)

    val = get(handles.sPolyFitN,'Value');
    set(handles.tPolyFitN,'String',num2str(val));
    
    if (val==1)
        set(handles.cbQlinear,'Enable','on');
    else
        set(handles.cbQlinear,'Enable','off');
    end;

    if (val==2)
        set(handles.cbBarrierFit,'Enable','on');
        set(handles.cbBarrierArea,'Enable','on');
    else
        set(handles.cbBarrierFit,'Enable','off');
        set(handles.cbBarrierArea,'Enable','off');
    end;
    
function sPolyFitN_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor',[.9 .9 .9]);

    
function cbBarrierArea_Callback(hObject, eventdata, handles)
function cbBarrierFit_Callback(hObject, eventdata, handles)


function rbUnitXY_SelectionChangeFcn(hObject, eventdata, handles)

    if get(handles.rbUnitX,'Value')
        set(handles.bUnitInv,'Enable','off');
    else
        set(handles.bUnitInv,'Enable','on');
    end;

function rbUnitXY_CreateFcn(hObject, eventdata, handles)


function cbQlinear_Callback(hObject, eventdata, handles)


function bAsimB_Callback(hObject, eventdata, handles)

    global ChanData;
    
    if channelIsEmpty(1) || channelIsEmpty(2)
        return;
    end;
    
    ch1=2; ch2=1;
    
    tmpY1 = ChanData{ch1}.getYs();
    tmpY2 = ChanData{ch2}.getYs();
    Amin=min(tmpY1); Amax=max(tmpY1); Arng=Amax-Amin;
    Bmin=min(tmpY2); Bmax=max(tmpY2); Brng=Bmax-Bmin;

    backupChans(handles);

    tmpY1 = tmpY1 - Amin;
    tmpY1 = tmpY1.*(Brng/Arng);
    tmpY1 = tmpY1 + Bmin;
    ChanData{ch1}.data(:,2) = tmpY1;

    chan_data.show_chans(handles);


function cbHiresLP_Callback(hObject, eventdata, handles)

    if get(handles.cbHiresLP,'Value')
        set(handles.eFilter, 'Enable', 'off');
    else
        set(handles.eFilter, 'Enable', 'on');
    end;


function popupmenu1_Callback(hObject, eventdata, handles)
function popupmenu1_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function bBTKMod_Callback(hObject, eventdata, handles)

    global btk_hwnd BTKparams ChanData;
    
    mstr = get(handles.pmPoints,'String');
    idx = round(get(handles.pmPoints,'Value'));
    BTKparams.N = str2num(mstr{idx});

    mstr = get(handles.pmRange,'String');
    idx = round(get(handles.pmRange,'Value'));
    BTKparams.Erng = sscanf(mstr{idx},'%d');
    
    set(handles.bBTKMod,'Enable','off');
    drawnow;
    
    btk_hwnd = btk_interface(handles);
    

function mainFigure_CloseRequestFcn(hObject, eventdata, handles)

    global btk_hwnd;
    
    if btk_hwnd~=0
        delete(btk_hwnd);
        btk_hwnd = 0;
    end;
    
    delete(hObject);
    

function pmRange_Callback(hObject, eventdata, handles)
function pmRange_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function pmPoints_Callback(hObject, eventdata, handles)
function pmPoints_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');
    

function expFN=exportChannel(handles,chan_id)

    global LOCAL_DIR DataFile ChanData;
    
    tmp = '';
    if chan_id==1
        tmp = '.chan_A';
    elseif chan_id==2
        tmp = '.chan_B';
    elseif chan_id==3
        tmp = '.chan_R';
    elseif chan_id==4
        tmp = '.chan_F';
    end;
    
    [path,name,ext] = fileparts(DataFile.filename);
    expFN = strcat(LOCAL_DIR,'\',name,tmp);
    exppath = strcat(expFN,'.txt');
    
    if isempty(tmp)
        return;
    end;

    N = ChanData{chan_id}.count();
    tmp = zeros([N 2]);
    tmp(1:N,1) = ChanData{chan_id}.getXs();
    tmp(1:N,2) = ChanData{chan_id}.getYs();
    
    fid = fopen(exppath,'w');
%     fprintf(fid, hdr);
%     fprintf(fid, '\n');
    fclose(fid);
    
    if N==0
        return;
    end;
    
    save(exppath,'tmp','-ascii','-tabs','-append');
    
    if get(handles.cbUseComma,'Value')
        comma_overwrite(exppath);
    end;

    
function bExport_Callback(hObject, eventdata, handles)

    global DataFile BTKparams Polyfit;
    global ID_D1 ID_D2 ID_W ID_Z1 ID_Z2 ID_G1 ID_G2 ID_P ID_PD;
    
    if (DataFile==0)
        msgbox('Nothing to export!','Warning','warn','modal');
        return;
    end;
    
    FN = exportChannel(handles,0);
    tmp = sprintf('%s.chan_A.txt',FN);
    hnd = progbar(tmp, 'Exporting ..');

    if get(handles.cbExportA,'Value')
        tmp = sprintf('%s.chan_A.txt',FN);
        waitbar(0,hnd,tmp);
        exportChannel(handles,1);
    end;
    pause(0.25);

    if get(handles.cbExportB,'Value')
        tmp = sprintf('%s.chan_B.txt',FN);
        waitbar(0.25,hnd,tmp);
        exportChannel(handles,2);
    end;
    pause(0.25);
    
    if get(handles.cbExportR,'Value')
        tmp = sprintf('%s.chan_R.txt',FN);
        waitbar(0.5,hnd,tmp);
        exportChannel(handles,3);
    end;
    pause(0.25);
    
    if get(handles.cbExportF,'Value')
        tmp = sprintf('%s.chan_F.txt',FN);
        waitbar(0.75,hnd,tmp);
        expFN = exportChannel(handles,4);
        
        if get(handles.cbBTKfit,'Value')
            exppath = sprintf('%s_BTK.txt',expFN);
            fid = fopen(exppath,'w');
            fprintf(fid, 'BTK model parameters\n');
            fprintf(fid, '\n');
            fprintf(fid, 'Temperature:   %.3f K\n', BTKparams.T);
            fprintf(fid, 'Volt range:    %.3f meV \n', BTKparams.Erng);
            fprintf(fid, 'Num.of points: %d \n', BTKparams.N);
            fprintf(fid, 'R-squared:     %.6f \n', BTKparams.R2);
            fprintf(fid, '\n');
            fprintf(fid, 'Weight1: %.3f \n', 1-BTKparams.DGZW(ID_W));
            fprintf(fid, 'Delta1:  %.3f meV\n', BTKparams.DGZW(ID_D1));
            fprintf(fid, 'Zet1:    %.3f \n', BTKparams.DGZW(ID_Z1));
            fprintf(fid, 'Gamma1:  %.3f meV\n', BTKparams.DGZW(ID_G1));
            fprintf(fid, '\n');
            fprintf(fid, 'Weight2: %.3f \n', BTKparams.DGZW(ID_W));
            fprintf(fid, 'Delta2:  %.3f meV\n', BTKparams.DGZW(ID_D2));
            fprintf(fid, 'Zet2:    %.3f \n', BTKparams.DGZW(ID_Z2));
            fprintf(fid, 'Gamma2:  %.3f meV\n', BTKparams.DGZW(ID_G2));
            fprintf(fid, 'Polarization:  %.3f \n', BTKparams.DGZW(ID_P));
            fprintf(fid, 'Polarization gap:  %.3f meV\n', BTKparams.DGZW(ID_PD));
            fclose(fid);
            
            if get(handles.cbUseComma,'Value')
                comma_overwrite(exppath);
            end;
        end;
        
        if get(handles.cbPolynomFit,'Value') && (~isempty(Polyfit.coefs1))
            exppath = sprintf('%s_poly.txt',expFN);
            fid = fopen(exppath,'w');
            
            n = length(Polyfit.coefs1);
            fprintf(fid, 'Polynomial fit parameters\n');
            fprintf(fid, 'Order: %d \n', n-1);
            fprintf(fid, '\n');
            
            if isempty(Polyfit.coefs2)
                tmp = 'f(x) = c0';
                for i=2:n
                    tmp = strcat(tmp,sprintf(' + c%d*x^%d ',i-1,i-1));
                end;
                fprintf(fid, '%s \n',tmp);
                fprintf(fid, '\n');
                for i=1:n
                    fprintf(fid, 'c%d: %e \n', i-1,Polyfit.coefs1(n-i+1));
                end;
                fprintf(fid, '\n');

                if ~isempty(Polyfit.barcoefs)
                    fprintf(fid, 'Trapezoidal barrier fit:\n');
                    fprintf(fid, '------------------------\n');
                    fprintf(fid, 'junction area: %s um^2\n',frmnum(Polyfit.barcoefs(1)));
                    fprintf(fid, 'parallel resistance: %s Ohm\n',frmnum(Polyfit.barcoefs(2)));
                    fprintf(fid, 'barrier width: %.3f nm\n',0.1*Polyfit.barcoefs(3));
                    fprintf(fid, 'barrier L-height: %.3f eV\n',Polyfit.barcoefs(4));
                    fprintf(fid, 'barrier R-height: %.3f eV\n',Polyfit.barcoefs(5));
                end;
            else
                fprintf(fid, 'f(x) = a0 + a1*x (x < x0) \n');
                fprintf(fid, 'f(x) = b0 + b1*x (x > x0) \n');
                fprintf(fid, '\n');
                fprintf(fid, 'x0: %e \n', Polyfit.x0);
                fprintf(fid, 'a0: %e \n', Polyfit.coefs1(2));
                fprintf(fid, 'a1: %e \n', Polyfit.coefs1(1));
                fprintf(fid, 'b0: %e \n', Polyfit.coefs2(2));
                fprintf(fid, 'b1: %e \n', Polyfit.coefs2(1));
                fprintf(fid, '\n');
            end;
            fclose(fid);
            
            if get(handles.cbUseComma,'Value')
                comma_overwrite(exppath);
            end;
        end;
    end;
    pause(0.25);

    waitbar(1);
    delete(hnd);


function cbExportA_Callback(hObject, eventdata, handles)
function cbExportB_Callback(hObject, eventdata, handles)
function cbExportR_Callback(hObject, eventdata, handles)
function cbExportF_Callback(hObject, eventdata, handles)
function cbUseComma_Callback(hObject, eventdata, handles)
function cbPolynomFit_Callback(hObject, eventdata, handles)
function cbBTKfit_Callback(hObject, eventdata, handles)


function eMaxPoints_Callback(hObject, eventdata, handles)

    global maxN;
    val = str2num(get(handles.eMaxPoints,'String'));
    maxN = max(10,min(round(val),10000));
    set(handles.eMaxPoints,'String',num2str(val));
    
function eMaxPoints_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function eBarrierArea_Callback(hObject, eventdata, handles)

    val = str2num(get(handles.eBarrierArea,'String'));
    val = max(1e-6,min(val,1e6));
    set(handles.eBarrierArea,'String',sprintf('%.1e',val));
    
function eBarrierArea_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');
