function names = XML_ListNodeNames(nodelst)
%XML_ListNodeNames  Build a list of node names for the nodes in a NodeList.
%
%   Syntax:
%    names = XML_ListNodeNames(nodelst)
%
%   Input:
%    nodelst: Scalar XML Document Object Model Node, NodeList or Document
%             defining the investigated node. Must provide "item" and 
%             "getLength" methods.
%
%   Output:
%    names: N x 1 cell string containing the node names for all child nodes
%           directly below the investigated node.
%            Rows:     Direct child nodes
%            Elements: String containing node name
%
%   Effect: This function will build up a cell array containing the node
%   names (XML tags) of all child nodes directly below the node specified
%   in the input. The sequence of nodes will be maintained.
%
%   Dependencies: none
%
%   Known parents: XML_FindTagNames.m
%                  OpenSim_SetupGCF.m
%                  OpenSim_SetupID.m
%                  OpenSim_SetupAnalysis.m
%                  OpenSim_SetupMA.m

%Created on 21/06/2012 by Ward Bartels.
%Stabile, fully functional.


%Loop over all child nodes
N = nodelst.getLength;
names = cell(N, 1);
for ind = 1:N
    names{ind} = char(nodelst.item(ind-1).getNodeName);
end