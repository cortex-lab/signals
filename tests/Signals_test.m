classdef Signals_test < matlab.unittest.TestCase
  properties
    net
    A
    B
    C
  end
  
  methods (TestClassSetup)
    function createNetwork(testCase)
      testCase.net = sig.Net;
      testCase.addTeardown(@delete, testCase.net)
    end
  end
  
  methods (TestMethodSetup)
    function setupInputSignals(testCase)
      testCase.A = testCase.net.origin('a');
      testCase.B = testCase.net.origin('b');
      testCase.C = testCase.net.origin('c');
      
      testCase.addTeardown(@delete, testCase.A)
      testCase.addTeardown(@delete, testCase.B)
      testCase.addTeardown(@delete, testCase.C)
    end
  end
  
  methods (Test)
    function test_bufferUpTo(testCase)
      % Test for bufferUpTo method
      a = testCase.A;
      b = a.bufferUpTo(3);
      
      a.post(randi(1e4))
      testCase.verifyEqual(b.Node.CurrValue, a.Node.CurrValue, ...
        'Unexpected output when bufferUpTo')
      testCase.verifyMatches(b.Name, '\w+\.bufferUpTo\(\d+)', 'Unexpected Name')

      % Test filling buffer
      vals = rand(1,4);
      arrayfun(@(v) a.post(v), vals)
      testCase.verifyEqual(b.Node.CurrValue, vals(end-2:end), ...
        'Fails to buffer up to sample number')
      
      % Test transfer function directly; no new changes in network
      % ids = pick([b.Node.Inputs], 'Id') % Same as below, requires Rigbox
      inIds = arrayfun(@(n) n.Id, b.Node.Inputs);
      args = {testCase.net.Id, inIds, b.Node.Id};
      [~, valset] = sig.transfer.buffer(args{:});
      testCase.verifyFalse(valset, 'Expected ''valset'' to be false')
      
      % Update one of the input nodes
      expected = sort(cellfun(@(n) n.Node.Id, {a,b}));
      actual = submit(testCase.net.Id, a.Node.Id, rand);
      testCase.verifyEqual(expected(:), actual, ...
        'Unexpected affected node indicies returned')
      [val, valset] = sig.transfer.buffer(args{:});
      testCase.verifyTrue(valset, 'Expected ''valset'' to be true')
      testCase.verifyEqual(val(end), a.Node.WorkingValue, 'Failed to re-evaluate function')
      
      % Test N samples as signal
      b = testCase.B;
      buff = a.bufferUpTo(b);
      testCase.verifyMatches(buff.Name, '\w+\.bufferUpTo\(\w+)', 'Unexpected Name')
      
      % No updates until n samples defined
      a.post(rand)
      inIds = arrayfun(@(n) n.Id, buff.Node.Inputs);
      args = {testCase.net.Id, inIds, buff.Node.Id};
      [~, valset] = sig.transfer.buffer(args{:});
      testCase.verifyFalse(valset, 'Expected ''valset'' to be false')
      
      % Initialize N samples
      n = 3;
      b.post(n), arrayfun(@(v) a.post(v), rand(1,n))
      expected = ...
        numel(buff.Node.CurrValue) == n && ...
        buff.Node.CurrValue(end) == a.Node.CurrValue;
      testCase.verifyTrue(expected, ...
        'Unexpected output when nSamples is signal')
      
      % Test restricting n samples
      b.post(b.Node.CurrValue-1)
      [~, valset] = sig.transfer.buffer(args{:});
      testCase.verifyFalse(valset, 'Expected ''valset'' to be false')
      a.post(rand)
      expected = ...
        numel(buff.Node.CurrValue) == n-1 && ...
        buff.Node.CurrValue(end) == a.Node.CurrValue;
      testCase.verifyTrue(expected, ...
        'Unexpected output when nSamples is signal')
    end
    
    function test_buffer(testCase)
      % Test for buffer method.  For thorough testing use test_bufferUpTo
      a = testCase.A;
      n = 3;
      b = a.buffer(n);
      
      % Test unfilled buffer
      a.post(rand)
      testCase.verifyEmpty(b.Node.CurrValue, ...
        'Expected buffer to be uninitialized while nUpdates < n')
      testCase.verifyMatches(b.Name, '\w+\.buffer\(\d+)', 'Unexpected Name')

      % Test filling buffer
      vals = rand(1,n);
      arrayfun(@(v) a.post(v), vals)
      testCase.verifyEqual(b.Node.CurrValue, vals(end-2:end), ...
        'Fails to buffer up to sample number')
    end
    
    function test_filter(testCase)
      % Tests for filter method
      [a, b] = deal(testCase.A, testCase.B);
      f = a.filter(@ischar, b);
      
      % Test format specification
      testCase.verifyMatches(f.Name, '\w+\.filter\(@\w+\)', 'Unexpected Name')
      
      b.post(true) % Keep passed
      [~, set] = currNodeValue(testCase.net.Id, f.Node.Id);
      testCase.verifyFalse(set, 'Unexpected update')
      
      % Test filtering
      a.post('c')
      testCase.verifyEqual(f.Node.CurrValue, a.Node.CurrValue, ...
        'Failed to update with the correct value')
      a.post(2)
      testCase.verifyNotEqual(f.Node.CurrValue, a.Node.CurrValue, ...
        'Failed to discard value')
      
      b.post(false) % Keep failed
      a.post(2)
      testCase.verifyEqual(f.Node.CurrValue, a.Node.CurrValue, ...
        'Failed to update with the correct value')
      a.post('c')
      testCase.verifyNotEqual(f.Node.CurrValue, a.Node.CurrValue, ...
        'Failed to discard value')
      
      % Test functions are char
      f = a.filter('~=2');
      a.post(0)
      testCase.verifyEqual(f.Node.CurrValue, a.Node.CurrValue, ...
        'Failed to discard value')
      a.post(2)
      testCase.verifyNotEqual(f.Node.CurrValue, a.Node.CurrValue, ...
        'Failed to update with the correct value')
    end
      
    function test_map(testCase)
      % Tests for map method
      [a, c] = deal(testCase.A, testCase.C);
      
      % Test mapping of signal through MATLAB function
      b = a.map(@fliplr);
      arr = 1:3;
      a.post(arr)
      testCase.verifyEqual(b.Node.CurrValue, fliplr(arr), ...
        'Unexpected output when mapping function')
      testCase.verifyMatches(b.Name, '\w+\.map\(@\w+\)', 'Unexpected Name')
      
      % Test mapping to a constant
      v = rand;
      b = a.map(v);
      a.post(arr)
      testCase.verifyEqual(b.Node.CurrValue, v, ...
        'Unexpected output when mapping constant')
      testCase.verifyMatches(b.Name, '\w+\.map\([\d|\.]*\)', 'Unexpected Name')
      
      % Test transfer function directly
      % No new changes in network;
      args = {testCase.net.Id, a.Node.Id, [], @identity};
      [~, valset] = sig.transfer.map(args{:});
      testCase.verifyFalse(valset, 'Expected ''valset'' to be false')
      % Update one of the input nodes
      actual = submit(testCase.net.Id, a.Node.Id, v);
      testCase.verifyEqual(sort([a.Node.Id; b.Node.Id]), actual, ...
        'Unexpected affected node indicies returned')
      [val, valset] = sig.transfer.map(args{:});
      testCase.verifyTrue(valset, 'Expected ''valset'' to be true')
      testCase.verifyEqual(val, v, 'Failed to re-evaluate function')
      
      % Test mapping one Signal to another:
      b = a.map(c);
      c.post(arr)
      testCase.verifyEmpty(b.Node.CurrValue, ...
        'Expected dependent Signal to be empty')
      a.post(0)
      testCase.verifyEqual(b.Node.CurrValue,arr, ...
        'Unexpected output when mapping Signal')
      testCase.verifyMatches(b.Name, '\w+\.map\(\w+\)', 'Unexpected Name')
    end
    
    function test_mapn(testCase)
      % Tests for mapn method
      [a, b] = deal(testCase.A, testCase.B);
      
      % Test mapping multiple input signals to multiple output signals
      [X, Y] = a.mapn(b, @meshgrid);
      
      % Test with these input values:
      xx = 1:5; yy = 5:10;
      [expectedX, expectedY] = meshgrid(xx, yy);
      
      % Verify that dependent signals only updated when all input signals
      % have values
      a.post(xx);
      actual = [X.Node.CurrValue Y.Node.CurrValue];
      testCase.verifyEmpty(actual, 'Values mapped before all inputs have values')
      
      b.post(yy);
      actualX = X.Node.CurrValue;
      actualY = Y.Node.CurrValue;
      
      % Verify Signals implementation yields equal output values
      isEqualX = isequal(expectedX, actualX);
      isEqualY = isequal(expectedY, actualY);
      testCase.verifyTrue(isEqualX && isEqualY, 'Failed to assign expected outputs')
      % Verify Name property
      expected = 'mapn\(\w+, \w+, @meshgrid\)';
      testCase.verifyMatches(X.Name, expected, 'Unexpected Name')
      testCase.verifyMatches(Y.Name, '.*[2]', 'Unexpected Name')
      
      % Test transfer function directly
      % No new changes in network;
      args = {testCase.net.Id, [a.Node.Id, b.Node.Id], [], {@meshgrid, 1}};
      [~, valset] = sig.transfer.mapn(args{:});
      testCase.verifyFalse(valset, 'Expected ''valset'' to be false')
      % Update one of the input nodes
      actual = submit(testCase.net.Id, a.Node.Id, xx);
      testCase.verifyEqual(sort([a.Node.Id; X.Node.Id; Y.Node.Id]), actual, ...
        'Unexpected affected node indicies returned')
      [val, valset] = sig.transfer.mapn(args{:});
      testCase.verifyTrue(valset, 'Expected ''valset'' to be true')
      testCase.verifyEqual(val, expectedX, 'Failed to re-evaluate function')
    end
    
    function test_merge(testCase)
      % Tests for map method
      [a, b, c] = deal(testCase.A, testCase.B, testCase.C);
      
      % Test merge
      m = merge(a, b, c);
      testCase.verifyMatches(m.Name, '( \w ~ \w ~ \w )', 'Unexpected Name')
      for s = {c, b, a, b}
        v = rand;
        post(s{1}, v)
        testCase.verifyEqual(m.Node.CurrValue, v, 'Unexpected output using merge')
      end
      
      % Test transfer function directly
      % No new changes in network;
      ids = @(varargin) cellfun(@(s) s.Node.Id, varargin);
      args = {testCase.net.Id, ids(a, b, c), m.Node.Id};
      [~, valset] = sig.transfer.merge(args{:});
      testCase.verifyFalse(valset, 'Expected ''valset'' to be false')
      % Update one of the input nodes
      expected = sort(ids(m, b));
      actual = submit(testCase.net.Id, b.Node.Id, rand);
      testCase.verifyEqual(expected(:), actual, ...
        'Unexpected affected node indicies returned')
      [val, valset] = sig.transfer.merge(args{:});
      testCase.verifyTrue(valset, 'Expected ''valset'' to be true')
      testCase.verifyEqual(val, b.Node.WorkingValue, 'Failed to re-evaluate function')
    end
    
    function test_setEpochTrigger(testCase)
      % Test for setEpochTrigger method 
      [t, dt, x] = deal(testCase.A, testCase.B, testCase.C);
      t.Name = 'duration'; dt.Name = 't'; x.Name = 'x';
      tr = setEpochTrigger(t, dt, x);
      
      % Verify name
      str = sprintf('%1$s\\w/%1$s\\w < \\w s.t. %1$s\\w = \\w', char(916));
      testCase.verifyMatches(tr.Name, str, 'Unexpected Name')
      
      % Verify initialized to false
      testCase.verifyFalse(tr.Node.CurrValue, 'Expected ''valset'' to be false')
      
      % Test trigger release
      dur = 5;
      t.post(dur)
      x.post(.1), x.post(.2)
      dt.post(0), dt.post(dur + 1)
      testCase.verifyTrue(tr.Node.CurrValue, 'Failed to release trigger')
      
      % Test period reset
      affectedIdxs = submit(testCase.net.Id, t.Node.Id, dur);
      changed = applyNodes(testCase.net.Id, affectedIdxs);
      testCase.verifyFalse(ismember(tr.Node.Id, changed), ...
        'Unexpected update to node''s value')
      
      % Test subthreshold time change
      newt = dt.Node.CurrValue + dur/2;
      affectedIdxs = submit(testCase.net.Id, dt.Node.Id, newt);
      changed = applyNodes(testCase.net.Id, affectedIdxs);
      testCase.verifyFalse(ismember(tr.Node.Id, changed), ...
        'Unexpected update to node''s value')

      % Test position reset
      state = tr.Node.Inputs(2).Inputs(1).Inputs(1).Inputs(1);
      newx = x.Node.CurrValue^2;
      x.post(newx);
      testCase.verifyEqual(state.CurrValue.remaining, dur, ...
        'Failed to reset period')
    end
    
    function test_size(testCase)
      % Test for the size method
      a = testCase.A;
      n = randi(10);
      
      % 1 input, 1 output
      sz = size(a);
      testCase.assertTrue(isa(sz, 'sig.Signal'), ...
        ['Unexpected output: expected sig.Signal but returned ', class(sz)])
      a.post(1:n);
      testCase.verifyEqual(sz.Node.CurrValue, [1 n], ...
        'Unexpected value for 1 input, 1 output map of size')
      % Verify Name property
      testCase.verifyMatches(sz.Name, 'size\(\w+\)', 'Unexpected Name')
      
      % 1 input, 2 outputs
      [sz_m, sz_n] = size(a);
      a.post(1:n)
      actual = [sz_m.Node.CurrValue, sz_n.Node.CurrValue];
      testCase.verifyEqual(actual, [1 n], ...
        'Unexpected value for 1 input, 1 output map of size')
      % Verify Name property
      expected = 'size\(\w+\) over dim \d+';
      testCase.verifyMatches(sz_m.Name, expected, 'Unexpected Name')
      testCase.verifyMatches(sz_n.Name, expected, 'Unexpected Name')
      
      % 2 input, 1 output
      [sz] = size(a, 2);
      a.post(1:n)
      testCase.verifyEqual(sz.Node.CurrValue, n, ...
        'Unexpected value for map of size along specified dimention')
      
      % 2 inputs, 2 outputs
      [~, sz] = size(a, 2);  %#ok<*ASGLU>
      % Note in 2019b error id changed
      id = iff(verLessThan('matlab', '9.7'), ...
          'MATLAB:maxlhs', 'MATLAB:size:NumOutNotEqualNumDims');
      testCase.verifyError(@()a.post(1:n), id, 'Unexpected error identifier')
    end
    
    function test_output(testCase)
      % Test for the output method
      a = testCase.A;
      h = output(a);
      
      testCase.verifyTrue(isa(h, 'TidyHandle'), ...
        sprintf('Expected TidyHandle but %s was returned instead', class(h)))
      
      % Test output
      val = randi(10000);
      out = strtrim(evalc('a.post(val)'));
      testCase.verifyEqual(out, num2str(val), 'Unexpected output')
      
      % Test cleanup
      clear('h')
      out = strtrim(evalc('a.post(val)'));
      testCase.verifyEmpty(out, 'Output persists after removing listener')
    end
    
    function test_colon(testCase)
      % Test for the colon method
      [a, b, c] = deal(testCase.A, testCase.B, testCase.C);
      i = 3; j = 14; k = 0.5;
      
      % Test two inputs
      s = a:b;
      a.post(i), b.post(j)
      testCase.verifyEqual(s.Node.CurrValue, i:j, 'Failed on two input')
      testCase.verifyMatches(s.Name, '\w+ : \w+', 'Unexpected Name')
      
      % Test three inputs
      s = a:c:b;
      c.post(k)
      testCase.verifyEqual(s.Node.CurrValue, i:k:j, 'Failed on three input')
      testCase.verifyMatches(s.Name, '\w+ : \w+ : \w+', 'Unexpected Name')
    end
    
    function test_min(testCase)
      % Test for the min method
      [a, b] = deal(testCase.A, testCase.B);
      
      [M,I] = min(a);
      a.post(magic(3))
      testCase.verifyEqual(M.Node.CurrValue, [3,1,2], ...
        'Failed to return minimum values')
      testCase.verifyEqual(I.Node.CurrValue, [2,1,3], ...
        'Failed to return indicies')
      testCase.verifyMatches(M.Name, 'min\(\w+\)', 'Unexpected Name')
      
      [M,I] = min(a,[],b);
      expected = 'min\(\w+\) over dim \w+';
      testCase.verifyMatches(M.Name, expected, 'Unexpected Name')
      post(b,2)
      testCase.verifyEqual(M.Node.CurrValue, [1;3;2], ...
        'Failed to return minimum values')
      testCase.verifyEqual(I.Node.CurrValue, [2;1;3], ...
        'Failed to return indicies')
      
      clear('I')
      M = min(a,b);
      testCase.verifyMatches(M.Name, 'min\(\w+,\w+\)', 'Unexpected Name')
      post(a,magic(2)), post(b,2)
      testCase.verifyEqual(M.Node.CurrValue, [1,2;2,2], ...
        'Failed to return minimum values')
    end
    
    function test_max(testCase)
      % Test for the max method
      [a, b] = deal(testCase.A, testCase.B);
      
      [M,I] = max(a);
      a.post(magic(3))
      testCase.verifyEqual(M.Node.CurrValue, [8,9,7], ...
        'Failed to return maximum values')
      testCase.verifyEqual(I.Node.CurrValue, [1,3,2], ...
        'Failed to return indicies')
      testCase.verifyMatches(M.Name, 'max\(\w+\)', 'Unexpected Name')
      
      [M,I] = max(a,[],b);
      expected = 'max\(\w+\) over dim \w+';
      testCase.verifyMatches(M.Name, expected, 'Unexpected Name')
      post(b,2)
      testCase.verifyEqual(M.Node.CurrValue, [8;7;9], ...
        'Failed to return maximum values')
      testCase.verifyEqual(I.Node.CurrValue, [1;3;2], ...
        'Failed to return indicies')
      
      clear('I')
      M = max(a,b);
      testCase.verifyMatches(M.Name, 'max\(\w+,\w+\)', 'Unexpected Name')
      post(a,magic(2)), post(b,2)
      testCase.verifyEqual(M.Node.CurrValue, [2,3;4,2], ...
        'Failed to return maximum values')
    end
    
    function test_exp(testCase)
      % Test for the exp method
      a = testCase.A;
      b = exp(a);
      e = exp(1);
      
      testCase.verifyMatches(b.Name, 'exp\(\w+\)', 'Unexpected Name')
      a.post(1)
      testCase.verifyEqual(b.Node.CurrValue, e)
    end
    
    function test_erf(testCase)
      % Test for the exp method
      a = testCase.A;
      b = erf(a); % our method to test
      x = [-0.5 0 1 0.72]; % values to test
      e = erf(x); % expected output
      
      testCase.verifyMatches(b.Name, 'erf\(\w+\)', 'Unexpected Name')
      a.post(x)
      testCase.verifyEqual(b.Node.CurrValue, e)
    end
    
    function test_sqrt(testCase)
      % Test for the sqrt method
      a = testCase.A;
      b = sqrt(a); % our method to test
      x = -2:2; % values to test
      e = sqrt(x); % expected output
      
      rootSym = char(hex2dec('221A'));
      testCase.verifyMatches(b.Name, [rootSym,'\(\w+\)'], 'Unexpected Name')
      a.post(x)
      testCase.verifyEqual(b.Node.CurrValue, e)
    end

    function test_str2num(testCase)
      % Test for the str2num method
      a = testCase.A;
      b = a.str2num; % our method to test
      str = '234.54'; % string to test

      testCase.verifyMatches(b.Name, 'str2num\(\w+\)', 'Unexpected Name')
      a.post(str)
      testCase.verifyEqual(b.Node.CurrValue, str2double(str))
    end

    function test_num2str(testCase)
      % Test for the num2str method
      a = testCase.A;
      b = num2str(a); % our method to test
      b_pres = num2str(a, 3);
      n = rand; % number to convert

      testCase.verifyMatches(b.Name, 'num2str\(\w+\)', 'Unexpected Name')
      a.post(n)
      testCase.verifyEqual(b.Node.CurrValue, num2str(n))
      testCase.verifyEqual(b_pres.Node.CurrValue, num2str(n, 3))
    end

    function test_fliplr(testCase)
      % Test for the fliplr method
      a = testCase.A;
      b = fliplr(a); % our method to test
      x = magic(6); % values to test
      e = fliplr(x); % expected output
      
      testCase.verifyMatches(b.Name, 'fliplr\(\w+\)', 'Unexpected Name')
      a.post(x)
      testCase.verifyEqual(b.Node.CurrValue, e)
    end
    
    function test_flipud(testCase)
      % Test for the flipud method
      a = testCase.A;
      b = flipud(a); % our method to test
      x = magic(6); % values to test
      e = flipud(x); % expected output
      
      testCase.verifyMatches(b.Name, 'flipud\(\w+\)', 'Unexpected Name')
      a.post(x)
      testCase.verifyEqual(b.Node.CurrValue, e)
    end
    
    function test_rot90(testCase)
      % Test for the rot90 method
      a = testCase.A;
      b = rot90(a); % our method to test
      x = magic(6); % values to test
      e = rot90(x); % expected output
      
      testCase.verifyMatches(b.Name, 'rot90\(\w+\)', 'Unexpected Name')
      a.post(x)
      testCase.verifyEqual(b.Node.CurrValue, e)
      % test second input
      b = rot90(a,4);
      a.post(x)
      testCase.verifyEqual(b.Node.CurrValue, x)
    end
    
    function test_any(testCase)
      % Test for the any method
      a = testCase.A;
      b = any(a); % our method to test
      x = eye(6); % values to test
      e = any(x); % expected output
      
      testCase.verifyMatches(b.Name, 'any\(\w+\)', 'Unexpected Name')
      a.post(x)
      testCase.verifyEqual(b.Node.CurrValue, e)
      % test second input
      b = any(a,'all');
      a.post(x)
      testCase.verifyTrue(b.Node.CurrValue)
    end
    
    function test_all(testCase)
      % Test for the all method
      a = testCase.A;
      b = all(a); % our method to test
      x = eye(6); % values to test
      e = all(x); % expected output
      
      testCase.verifyMatches(b.Name, 'all\(\w+\)', 'Unexpected Name')
      a.post(x)
      testCase.verifyEqual(b.Node.CurrValue, e)
      % test second input
      b = all(a,'all');
      a.post(x)
      testCase.verifyFalse(b.Node.CurrValue)
    end
    
    function test_floor(testCase)
      % Test for the floor method
      a = testCase.A;
      b = floor(a); % our method to test
      x = 12 + rand; % value to test
      e = floor(x); % expected output
      
      testCase.verifyMatches(b.Name, 'floor\(\w+\)', 'Unexpected Name')
      a.post(x)
      testCase.verifyEqual(b.Node.CurrValue, e)
    end
    
    function test_abs(testCase)
      % Test for the floor method
      a = testCase.A;
      b = abs(a); % our method to test
      x = -4:4; % values to test
      e = abs(x); % expected output
      
      testCase.verifyMatches(b.Name, '|\w+|', 'Unexpected Name')
      a.post(x)
      testCase.verifyEqual(b.Node.CurrValue, e)
    end
    
    function test_sign(testCase)
      % Test for the sign method
      a = testCase.A;
      b = sign(a); % our method to test
      x = -4:4; % values to test
      e = sign(x); % expected output
      
      testCase.verifyMatches(b.Name, 'sgn\(\w+\)', 'Unexpected Name')
      a.post(x)
      testCase.verifyEqual(b.Node.CurrValue, e)
    end
    
    function test_sin(testCase)
      % Test for the sin method
      a = testCase.A;
      b = sin(a); % our method to test
      x = -pi:0.01:pi; % values to test
      e = sin(x); % expected output
      
      testCase.verifyMatches(b.Name, 'sin\(\w+\)', 'Unexpected Name')
      a.post(x)
      testCase.verifyEqual(b.Node.CurrValue, e)
    end
    
    function test_cos(testCase)
      % Test for the cos method
      a = testCase.A;
      b = cos(a); % our method to test
      x = -pi:0.01:pi; % values to test
      e = cos(x); % expected output
      
      testCase.verifyMatches(b.Name, 'cos\(\w+\)', 'Unexpected Name')
      a.post(x)
      testCase.verifyEqual(b.Node.CurrValue, e)
    end
    
    function test_keepWhen(testCase)
      % Test for the keepWhen method
      [a, b] = deal(testCase.A, testCase.B);
      s = a.keepWhen(b);
      testCase.verifyMatches(s.Name, '\w.keepWhen(\w+\)', 'Unexpected Name')
      
      % Post a truthy value to b
      affectedIdxs = submit(testCase.net.Id, b.Node.Id, true);
      changed = applyNodes(testCase.net.Id, affectedIdxs);
      % Check only b's node affected
      testCase.verifyTrue(isequal(affectedIdxs, changed, b.Node.Id), ...
        'Unexpected nodes affected when predicate signal true')
      
      % Post a value to signal a
      v = rand;
      affectedIdxs = submit(testCase.net.Id, a.Node.Id, v);
      changed = applyNodes(testCase.net.Id, affectedIdxs);
      % Check a and s nodes changed
      testCase.verifyTrue(isequal(affectedIdxs, changed, [a.Node.Id;s.Node.Id]), ...
        'Unexpected network behaviour upon posting value to signal a')
      testCase.verifyTrue(isequal(v, a.Node.CurrValue, s.Node.CurrValue), ...
        'Unexpected values of signals a and s')
      
      % Post a non-truthy value to b
      affectedIdxs = submit(testCase.net.Id, b.Node.Id, false);
      changed = applyNodes(testCase.net.Id, affectedIdxs);
      % Check only b's node affected
      testCase.verifyTrue(isequal(affectedIdxs, changed, b.Node.Id), ...
        'Unexpected nodes affected when predicate signal false')
      
      % Post a value to signal a
      v = rand;
      affectedIdxs = submit(testCase.net.Id, a.Node.Id, v);
      changed = applyNodes(testCase.net.Id, affectedIdxs);
      % Check only a's node affected
      testCase.verifyTrue(isequal(affectedIdxs, changed, a.Node.Id), ...
        'Unexpected network behaviour upon posting value to signal a')
      testCase.verifyTrue(v == a.Node.CurrValue && s.Node.CurrValue ~= v, ...
        'Unexpected values of signals a and s')
    end
    
    function test_at(testCase)
      % Test for the at method
      [a, b] = deal(testCase.A, testCase.B);
      s = a.at(b);
      testCase.verifyMatches(s.Name, '\w.at(\w+\)', 'Unexpected Name')
      
      % Post a value to signal a
      v = rand;
      affectedIdxs = submit(testCase.net.Id, a.Node.Id, v);
      changed = applyNodes(testCase.net.Id, affectedIdxs);
      % Check only a changed
      testCase.verifyTrue(isequal(affectedIdxs, changed, a.Node.Id), ...
        'Unexpected network behaviour upon posting value to signal a')
            
      % Post a truthy value to b
      affectedIdxs = submit(testCase.net.Id, b.Node.Id, true);
      changed = applyNodes(testCase.net.Id, affectedIdxs);
      % Check b and s nodes changed
      testCase.verifyTrue(isequal(affectedIdxs, changed, [b.Node.Id;s.Node.Id]), ...
        'Unexpected network behaviour upon posting value to signal b')
      testCase.verifyTrue(isequal(v, a.Node.CurrValue, s.Node.CurrValue), ...
        'Unexpected values of signals a and s')

      % Post a value to signal a
      v = rand;
      affectedIdxs = submit(testCase.net.Id, a.Node.Id, v);
      changed = applyNodes(testCase.net.Id, affectedIdxs);
      % Check only a's node affected: unlike keepwhen, s will not be
      % updated as b (dispite being true) has not changed since last update
      testCase.verifyTrue(isequal(affectedIdxs, changed, a.Node.Id), ...
        'Unexpected network behaviour upon posting value to signal a')
      testCase.verifyTrue(v == a.Node.CurrValue && s.Node.CurrValue ~= v, ...
        'Unexpected values of signals a and s')
      
      % Post a non-truthy value to b
      affectedIdxs = submit(testCase.net.Id, b.Node.Id, false);
      changed = applyNodes(testCase.net.Id, affectedIdxs);
      % Check only b's node affected
      testCase.verifyTrue(isequal(affectedIdxs, changed, b.Node.Id), ...
        'Unexpected nodes affected when predicate signal false')
      
      % Post a value to signal a
      v = rand;
      affectedIdxs = submit(testCase.net.Id, a.Node.Id, v);
      changed = applyNodes(testCase.net.Id, affectedIdxs);
      % Check only a's node affected
      testCase.verifyTrue(isequal(affectedIdxs, changed, a.Node.Id), ...
        'Unexpected network behaviour upon posting value to signal a')
      testCase.verifyTrue(v == a.Node.CurrValue && s.Node.CurrValue ~= v, ...
        'Unexpected values of signals a and s')
    end
    
  end
end