function varargout = create(varargin)
% SIG.TEST.CREATE Returns a set of origin signals
%  [A,B,...N] = SIG.TEST.CREATE([NET, NAMES]) Creates a set of new origin
%  signals and assigns them to the output arguments.  
%
%  Inputs:
%    net (sig.Net) : A Net object for which to create the signals.  If none
%                    is provided, one is created.  
%    names (cellstr) : A list of names to assign the output signals.  The
%                      number of elements must be >= nargout.  If no names
%                      are given, letters of the alphabet are used instead.
%
%  Output(s):
%    sig.node.OriginSignal : One or more origin signals for a given network
%
%  Examples:
%    % Quickly create three origin signals for testing
%    [a, b, c] = sig.test.create;
%
%    % Create some origin signals for a given network, with given names
%    net = sig.Net; 
%    [x, y] = sig.test.create(net, {'input', 'trigger'})
% 
% See also sig.test.playgroundPTB

p = inputParser;
p.addOptional('net',[])
% If no names provided, use alphabet, i.e. 'a', 'b', etc.
p.addOptional('names',mapToCell(@char, (1:10) + 96))
p.parse(varargin{:})
net = p.Results.net;
names = p.Results.names;

% Create a network if one is not provided
if isempty(net)
  net = sig.Net;
  net.Debug = 'on'; % Turn on debug by default
end

assert(numel(names) >= nargout, 'Signals:sig:test:create:notEnoughNames', ...
  'Number of names provided must be >= nargout')

varargout = cell(1,nargout);
for i = 1:nargout
  varargout{i} = net.origin(names{i});
end