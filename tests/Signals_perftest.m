classdef Signals_perftest < matlab.perftest.TestCase
  
  properties
    net
    A
    B
    C
    func
    verify = false
    results
    reps = 2000
  end
  
  properties (TestParameter)
    ops = num2cell([1:6 10:14 30 40 50])
  end
  
  methods (TestClassSetup)
    
    function createNetwork(testCase)
      testCase.net = sig.Net;
      testCase.A = testCase.net.origin('A');
      testCase.B = testCase.net.origin('B');
      % Add op code map
      keys = cell2mat(testCase.ops);
      vals = {'plus', 'minus', 'times', ...
        'mtimes', 'rdivide', 'mrdivide', ...
        'gt', 'ge', 'lt', 'le', 'eq', ...
        'numel', 'flattenStruct', 'identity'};
      testCase.func = containers.Map(keys, vals);
    end
    
  end
    
  methods (Test)
    
    function test_ops(testCase, ops)
      if ops > 3 && ops < 7
        testCase.C = feval(testCase.func(ops), testCase.B, testCase.A);
        testCase.B.post(magic(6))
      elseif ops == 30
        testCase.C = feval(testCase.func(ops), testCase.A.map(@magic));
      elseif ops == 40
        testCase.C = feval(testCase.func(ops), testCase.B);
        testCase.B.post(struct('A', testCase.A))
      elseif ops == 50
        testCase.C = feval(testCase.func(ops), testCase.B);
        testCase.B.post(magic(60))
      else
        testCase.C = feval(testCase.func(ops), testCase.A, testCase.B);
        testCase.B.post(randi(10000))
      end
      
      while(testCase.keepMeasuring)
        for i = 1:testCase.reps
          post(testCase.A, randi(10000))
        end
      end
    end
    
    function test_benchmark(testCase)
      x = testCase.A;
      resfun = @(x)2.*x + x.*cos(x.*x - 5) + (x > 15) + 1;
      y = resfun(x);
      res = skipRepeats(delta(y));
      
      values = []; %zeros(1,nreps-1);
      vidx = 1;
      
      list = res.onValue(@store);
      res = res.buffer(4); %#ok<NASGU>
      networkInfo(testCase.net.Id)
      while(testCase.keepMeasuring)
        for i = 1:testCase.reps
          post(x, i);
        end
      end
      delete(list)
      
      match = all(values == diff(resfun(1:vidx)));
      testCase.verifyTrue(match, 'signal values were computed incorrectly');
      testCase.verifyEqual(y.Node.CurrValue, resfun(i), ...
        'unexpected current signal value')
      
      function store(v)
        values = [values v];
        vidx = vidx + 1;
      end
    end
    
  end
  
end