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
      n = cell(numel(those), 1);
      for i = 1:numel(those)
        n{i} = those(i).Name;
      end
    end
    
    function setInputs(this, nodes)
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

