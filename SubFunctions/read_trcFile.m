% Read data from TRC file
% Simon Harrison
% 11th Aug 2009
% 
% ------------------------------------------------------------------------
% Usage: v = read_trcFile(fileName)
% ------------------------------------------------------------------------
% 
% Inputs:   fileName = name of TRC file to read
% 
% Outputs:  Structured array: v
%               v.PathFileType          - usually 4. Note sure what this is
%               v.FileName              - string
%               v.DataRate              - float
%               v.CameraRate            - float
%               v.NumFrames             - integer
%               v.NumMarkers            - integer
%               v.Units                 - mm, m etc
%               v.OrigDataRate          - float
%               v.OrigDataStartFrame    - integer
%               v.OrigNumFrames         - integer
%               v.MarkerList            - Marker1, Marker2 ...
%               v.Data                  - Frame,Time,X1,Y1,Z1,...,Xn,Yn,Zn
% 
% 
% ------------------------------------------------------------------------

function v = read_trcFile(fileName)

    usage = 'Usage: v = read_trcFile(fileName)';

    if nargin < 1,
        disp(usage);
        return
    end

    fid = fopen(fileName, 'r');	
    if fid == -1								
        error(['unable to open ', fileName])		
    end

    % Hardcoded format file read. Hope this doesn't change.
    a = fgetl(fid);
    v.PathFileType = a(14);
    v.FileName = a(24:end);
    a = fgetl(fid); %#ok<NASGU>
    a = fgetl(fid);
    aa = sscanf(a,'%f%f%f%f%s%f%f%f');
    aaLength = length(aa);
    v.DataRate = aa(1);
    v.CameraRate = aa(2);
    v.NumFrames = aa(3);
    v.NumMarkers = aa(4);
    v.Units = '';
    for i = 5:aaLength-3
        v.Units = [v.Units,char(aa(i))];
    end
    v.OrigDataRate = aa(aaLength-2);
    v.OrigDataStartFrame = aa(aaLength-1);
    v.OrigNumFrames = aa(aaLength);
    
    clear temp2
    a = fgetl(fid);
    temp = regexp(a,'\t','split');
    
    % Maarten Adj: Sometimes the trc files stored with only one space
    % between the marker headers, thereforwe we use another implementation
    % that does not depend on the number of spaces between the headers (but
    % this implementation is slower)
    ct=1;
    for i=3:1:size(temp,2);
        if ~isempty(temp{i})
            temp2{ct}=temp{i};
            ct=ct+1;
        end
    end    
%     for i = 3:3:size(temp,2)
%         temp2{i/3} = temp{i}; %#ok<AGROW>
%     end
    v.MarkerList = temp2;
    
    a = fgetl(fid);%#ok<NASGU>
    a = fgetl(fid);%#ok<NASGU>
    
    clear Data
    dataSize = 0;
    while 1
        a = fgetl(fid);
        if ~ischar(a), break, end
        dataSize = dataSize + 1;        
        Data(dataSize,:) = sscanf(a, '%f'); %#ok<AGROW>
        clear a
    end         

    v.Data = Data;
end
