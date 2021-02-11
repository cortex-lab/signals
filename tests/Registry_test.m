classdef Registry_test < matlab.unittest.TestCase
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
      
      testCase.addTeardown(@delete, testCase.A)
      testCase.addTeardown(@delete, testCase.B)
    end
  end
    
  methods (Test)
    function test_entryAdded(testCase)
      % Test for subassign and subsref
      registry = sig.Registry;
      
      % Assign
      field = 'A';
      registry.(field) = testCase.A;
      
      % Reference
      testCase.verifyEqual(registry.(field), testCase.A)
      
      % Reference non-existent
      try
        registry.B
        testCase.verifyTrue(false, 'failed to throw non-existent field error')
      catch ex
        testCase.verifyEqual(ex.identifier, 'MATLAB:nonExistentField');
      end
      
      % Assign scalar value
      try
        registry.B = rand;
        testCase.verifyTrue(false, 'failed to throw type error error')
      catch ex
        testCase.verifyMatches(ex.identifier, 'typeError');
      end
      
      % Verify that we can work with subscriptable signals
      b = testCase.B.subscriptable();
      registry.B = b;
      testCase.verifyTrue(isa(registry.B.foo, 'sig.Signal'))
    end
    
    function test_logs(testCase)
      % Tests the logs method and clock function input
      registry = sig.Registry;
      registry.a = testCase.A;
      registry.b = testCase.B;
      
      h = testCase.B.into(testCase.A);  %#ok<NASGU>
      registry.a.post(1)
      registry.a.post(2)
      testCase.A.post(3)
      testCase.B.post(4)
      registry.b.post(5)
      
      s = logs(registry);
      expected = {'aValues', 'aTimes', 'bValues', 'bTimes'}';
      testCase.verifyEqual(fieldnames(s), expected)
      
      testCase.verifyEqual(s.aValues, 1:5)
      testCase.verifyEqual(s.bValues, 4:5)
      dt = GetSecs() - s.bTimes(end);
      testCase.verifyTrue(dt > 0 && dt < 10)
      
      % Test the clock function and offset
      registry = sig.Registry(@now);
      registry.a = testCase.A;
      for i = 1:5, registry.a.post(rand), end
      s = logs(registry, now + 0.1);
      testCase.verifyTrue(all(s.aTimes < 0) && all(s.aTimes > -1))
    end
  end
end