function CreateActuatorsFile(ForceSetFile_org,ForceSetFile,modelFile)

fid = fopen (modelFile ,'r+','n');

while feof(fid) == 0
    tline = fgetl(fid);
    matches = findstr(tline, ['Body name="pelvis"']);
    num = length(matches);
    if num > 0
        break
    end
end

tline = fgetl(fid);
fseek(fid, 0, 'cof');
tline = fgetl(fid);
[token, remain] = strtok(tline,'>');
[com, remain2] = strtok(remain,'<');
com = com(2:end);

fclose(fid);

SOactin = ForceSetFile_org;

SOSetup = xmlread(SOactin);
SOSetup = SOSetup.getDocumentElement;

% Trapje naar beneden
namesA = XML_ListNodeNames(SOSetup);
toolnode = find(strcmpi(namesA, 'ForceSet'));
toolnode1 = SOSetup.item(toolnode-1);

% Trapje naar beneden
namesB = XML_ListNodeNames(toolnode1);
toolnode2 = find(strcmpi(namesB, 'objects'));
toolnode3 = toolnode1.item(toolnode2-1);

for p = 2:2:6
    tags = {'point'}.';
    % Trapje naar beneden
    namesC = XML_ListNodeNames(toolnode3);
    toolnode4 = p;
    toolnode5 = toolnode3.item(toolnode4-1);
    
    %Locate tags in nodes under toolnode 5
    [varargin, tags] = XML_FindTagNames(toolnode5, tags, [mfilename ':XMLTagMissing'], ...
        'Required data not found.');
    
    % Lees hier de nieuwe combinatie in.
    toolnode5.item(tags.point).item(0).setNodeValue([' ' com ' ']);
    
    clear namesC toolnode4 toolnode5 tags
end
xmlwrite(ForceSetFile, SOSetup.getOwnerDocument);
