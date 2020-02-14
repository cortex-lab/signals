function varargout = create(net, names)
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

% Create a network if one is not provided
if nargin < 1
  net = sig.Net;
  net.Debug = 'on'; % Turn on debug by default
end
% If no names provided, use alphabet, i.e. 'a', 'b', etc.
if nargin < 2, names = mapToCell(@char, (1:5) + 96); end
assert(numel(names) >= nargout, 'Signals:sig:test:create:notEnoughNames', ...
  'Number of names provided must be >= nargout')

varargout = cell(1,nargout);
for i = 1:nargout
  varargout{i} = net.origin(names{i});
end