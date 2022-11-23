function [loc, varargout] = XML_FindTagNames(nodelst, tags, errid, errmsg)
%XML_FindTagNames  Locate tag names in a NodeList.
%
%   Syntax:
%    [loc, tags] = XML_FindTagNames(nodelst, tags, errid, errmsg)
%    [loc, present, tags] = XML_FindTagNames(nodelst, tags)
%
%   Input:
%    nodelst: Scalar XML Document Object Model Node, NodeList or Document
%             defining the investigated node. Must provide "item" and 
%             "getLength" methods.
%    tags:    N x 1 cell string defining the names of the tags to be
%             located.
%              Rows:     Tags to be located
%              Elements: String containing tag name
%    errid:   String defining error ID.
%    errmsg:  String defining error message.
%
%   Output:
%    loc:     N x 1 double array containing (zero-based) indices of the
%             tags located in the NodeList.
%              Rows:     Tags to be located
%              Contents: Indices usable for the "item" method in the
%                        NodeList; NaN if corresponding tag was not found
%    present: N x 1 logical array indicating which tags were found.
%              Rows:     Tags to be located
%              Contents: True if corresponding tag was found
%
%   Effect: This function will locate the specified tags in the provided
%   NodeList and return a set of indices that can be used in the NodeList's
%   "item" method. If the first syntax is used, an error message will be
%   generated (from the calling function) if any tags were not found.
%
%   Dependencies: XML_ListNodeNames.m
%
%   Known parents: OpenSim_SetupGCF.m
%                  OpenSim_SetupID.m
%                  OpenSim_SetupAnalysis.m
%                  OpenSim_SetupMA.m

%Created on 21/06/2012 by Ward Bartels.
%Stabile, fully functional.


%List node names <<XML_ListNodeNames.m>>
names = XML_ListNodeNames(nodelst);

%Find tags in name list
[present, loc] = ismember(tags, names);
loc = loc-1; %0-based indices

%Determine if error message was provided
errin = nargin>=4;

%If error message was provided, throw error if any tags were not found
if errin 
    if ~all(present)
        exception = MException(errid, errmsg);
        throwAsCaller(exception);
    end
else %Otherwise, compensate for missing tags
    loc(~present) = NaN;
end

%Preallocate cell array for outputs
maxnargs = 2-errin;
varargout = cell(1, max(nargout-1, maxnargs));

%If requested, build tags struct
if nargout>=3-errin
    varargout{maxnargs} = cell2struct(num2cell(loc(present)), tags(present), 1);
end

%If requested, add present to output cell array
if ~errin && nargout>=2
    varargout{1} = present;
end