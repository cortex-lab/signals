classdef VoidSignal_test < matlab.unittest.TestCase
  
  properties
    Instance
    CachedInstance
  end
  
  methods (TestClassSetup)
    function createVoids(testCase)
      testCase.Instance = sig.void;
      testCase.CachedInstance = sig.void(true);
      testCase.assertTrue(isa(testCase.Instance, 'sig.VoidSignal'))
      testCase.assertTrue(isa(testCase.CachedInstance, 'sig.VoidSignal'))
      testCase.assertTrue(~builtin('isequal', testCase.Instance, testCase.CachedInstance))
    end
  end
  
  methods (Test)
    function test_coverage(testCase)
      % Ensure all methods are covered by VoidSignal class
      sigFcns = unique([methods('sig.Signal');methods('sig.node.Signal')]);
      voidFcns = methods('sig.VoidSignal');
      ignore = {'Signal', 'applyTransferFun', 'node', 'valueChanged'};
      missing = setdiff(setdiff(sigFcns, voidFcns), ignore);
      testCase.verifyEmpty(missing, ...
        sprintf('The following Signals methods not covered by class:\n"%s"', ...
        strjoin(missing, '"\n"')));
    end
    
    function test_methods(testCase)
      % Check all methods return the same instance of the void signal
      validateFcn = @(obj)builtin('isequal', testCase.Instance, obj);
      ignre = {'subsref', 'subsasgn', 'onValue', 'instance', 'listener', 'notify'...
        'addlistener', 'output', 'findprop', 'findobj', 'delete', 'isvalid'};
      fn = setdiff(methods('sig.VoidSignal'), ignre);
      fn = string(fn');
      for m = fn
        try % Try with one input
          void = feval(m, testCase.Instance);
        catch ex
          if strcmp(ex.identifier, 'MATLAB:minrhs')
            % Try with second input
            void = feval(m, testCase.Instance, testCase.Instance);
          else
            rethrow(ex)
          end
        end
        
        testCase.verifyTrue(validateFcn(void), ...
          sprintf('method "%s" failed to return void signal', m))
      end
    end
    
    function test_cache(testCase)
      % Test subscripts are cached when needed
      s = testCase.CachedInstance;
      s.one;
      s.three = s.two * 5;
      
      testCase.verifyTrue(isequal(fieldnames(s.Subscripts), {'one'; 'two'}));
    end
  end
  
end