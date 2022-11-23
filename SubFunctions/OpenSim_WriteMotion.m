function fpath = OpenSim_WriteMotion(names, data, header, oldheader, fpath, title, deg)
%OpenSim_WriteMotion  Write OpenSim motion or storage file.
%
%   Syntax:
%    fpath = OpenSim_WriteMotion(names, data, header, oldheader, fpath, ...
%                                title)
%
%   Input:
%    names:     N x 1 cell array defining column names.
%                Rows:     Columns in the file (different data)
%                Elements: String defining column name
%    data:      M x N double array defining numeric data to be written.
%                Rows:     Rows in the file (time frames)
%                Columns:  Columns in the file (different data)
%                Contents: Numeric data
%    header:    String defining the header at the start of the file,
%               without the "endheader" keyword. Optional, generated
%               automatically if omitted or empty.
%    oldheader: Scalar logical indicating whether a reverse-compatible SIMM
%               header is to be added to the automatically generated file
%               header. Optional, defaults to true.
%    fpath:     String defining a path to the file that is to be written.
%               Optional, obtained via a file output dialog if omitted or
%               empty.
%    title:     String defining the window title for the file output
%               dialog. Optional, defaults to 'Save motion or storage file'
%               if omitted or empty.
%
%   Output:
%    fpath: String containing a path to the file that was written. Will be
%           set to an empty string if the user closes the file save dialog
%           box.
%
%   Effect: This function will write the provided data to an OpenSim motion
%   or storage file. If no header is provided, a valid header is generated
%   automatically.
%
%   Dependencies: SIMM_WriteMotion.m
%
%   Known parents: none

%Created on 13/12/2011 by Ward Bartels.
%WB, 14/12/2011: Fixed unbelievably dumb bug causing row and column counts
%                in header to get switched.
%Stabile, fully functional.


%Set defaults for input variables
if nargin<3, header = ''; end
if nargin<4, oldheader = true; end
if nargin<5, fpath = ''; end
if nargin<6 || isempty(title), title = 'Save motion or storage file'; end

%If no file path was provided, get file from file input dialog
if isempty(fpath)
    [filename, pathname] = uiputfile({'*.mot;*.sto' 'Motion or storage file (*.mot,*.sto)'}, title);
    if isequal(filename, 0)
        fpath = '';
        return
    end
    fpath = fullfile(pathname, filename);
end

%If no header was provided, construct a valid header automatically
if isempty(header)
    
    %Separate filename from path
    [varagin, filename] = fileparts(fpath);
    
    %Construct OpenSim header
    header = sprintf(['%s\nversion=1\nnRows=%d\nnColumns=%d\ninDegrees=' deg '\n'], ...
                     filename, size(data, 1), numel(names));
    
    %If requested, construct reverse-compatible SIMM header
    if oldheader
        header = [header ...
                  sprintf('\n# SIMM Motion File Header:\nname %s\ndatacolumns %d\ndatarows %d\n', ...
                          filename, numel(names), size(data, 1))];
    end
end %if header is not empty, SIMM_WriteMotion will check that it ends on a newline

%Write the file <<SIMM_WriteMotion.m>>
fpath = SIMM_WriteMotion(names, data, header, fpath);