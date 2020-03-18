    function    comma_overwrite( fpath )
    % replaces all occurences of comma (",") with point (".") in a text-file.
    % Note that the file is overwritten, which is the price for high speed.
        file    = memmapfile( fpath, 'writable', true );
        comma   = uint8(',');
        point   = uint8('.');
        file.Data( transpose( file.Data==point) ) = comma;
        %%% delete(file)
    end