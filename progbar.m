function [hnd]=progbar(text,title,cancel_btn)

    WAIT_BAR_MODALITY = 'modal';%'normal'

    if nargin<2
        title = '';
    end;
    if nargin<3
        cancel_btn = 0;
    end;
    
    set(0,'defaulttextinterpreter','none');
    if cancel_btn
        hnd = waitbar(0,text,'Name',title,'CreateCancelBtn','setappdata(gcbf,''canceling'',1)','WindowStyle',WAIT_BAR_MODALITY);
        setappdata(hnd,'canceling',0);
    else
        hnd = waitbar(0,text,'Name',title,'WindowStyle',WAIT_BAR_MODALITY);
    end;
    set(findobj(hnd,'type','patch'),'edgecolor','b','facecolor','b');
