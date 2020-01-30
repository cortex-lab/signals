classdef VoidSignal_test < matlab.unittest.TestCase
  
  properties
    % Handle to VoidSignal object
    Instance
    % Handle to VoidSignal object that will cache its subsrefs
    CachedInstance
  end
  
  methods (TestClassSetup)
    function createVoids(testCase)
      % Store two instances of the VoidSignal class
      testCase.Instance = sig.void;
      testCase.CachedInstance = sig.void(true);
      testCase.assertTrue(isa(testCase.Instance, 'sig.VoidSignal'))
      testCase.assertTrue(isa(testCase.CachedInstance, 'sig.VoidSignal'))
      % Ensure both instances are not the identical
      testCase.assertTrue(~builtin('isequal', testCase.Instance, testCase.CachedInstance))
    end
  end
  
  methods (Test)
    function test_coverage(testCase)
      % Ensure all methods are covered by VoidSignal class
      sigFcns = unique([methods('sig.Signal');methods('sig.node.Signal')]);
      voidFcns = methods('sig.VoidSignal'); % List methods
      ignore = {'Signal', 'applyTransferFun', 'node', 'valueChanged'};
      missing = setdiff(setdiff(sigFcns, voidFcns), ignore);
      testCase.verifyEmpty(missing, ...
        sprintf('The following Signals methods not covered by class:\n"%s"', ...
        strjoin(missing, '"\n"')));
    end
    
    function test_methods(testCase)
      % Check all methods return the same instance of the void signal.
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
      % Check subscripts 'one' and 'two' were recorded
      testCase.verifyTrue(isequal(fieldnames(s.Subscripts), {'one'; 'two'}));
    end
    
    function test_subsref(testCase)
      % Test various weird and wonderful subscript references
      % TODO As of 19.03.19 "A(I:end)" and "A.map(I).J" throw errors
      % @body Check these work with standard Signals objects.  If so, the
      % VoidSignal class should be updated, otherwise we may wish to
      % consider implementing these.
      [A, I, J] = deal(testCase.Instance); % Assign voids to vars
      validateFcn = @(obj)builtin('isequal', testCase.Instance, obj);
      fn = {@()A('key'), @()A(4), @()A(I), @()A.I, @()A.I.J, @()A(1:4), ...
        @()A{I}, @()A{I}, @()A{I.J}, @()A{I(end)}, @()A(I).J, @()A(I,J), ...
        @()A(I,J,I), @()A(:,I)};
      
      for i = 1:length(fn)
        try % Test each subsref
          void = feval(fn{i});
        catch % If there's an error set void is nil
          void = nil;
        end
        sref = erase(func2str(fn{i}), '@()');
        testCase.verifyTrue(validateFcn(void), ...
          sprintf('subsref "%s" failed to return void signal', sref))
      end
    end
    
    function test_newInstance(testCase)
      % Test that calling the constructor returns the same Void instance
      testCase.addTeardown(@()refresh)
      old = testCase.Instance;
      new = sig.void;
      testCase.verifyTrue(builtin('isequal',old,new), 'Failed to return identical instance')
      
      % Extra careful test
      delete(new)
      testCase.verifyTrue(~isvalid(old), 'Failed to return identical instance')
      
      function refresh()
        clear('VoidSignal')
        testCase.Instance = sig.void;
        assert(isvalid(testCase.Instance))
      end
    end

  end
  
end