classdef strings<handle

    properties (SetAccess = private)
        hListBox 
        List;
    end

    methods
        function obj = strings(hListBox)
            obj.hListBox = hListBox;
            obj.List = '';
        end

        function obj2 = copy_strings(obj,hListBox)
            obj2 = strings(hListBox);
            obj2.List = obj.List;
        end
        
        function obj=add_string(obj,string)
            obj.List=[obj.List {string}];
        end
        
        function str=get_string(obj,idx)
            str=obj.List{idx};
        end
        
        function N=count(obj)
            N=length(obj.List);
        end
        
        function clear(obj)
            obj.List = '';
        end;
        
        function obj=rename_string(obj,idx,string)
            if (~iscell(obj.List))
                obj.List = string;
            else
                obj.List = obj.List';
                obj.List{idx} = string;
            end;
        end;

        function obj=sort(obj)
            N = length(obj.List);

            if N==0
                return;
            end;

            max_len = 0;
            for i=1:N
                if length(obj.List{i})>max_len
                    max_len = length(obj.List{i});
                end;
            end;
            tmp=zeros(N,max_len);
            for i=1:N
                tmp(i,1:length(obj.List{i}))=lower(obj.List{i});
            end;
            tmp=sortrows(tmp);
            for i=1:N
                obj.List{i}=char(tmp(i,:));
            end;
        end;
        
        function display(obj,hListBox)
            if nargin<2
                hnd = obj.hListBox;
            else
                hnd = hListBox;
            end;
            if (hnd>0)
                val=get(hnd, 'Value');
                if (val==0)
                    set(hnd, 'Value', 1);
                end;
                if (val>length(obj.List))
                    set(hnd, 'Value', length(obj.List));
                end;
                set(hnd, 'String', obj.List);
            end;
        end;

        function idx=get_selected(obj)
            if (obj.hListBox>0)
                idx=get(obj.hListBox, 'Value');
            end;
        end;

        function select(obj,idx)
            if (obj.hListBox>0)
                set(obj.hListBox, 'Value', max(1,min(idx,length(obj.List))));
            end;
        end;
    end
end
