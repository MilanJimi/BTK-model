function varargout = file_info(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @file_info_OpeningFcn, ...
                   'gui_OutputFcn',  @file_info_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

global hParent;

if nargin
    hParent = varargin{1};
end;

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


function file_info_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;
    guidata(hObject, handles);

    global DataFile Lists List Chops;

    Header = strings(handles.lbHeader);
    for i=1:length(DataFile.header);
        Header.add_string(strrep(DataFile.header{i},char(9),'...'));
    end;
    Header.display();
    
    List = copy_strings(Lists{2},handles.lbColumns);
    List.display();
    
%     Chops = copy_strings(Lists{4},handles.lbChops);
    Nturns = DataFile.turns_count();
    Chops = strings(handles.lbChops);
    for i=1:Nturns
        Chops.add_string(num2str(i));
    end;
    Chops.select(1);
    Chops.display();

    set(handles.figure1,'Name',DataFile.file_name);

    % centralizuj okno
    res=get(0,'screensize');
    pos=get(handles.figure1,'Position');
    set(handles.figure1,'Position',[0.5*(res(3)-pos(3)),0.5*(res(4)-pos(4)),pos(3),pos(4)]);
    
    lbColumns_Callback(hObject, eventdata, handles);
    
    
function lbChops_Callback(hObject, eventdata, handles)

    lbColumns_Callback(hObject, eventdata, handles);
    
    
function lbChops_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function varargout = file_info_OutputFcn(hObject, eventdata, handles) 

    varargout{1} = handles.output;


function lbHeader_Callback(hObject, eventdata, handles)

function lbHeader_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function WriteLog(hAxes,strings)
    
    global LastLog BG_COLOR;
    
    LastLog = strings;
    
    plot(hAxes,[0,1],[0,1],'.','Color',BG_COLOR);
    axis(hAxes,'off');
%    zoom(hAxes,'off');
    hold(hAxes,'off');
    axes(hAxes);
    for i=1:length(strings)
        if ~exist('strings{i}.int')
            strings{i}.int='tex';
        end;
        text('position',[0.02,1-i*0.04],'string',strings{i}.str,'fontname','courier new','fontsize',9,'interpreter',strings{i}.int);
    end;
    
    
function lbColumns_Callback(hObject, eventdata, handles)

    global DataFile List Chops;
    
    col_idx = List.get_selected();
    chp_idx = Chops.get_selected();
    X = DataFile.get_col_data(col_idx);
    Xstp = diff(X);
    N = length(X);

    x1 = DataFile.turns_idx(chp_idx,1);
    x2 = DataFile.turns_idx(chp_idx,2);
    Xch = X(x1:x2);
    Nch = length(Xch);
    Xch_stp = diff(Xch);
    
    plot(handles.axValues,X,'b-','LineWidth',2);
    csv_data.set_xy_lims(handles.axValues,[1 N],X);
    hold(handles.axValues,'on');
    plot(handles.axValues,[x1:x2],Xch,'r-','LineWidth',2);
    hold(handles.axValues,'off');
    
%     plot(handles.axSteps,Xch_stp,'r-','LineWidth',2);
%     hold(handles.axSteps,'on');
%     Xi = [1:ceil(Nch/100):Nch];
%     Xstpf=interp1([1:Nch-1],Xch_stp,Xi','nearest');
%     csv_data.set_xy_lims(handles.axSteps,Xi,Xstpf);
%     hold(handles.axSteps,'off');
%     zoom(handles.axSteps,'off');
    
    strs={};
    for i=1:30
        strs{i}.str='';
    end;
    
    stat = DataFile.get_col_stat(Xch);
    strs{1}.str=sprintf(' STATISTICS OF COLUMN %d (chop %d)',col_idx,chp_idx);
    strs{2}.str=sprintf(' ----------------------------------',col_idx);
    strs{3}.str=sprintf(' number of points : %d',stat.N);
    strs{4}.str=sprintf(' from %s to %s',frmnum(stat.min),frmnum(stat.max));
    strs{5}.str=sprintf(' abs.min. : %s',frmnum(stat.absmin));
    strs{6}.str=sprintf(' average  : %s',frmnum(stat.avg));
    strs{7}.str=sprintf(' std.dev. : %s',frmnum(stat.dev));
    strs{8}.str=sprintf(' ord.rng. : %.1f',log10(stat.max/stat.absmin));

    stat = DataFile.get_col_stat(abs(Xch_stp));
    strs{10}.str=sprintf(' STATISTICS OF STEPS (absolute values)',col_idx,chp_idx);
    strs{11}.str=sprintf(' -------------------------------------',col_idx);
    strs{12}.str=sprintf(' number of steps : %d',stat.N);
    strs{13}.str=sprintf(' from %s to %s',frmnum(stat.min),frmnum(stat.max));
    strs{14}.str=sprintf(' average  : %s',frmnum(stat.avg));
    strs{15}.str=sprintf(' 5%%-tile  : %s',frmnum(stat.prc5));
    strs{16}.str=sprintf(' median   : %s',frmnum(stat.med));
    strs{17}.str=sprintf(' 95%%-tile : %s',frmnum(stat.prc95));
    strs{18}.str=sprintf(' ord.rng. : %.1f (from %%-tiles)',log10(stat.prc95/stat.prc5));
    
    WriteLog(handles.axLog,strs);

function lbColumns_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function eChopTol_Callback(hObject, eventdata, handles)
function eChopTol_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function eMinLen_Callback(hObject, eventdata, handles)
function eMinLen_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function pmChopTol_Callback(hObject, eventdata, handles)
function pmChopTol_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function pmMinLen_Callback(hObject, eventdata, handles)
function pmMinLen_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');

    
function bChop_Callback(hObject, eventdata, handles)

    global DataFile List Chops;
    
    mstr = get(handles.pmChopTol,'String');
    idx = round(get(handles.pmChopTol,'Value'));
    Ntol = str2num(mstr{idx});
    
    mstr = get(handles.pmMinLen,'String');
    idx = round(get(handles.pmMinLen,'Value'));
    Nmin = str2num(mstr{idx});

    if get(handles.cbMaxChops,'Value')
        Nmax = str2num(get(handles.eChopN,'String'));
        DataFile.chop_data(List.get_selected(),Ntol,Nmin,Nmax);
    else
        DataFile.chop_data(List.get_selected(),Ntol,Nmin);
    end;
    
    Chops.clear();
    [N,m]=size(DataFile.turns_idx);
    for i=1:N
        Chops.add_string(num2str(i));
    end;
    Chops.display();
    Chops.select(1);

    lbColumns_Callback(hObject, eventdata, handles);
    

function bOK_Callback(hObject, eventdata, handles)

    delete(handles.figure1);


function eChopN_Callback(hObject, eventdata, handles)
function eChopN_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function cbMaxChops_Callback(hObject, eventdata, handles)

    if get(handles.cbMaxChops,'Value')
        set(handles.eChopN,'Enable','on');
    else
        set(handles.eChopN,'Enable','off');
    end;


function bReset_Callback(hObject, eventdata, handles)
