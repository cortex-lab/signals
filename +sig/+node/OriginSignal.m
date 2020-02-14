classdef OriginSignal < sig.node.Signal
  % sig.node.OriginSignal Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (SetAccess = private, Transient)
    ActiveTimers
  end
  
  methods
    function this = OriginSignal(node)
      this = this@sig.node.Signal(node);
    end

    function post(this, v)
      % assigns the value `v` to `this`
      
      % an array containing the network indices of the signals which will
      % be affected as a result of this post
      affectedIdxs = submit(this.Node.NetId, this.Node.Id, v);
      applyNodes(this.Node.NetId, affectedIdxs);
    end

    function delayedPost(this, value, delay)
      t = GetSecs;
      if nargin < 3
        [value, delay] = value{:};
      end
      this.Node.Net.Schedule(end+1) = struct('nodeid', this.Node.Id, 'value', value, 'when', t + delay);
%       tmr = timer('TimerFcn', @tmrfn, 'StartDelay', delay - 3e-3); %NB: hacky lag correction
%       this.ActiveTimers = [this.ActiveTimers tmr];
%       start(tmr);
      
%       function tmrfn(~,~)
%         global inPost
%         
%         if inPost
%           disp('***** starting delay post while normal post in progress **** ');
%         end
% %         assert(~inPost, 'starting delay post while normal post in progress');
%         post(this, value);
%         idx = this.ActiveTimers == tmr;
%         if numel(this.ActiveTimers) == 1
%           this.ActiveTimers = [];
%         else
%           this.ActiveTimers(idx) = [];
%         end
%         stop(tmr);
%         delete(tmr);
%       end
    end
    
    function cancelPending(this)
      if ~isempty(this.ActiveTimers)
        stop(this.ActiveTimers);
        delete(this.ActiveTimers);
        this.ActiveTimers = [];
      end
    end
  end
end

