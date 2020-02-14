%% Test 1: Input defaults
% Test function with default inputs
[a, b, c] = sig.test.create;
netIds = cellfun(@(s) s.Node.NetId, {a, b, c});
assert(~any(diff(netIds)), 'Not all signals part of the same network')
T = evalc('networkInfo(netIds(1))');
expected = sprintf('Net %i with 3/4000 active nodes', a.Node.NetId);
assert(strcmp(strip(T), expected))

names = cellfun(@(s) s.Name, {a,b,c});
assert(strcmp(names, 'abc'), 'Unexpected names');

%% Test 2: Inputs
% Test behaviour when natework and names provided
net = sig.Net;
[a, b, c] = sig.test.create(net, {'1', '2', '3'});
netIds = cellfun(@(s) s.Node.NetId, {a, b, c});
assert(~any(diff([netIds net.Id])), 'Not all signals part of the same network')

names = cellfun(@(s) s.Name, {a,b,c});
assert(strcmp(names, '123'), 'Unexpected names');

% Test names error
try
[a, b, c] = sig.test.create(net, {'1'});
ex.identifier = '';
catch ex
end
assert(strcmp(ex.identifier, 'Signals:sig:test:create:notEnoughNames'))
