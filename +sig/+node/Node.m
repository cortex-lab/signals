classdef Node < handle
  %NODE Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    FormatSpec
    % The nodes (and their ordering) which are presented as inputs, e.g.
    % used in formatting the name of the node, or in a GUI
    DisplayInputs
    Listeners
  end
  
  properties (SetAccess = immutable)
    Net sig.Net % Parent network
  end
  
  properties (SetAccess = private)
    Inputs sig.node.Node % Array of input nodes
  end
  
  properties (SetAccess = private, Transient)
    NetId double
    Id double
  end
  
  properties (Dependent)
    Name
    CurrValue
    CurrValueSet
    WorkingValue
    WorkingValueSet
  end
  
  properties (Access = private)
    NameOverride
    NetListeners
  end
  
  methods
    function this = Node(srcs, transFun, transArg, appendValues)
      if isa(srcs, 'sig.Net')
        this.Net = srcs;
        this.Inputs = sig.node.Node.empty;
      else % assume srcs is an array of input nodes
        this.Inputs = srcs;
        this.Net = unique([this.Inputs.Net]);
        assert(numel(this.Net) == 1);
      end
      this.DisplayInputs = this.Inputs;
      this.NetId = this.Net.Id;
      inputids = [this.Inputs.Id];
      if nargin < 2
        transFun = 'sig.transfer.nop';
      end
      if nargin < 3
        transArg = [];
      end
      if nargin < 4
        appendValues = false;
      end
      opCode = sig.node.transfererOpCode(transFun, transArg);
      this.Id = addNode(this.NetId, inputids, transFun, opCode, transArg, appendValues);
      this.NetListeners = event.listener(this.Net, 'Deleting', @this.netDeleted);
    end
    
    function v = get.Name(this)
      if ~isempty(this.NameOverride)
        v = this.NameOverride;
      else
        childNames = names(this.DisplayInputs);
        v = sprintf(this.FormatSpec, childNames{:});
      end
    end
    
    function set.Name(this, v)
      this.NameOverride = v;
    end
    
    function delete(this)
      if ~isempty(this.Id)
%         fprintf('Deleting node ''%s''\n', this.Name);
        deleteNode(this.NetId, this.Id);
      end
    end
    
    function v = get.CurrValue(this)
      v = currNodeValue(this.NetId, this.Id, true);
    end
    
    function set.CurrValue(this, v)
      currNodeValue(this.NetId, this.Id, true, v);
    end
    
    function b = get.CurrValueSet(this)
      [~, b] = currNodeValue(this.NetId, this.Id);
    end
    
    function v = get.WorkingValue(this)
      v = workingNodeValue(this.NetId, this.Id, true);
    end
    
    function set.WorkingValue(this, v)
      workingNodeValue(this.NetId, this.Id, true, v);
    end
    
    function b = get.WorkingValueSet(this)
      [~, b] = workingNodeValue(this.NetId, this.Id);
    end
    
    function n = names(those)
     % NAMES Return names from an array of Nodes
     %    Convenience function for returning the node names from an array
     %    of Node objects.
     %
     %    Input:
     %      those (sig.node.Node) - Array of Nodes to fetch names of
     %
     %    Output:
     %      n (cellstr) - A cell array of Node names
     %
     %    Example:
     %      inputIds = ids(node.Inputs);
     %
     % See also IDS
      n = cell(numel(those), 1);
      for i = 1:numel(those)
        n{i} = those(i).Name;
      end
    end
    
    function i = ids(those)
     % IDS Return IDs from an array of Nodes
     %    Convenience function for returning the node IDs from an array of
     %    Node objects.
     %
     %    Input:
     %      those (sig.node.Node) - Array of Nodes to fetch IDs of
     %
     %    Output:
     %      i (int) - An array of ID integers
     %
     %    Example:
     %      inputIds = ids(node.Inputs);
     %
     % See also NAMES
      i = arrayfun(@(n) n.Id, those);
   end
    
    function setInputs(this, nodes)
      % SETINPUTS Set the node inputs.
      %   Changes the node inputs and propogates the network changes.  The
      %   number of new inputs must equal the current number of inputs.
      %
      %   NB: This method must be used with care: rewiring inputs may lead
      %   to side effects such as infinite recursion.
      %
      %   Input:
      %     nodes (sig.node.Node) - An array of new input nodes the length
      %                             of this.Inputs.
      %
      %   Example: 
      %     net = sig.Net;
      %     a = net.origin('a');     
      %     b = a^2;
      %     A = net.origin('A');
      %     B = A^2
      %     % B -> b
      %     b.Node.setInputs(B.Node.Inputs)
      %
      % See also NODEINPUTS
      assert(numel(nodes) == numel(this.Inputs), 'Number of new inputs does not match')
      % Patch network
      newId = ids(nodes);
      nodeInputs(this.NetId, this.Id, newId)
      % applyNodes(this.NetId, this.Id)
      % Update class properties
      this.DisplayInputs = arrayfun(@(n) nodes(n == this.Inputs), this.DisplayInputs);
      this.Inputs = nodes;
    end
  end
  
  methods (Access = protected)
    function netDeleted(this, ~, ~)
      if isvalid(this)
        this.Id = [];
      end
    end
  end
end

