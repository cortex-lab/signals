classdef Output < sig.Registry
  %SIG.OUTPUT Interface between Signals and DAQ Controller
  %   Signals added to the Registry object via subassign have their values
  %   stored and timestamped using the provided clock function.  Upon
  %   update, the values are forwarded to the Controller object
  %
  %   Example:
  %     rig = hw.devices;
  %     outputs = sig.Ouput(rig.daqController, @clock.now)
  %     outputs.A = s1;
  %     outputs.B = s2;
  %     S = logs(outputs)
  %
  % See also AUDSTREAM.REGISTRY, HW.DAQCONTROLLER
  
  properties (SetAccess = private)
    % A hardware interface object.  Currently only hw.DaqController objects
    % are supported
    Controller
  end
  
  properties (Access = private)
    % A map of virtual channel name keys and their corresponding channels
    MultiplexedFields containers.Map
    % An array of onValue listeners for update callbacks
    Handles TidyHandle
  end
    
  methods
    function this = Output(controller, varargin)
      % SIG.OUTPUT Interface between Signals and DAQ Controller
      %  When Signals are added to this registry via subscripted assignment
      %  a logging signal is created along with an onValue callback that
      %  accesses the command method of the Controller class.
      %
      %  Inputs:
      %    controller (hw.DaqController) - The DAQ interface object
      %    clockFun (function_handle) - A function that returns a timestamp
      %
      %  Example:
      %    output = sig.Output(hw.DaqController, @now)
      %
      % See also AUDSTREAM.REGISTRY, HW.DAQCONTROLLER
      this = this@sig.Registry(varargin{:});
      this.Name = 'Outputs';
      this.Reserved = [this.Reserved {'multiplex'}];
      this.Controller = controller;
      this.MultiplexedFields = containers.Map();
      if ~isempty(controller) && ~isempty(controller.ChannelNames)
        this.MultiplexedFields('all') = controller.ChannelNames;
      end
    end
    
    function multiplex(this, name, channels)
      % MULTIPLEX Map a new subs ref to one or more DAQ channel names
      %  Creates a 'virtual' channel name that when referenced will map its
      %  signal's values to the provided channels.  One or more channel 
      %  names or indices may be provided.
      %
      %  NB: Channels must correspond to an existing DAQ channel name or
      %  virtual channel.  You cannot map to duplicate channels (channel
      %  list must be unique).
      %
      %  Inputs:
      %    name (char) - A valid variable name for virtual channel.
      %    channels (string|cellstr|char|int) - One or more channel names 
      %     or indices to map to virtual channel name.  
      %
      %  Example:
      %    % Rename the first hardware channel to 'reward'
      %    output.multiplex('reward', 1)
      %    % Multiplex channels so that a signal's value maps to multiple
      %    % outputs
      %    output.multiplex('both', {'reward', 'laserShutter'})
      %    output.reward = a;
      %    output.both = a.map2(b, @horzcat);
      %
      assert(isvarname(name), 'name must be a valid variable name')
      if isnumeric(channels)
        channels = this.Controller.ChannelNames(channels);
      else
        channels = cellstr(channels);  % ensure cellstr
        map = this.MultiplexedFields;
        % Get list of channels that are real channel names
        isVirtual = arrayfun(@(n) map.isKey(n), channels);
        isReal = ismember(channels(~isVirtual), this.Controller.ChannelNames);
        assert(all(isReal), 'unrecognized channel name')
        % Convert any virtual channel names to their real counterparts
        virtual2real = cellfun(@(n)cellstr(map(n)), channels(isVirtual), 'uni', 0);
        channels(isVirtual) = virtual2real;
        channels = cellflat(channels);
        assert(length(channels) == length(unique(channels)), 'duplicate channels')
      end
      this.MultiplexedFields(name) = channels;
    end

    function value = entryAdded(this, name, value)
      % ENTRYADDED Log entry and add onValue callback
      %   This method is called once when a new field is added via
      %   subscripted assignment.  Creates a logging signal and if a valid
      %   controller object is present, creates a callback to map Signal
      %   values to DAQ controller command output method.  This is called
      %   by the StructRef subsasgn method.
      %
      %   Inputs:
      %     name (char) - The name of the newly assigned field
      %     value (sig.Signal) - The Signal assigned to the field
      %
      % See also TOCONTROLLER
      
      % Super class validates input and creates logging Signal
      entryAdded@sig.Registry(this, name, value);
      
      % Currently without a signal generator there can be no output
      if isempty(this.Controller) || ...
          isempty(this.Controller.SignalGenerators) || ...
          isempty(this.Controller.ChannelNames)
        return
      end
      
      channels = ensureCell(this.Controller.ChannelNames);
      % Find matching channel from DAQ Controller
      if isKey(this.MultiplexedFields, name)
        id = ismember(this.MultiplexedFields(name), channels);
      else
        id = strcmp(name, channels);
      end
      
      if ~any(id) % if the output is present, create callback
        % Warn user of no match
        id = 'signals:sig:Outputs:channelNotFound';
        msg = 'The referenced channel %s was not found in hardware controller ChannelNames';
        warning(id, msg, name);
        return
      end
      command = fun.partial(@this.toController, id);
      this.Handles = [this.Handles value.onValue(command)];
    end
        
    function s = cleanup(this, varargin)
      % CLEANUP Clean up object
      %   Deletes any listeners and optionally returns logs before
      %   resetting the entries and field map.
      if nargout > 0, s = this.logs(varargin{:}); end
      this.Handles = [];
      this.Entries = struct();
      this.EntryNames = {};
      this.MultiplexedFields = containers.Map();
    end
    
  end
  
  methods (Access = private)
    function toController(this, ids, values)
      % TOCONTROLLER Callback for mapping value to DAQ Controller
      %   Called when an entry Signal updates.  Calls the DAQ Controller's
      %   command output method with the zero-padded values.
      %
      %   Inputs:
      %     ids (logical) - The indicies of the channels that correspond to
      %      the provided values.  
      %     values (any) - A matrix or cell array of value commands where
      %      each column corresponds to a given channel.
      %
      % See also ENTRYADDED
      assert(sum(ids) == length(values))
      v = zeros(size(values,1), this.Controller.NumChannels);
      if iscell(values) || size(values, 1) > 1
        fprintf('delivering output to %i channel(s)\n', size(values, 2))
        if iscell(values), v = num2cell(v); end  % Convert to cell if required
      else
        fprintf('delivering output of %.2f\n', values)
      end
      v(:,ids) = values;  % Padded values
      this.Controller.command(v)
    end
  end
end