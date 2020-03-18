function varargout = btk_interface(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @btk_interface_OpeningFcn, ...
                   'gui_OutputFcn',  @btk_interface_OutputFcn, ...
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


function btk_interface_OpeningFcn(hObject, eventdata, handles, varargin)
    % Choose default command line output for btk_interface
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);
    
    % UIWAIT makes btk_interface wait for user response (see UIRESUME)
    % uiwait(handles.figure1);
    
    global ID_D1 ID_D2 ID_W ID_P ID_PD ID_Z1 ID_Z2 ID_G1 ID_G2;
    global lastPos BTKmodel BTKparams parentHnds ChanData;
    
    parentHnds = varargin{1};

    if exist('lastPos','var')
      if length(lastPos)>0
        set(handles.figure1,'Position',lastPos);
      end;
    end;
    
    if exist('BTKmodel','var')
        if (BTKmodel~=0)
            delete(BTKmodel);
        end;
        BTKmodel = btk_model(BTKparams.Erng*1e-3,BTKparams.N);
        setTemp(handles,BTKparams.T);
        
        BTKparams.R2 = -Inf;
        set(handles.sDelta1,'Max',BTKparams.Erng/2);
        set(handles.sDelta2,'Max',BTKparams.Erng/2);
        setValue(handles.eDelta1,handles.sDelta1,BTKparams.DGZW(ID_D1),'meV');
        setValue(handles.eDelta2,handles.sDelta2,BTKparams.DGZW(ID_D2),'meV');
        setValue(handles.eZet1,handles.sZet1,BTKparams.DGZW(ID_Z1));
        setValue(handles.eZet2,handles.sZet2,BTKparams.DGZW(ID_Z2));
        setValue(handles.eGama1,handles.sGama1,BTKparams.DGZW(ID_G1),'meV');
        setValue(handles.eGama2,handles.sGama2,BTKparams.DGZW(ID_G2),'meV');
        setValue(handles.eWeight,handles.sWeight,BTKparams.DGZW(ID_W));
        setValue(handles.ePolarization,handles.sPolarization,BTKparams.DGZW(ID_P));
        setValue(handles.ePolarizationGap,handles.sPolarizationGap,BTKparams.DGZW(ID_PD), 'meV');
        setValue(handles.eTemp,0,BTKparams.T,'K');
        
        if ChanData{3}.count==0
            set(handles.bDelta1,'Enable','off');
            set(handles.bDelta2,'Enable','off');
            set(handles.bWeight,'Enable','off');
            set(handles.bPolarization,'Enable','off');
            set(handles.bPolarizationGap,'Enable','off');
            set(handles.bZet1,'Enable','off');
            set(handles.bZet2,'Enable','off');
            set(handles.bGama1,'Enable','off');
            set(handles.bGama2,'Enable','off');
            set(handles.tRsquared,'Visible','off');
            set(handles.lRsquared,'Visible','off');
        end;
        
        showDiffChar(handles,BTKparams);
    end;

function varargout = btk_interface_OutputFcn(hObject, eventdata, handles) 
    % Get default command line output from handles structure
    varargout{1} = handles.output;


function setTemp(handles,T)

    global BTKmodel BTKparams;
    
    BTKparams.T = T;
    BTKmodel.setTemp(T);
    
    
function [X,Y,r2] = optimizeParameter(handles,idx,tag,unit)
    
    global BTKmodel BTKparams ChanData;
    
    [X,Y] = BTKmodel.calcDiffChar(0,BTKparams.DGZW);
    r2 = -Inf;
    if ChanData{3}.count>0
        X3 = ChanData{3}.getXs();
        Y3 = ChanData{3}.getYs();
        [Y,r2] = BTKmodel.normDiffChar(X3,Y3,X,Y);
        set(handles.lRsquared,'String',sprintf('%.5f',r2));
    end;
    
    if (nargin==1) || (r2==-Inf)
        return;
    end;
    
    eval(sprintf('set(handles.e%s,''BackgroundColor'',''red'');',tag));
    
%     h=waitbar(0,'Please wait ..','Name','Optimizing parameter');
%     set(h,'WindowStyle','modal');
    h = progbar('Please wait ..','Optimizing parameter',1);
        
    dgzw = BTKparams.DGZW;
    eval(sprintf('pmax = get(handles.s%s,''Max'');',tag));
    pstp = pmax*0.01;
    oor2 = r2;
    or2 = r2;
    for i=1:100
        pval = dgzw(idx);
        pvalp = min(pmax,pval + pstp);
        pvalm = max(0,pval - pstp);
        
        dgzw(idx) = pvalp;
        [X,Y] = BTKmodel.calcDiffChar(0,dgzw);
        [Yp,r2p] = BTKmodel.normDiffChar(X3,Y3,X,Y);
        
        dgzw(idx) = pvalm;
        [X,Y] = BTKmodel.calcDiffChar(0,dgzw);
        [Y,r2] = BTKmodel.normDiffChar(X3,Y3,X,Y);
        
        if r2p>r2
            dgzw(idx) = pvalp;
            Y = Yp;
            r2 = r2p;
        end;
        
        waitbar(i/100);
        
        BTKparams.DGZW = dgzw;
        eval(sprintf('setValue(handles.e%s,handles.s%s,BTKparams.DGZW(%d),''%s'');',tag,tag,idx,unit));
        showDiffChar(handles,BTKparams);
        set(handles.lRsquared,'String',sprintf('%.5f',r2));
        drawnow;
        
        if getappdata(h,'canceling')
            break;
        end;
        
        if r2==oor2
            if pstp<0.01
                break;
            end;
            pstp = pstp/10;
        end;
        oor2 = or2;
        or2 = r2;
    end;
    
    eval(sprintf('set(handles.e%s,''BackgroundColor'',''white'');',tag));
    delete(h);
    
    
function bDelta1_Callback(hObject, eventdata, handles)

    global ID_D1;
    optimizeParameter(handles,ID_D1,'Delta1','meV');
    
function bDelta2_Callback(hObject, eventdata, handles)

    global ID_D2;
    optimizeParameter(handles,ID_D2,'Delta2','meV');
    
function bWeight_Callback(hObject, eventdata, handles)

    global ID_W;
    optimizeParameter(handles,ID_W,'Weight','');
    
function bPolarization_Callback(hObject, eventdata, handles)

    global ID_P;
    optimizeParameter(handles,ID_P,'Polarization','');

function bPolarizationGap_Callback(hObject, eventdata, handles)
    
    global ID_PD;
    optimizeParameter(handles,ID_PD,'PolarizationGap','');

function bZet1_Callback(hObject, eventdata, handles)

    global ID_Z1;
    optimizeParameter(handles,ID_Z1,'Zet1','');
    
function bZet2_Callback(hObject, eventdata, handles)

    global ID_Z2;
    optimizeParameter(handles,ID_Z2,'Zet2','');
    
function bGama1_Callback(hObject, eventdata, handles)

    global ID_G1;
    optimizeParameter(handles,ID_G1,'Gama1','meV');
    
function bGama2_Callback(hObject, eventdata, handles)

    global ID_G2;
    optimizeParameter(handles,ID_G2,'Gama2','meV');

function showDiffChar(handles,params)

    global BTKparams ChanData parentHnds;
    
    h=0;
    if BTKparams.N>1000
        h=waitbar(0,'Calculating ..','Name','BTK model');
        set(h,'WindowStyle','modal');
    end;
    
    [X,Y,BTKparams.R2] = optimizeParameter(handles);
    ChanData{4}.assign(X,Y);
    
    if h~=0
        delete(h);
    end;
    
    chan_data.show_chans(parentHnds);


function enableControls(handles,tag,enable)

    senable = enable;
    if ~strcmp(enable,'on')
        senable='inactive';
    end;
    eval(sprintf('set(handles.s%s,''Enable'',''%s'');',tag,senable));
    
    eenable = enable;
    if ~strcmp(enable,'on')
        eenable='off';
    end;
    eval(sprintf('set(handles.e%s,''Enable'',''%s'');',tag,eenable));
    

function cbZet12_Callback(hObject, eventdata, handles)

    if get(handles.cbZet12,'Value')
        enableControls(handles,'Zet2','inactive');
    else
        enableControls(handles,'Zet2','on');
    end;

    
function cbGama12_Callback(hObject, eventdata, handles)

    if get(handles.cbGama12,'Value')
        enableControls(handles,'Gama2','inactive');
    else
        enableControls(handles,'Gama2','on');
    end;
    

function setControl(handles,idx,tag,unit)

    global BTKparams;
    
    eval(sprintf('BTKparams.DGZW(%d) = get(handles.s%s,''Value'');',idx{1},tag{1}));
    eval(sprintf('setValue(handles.e%s,handles.s%s,BTKparams.DGZW(%d),''%s'');',tag{1},tag{1},idx{1},unit));
    if length(idx)>1
        eval(sprintf('BTKparams.DGZW(%d) = get(handles.s%s,''Value'');',idx{2},tag{2}));
        eval(sprintf('setValue(handles.e%s,handles.s%s,BTKparams.DGZW(%d),''%s'');',tag{2},tag{2},idx{2},unit));
    end;

    eval(sprintf('set(handles.s%s,''Enable'',''inactive'');',tag{1}));
    drawnow;
    showDiffChar(handles,BTKparams);
    eval(sprintf('set(handles.s%s,''Enable'',''on'');',tag{1}));

    
function setControlByEdit(handles,idx,tag,unit)

    global BTKparams;
    
    eval(sprintf('BTKparams.DGZW(%d) = getValue(handles.e%s, handles.s%s, ''%s'');',idx{1},tag{1},tag{1},unit));
    if length(idx)>1
        eval(sprintf('BTKparams.DGZW(%d) = getValue(handles.e%s, handles.s%s, ''%s'');',idx{2},tag{2},tag{2},unit));
    end;
    showDiffChar(handles,BTKparams);
    
    
function sDelta1_Callback(hObject, eventdata, handles)

    global ID_D1;
    setControl(handles,{ID_D1},{'Delta1'},'meV');

function sDelta2_Callback(hObject, eventdata, handles)

    global ID_D2;
    setControl(handles,{ID_D2},{'Delta2'},'meV');

function sWeight_Callback(hObject, eventdata, handles)

    global ID_W;
    setControl(handles,{ID_W},{'Weight'},'');

function sPolarization_Callback(hObject, eventdata, handles)

    global ID_P;
    setControl(handles,{ID_P},{'Polarization'},'');
    
function sPolarizationGap_Callback(hObject, eventdata, handles)

    global ID_PD;
    setControl(handles,{ID_PD},{'PolarizationGap'},'');


function sGama1_Callback(hObject, eventdata, handles)

    global ID_G1 ID_G2;
    if get(handles.cbGama12,'Value')
        set(handles.sGama2,'Value',get(handles.sGama1,'Value'));
        setControl(handles,{ID_G1,ID_G2},{'Gama1','Gama2'},'');
    else
        setControl(handles,{ID_G1},{'Gama1'},'');
    end;

function sGama2_Callback(hObject, eventdata, handles)

    global ID_G2;
    setControl(handles,{ID_G2},{'Gama2'},'meV');
    
function sZet1_Callback(hObject, eventdata, handles)

    global ID_Z1 ID_Z2;
    if get(handles.cbZet12,'Value')
        set(handles.sZet2,'Value',get(handles.sZet1,'Value'));
        setControl(handles,{ID_Z1,ID_Z2},{'Zet1','Zet2'},'');
    else
        setControl(handles,{ID_Z1},{'Zet1'},'');
    end;
    
function sZet2_Callback(hObject, eventdata, handles)

    global ID_Z2;
    setControl(handles,{ID_Z2},{'Zet2'},'');

function sDelta1_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor',[.9 .9 .9]);
function sDelta2_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor',[.9 .9 .9]);
function sGama1_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor',[.9 .9 .9]);
function sGama2_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor',[.9 .9 .9]);
function sZet1_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor',[.9 .9 .9]);
function sZet2_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor',[.9 .9 .9]);
function sWeight_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor',[.9 .9 .9]);
function sPolarization_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor',[.9 .9 .9]);
function sPolarizationGap_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor',[.9 .9 .9]);


function eDelta1_Callback(hObject, eventdata, handles)

    global ID_D1;
    setControlByEdit(handles,{ID_D1},{'Delta1'},'meV');

function eDelta2_Callback(hObject, eventdata, handles)

    global ID_D2;
    setControlByEdit(handles,{ID_D2},{'Delta2'},'meV');

function eWeight_Callback(hObject, eventdata, handles)

    global ID_W;
    setControlByEdit(handles,{ID_W},{'Weight'},'');


function ePolarization_Callback(hObject, eventdata, handles)

    global ID_P;
    setControlByEdit(handles,{ID_P},{'Polarization'},'');
    
function ePolarizationGap_Callback(hObject, eventdata, handles)

    global ID_PD;
    setControlByEdit(handles,{ID_PD},{'PolarizationGap'},'');
function eZet1_Callback(hObject, eventdata, handles)

    global ID_Z1 ID_Z2;
    if get(handles.cbZet12,'Value')
        set(handles.eZet2,'String',get(handles.eZet1,'String'));
        setControlByEdit(handles,{ID_Z1,ID_Z2},{'Zet1','Zet2'},'');
    else
        setControlByEdit(handles,{ID_Z1},{'Zet1'},'');
    end;

function eZet2_Callback(hObject, eventdata, handles)

    global ID_Z2;
    setControlByEdit(handles,{ID_Z2},{'Zet2'},'');

function eGama1_Callback(hObject, eventdata, handles)

    global ID_G1 ID_G2;
    if get(handles.cbGama12,'Value')
        set(handles.eGama2,'String',get(handles.eGama1,'String'));
        setControlByEdit(handles,{ID_G1,ID_G2},{'Gama1','Gama2'},'meV');
    else
        setControlByEdit(handles,{ID_G1},{'Gama1'},'meV');
    end;
    
function eGama2_Callback(hObject, eventdata, handles)

    global ID_G2;
    setControlByEdit(handles,{ID_G2},{'Gama2'},'meV');
    
function eDelta1_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');
function eDelta2_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');
function eWeight_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');
function ePolarization_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');
function ePolarizationGap_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');
function eZet1_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');
function eZet2_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');
function eGama1_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');
function eGama2_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function eTemp_Callback(hObject, eventdata, handles)

    global BTKparams;
    
    BTKparams.T = getValue(handles.eTemp, 0, 'K');
    setTemp(handles,BTKparams.T);
    showDiffChar(handles,BTKparams);

function eTemp_CreateFcn(hObject, eventdata, handles)
    set(hObject,'BackgroundColor','white');


function val = getValue(hEdit, hSlider, unit)

    if nargin<3
        unit='';
    end;

    val_txt = get(hEdit,'String');
    val_txt = strrep(val_txt,',','.');
    val = sscanf(val_txt,'%f');
    val = setValue(hEdit,hSlider,val,unit);
    
    
function val = setValue(hEdit, hSlider, val, unit)

    if nargin<4
        unit='';
    end;

    if hSlider~=0
        min_val = get(hSlider,'Min');
        max_val = get(hSlider,'Max');
        val = max(min_val,min(val,max_val));
        set(hSlider,'Value',val);
    elseif strcmp(unit,'K')
        val = max(0.1,min(val,100.0));
    end;
    
    txt_val = sprintf('%.3f %s',val,unit);
    set(hEdit,'String',txt_val);
    
    
function figure1_CloseRequestFcn(hObject, eventdata, handles)

    global lastPos btk_hwnd parentHnds;
    
%     delete(hObject);
%     return;
    
    lastPos=get(handles.figure1,'Position');
    set(parentHnds.bBTKMod,'Enable','on');
    
    delete(hObject);
    btk_hwnd = 0;


function bOK_Callback(hObject, eventdata, handles)

    figure1_CloseRequestFcn(handles.figure1, eventdata, handles)
    
    
