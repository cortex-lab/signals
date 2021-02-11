classdef Output_test < matlab.mock.TestCase
  properties
    net
    A
    B
    C
    Output
    Mock
    Behaviour
    ChannelNames = {'rewardValve', 'laserShutter'}
  end
  
  methods (TestClassSetup)
    function mockController(testCase)
      chanList = testCase.ChannelNames;
      try
        import matlab.mock.actions.Invoke
        [stub, behaviour] = createMock(testCase, ?hw.DaqController);
        stub.ChannelNames = chanList;
        stub.DaqChannelIds = chanList;  % To increase NumChannels
        stub.SignalGenerators = repmat(hw.PulseSwitcher, size(chanList));
        when(withAnyInputs(behaviour.command), Invoke(@nop))
      catch
        props = {'ChannelNames', 'SignalGenerators', 'NumChannels'};
        [stub, behaviour] = createMock(testCase, ...
          'AddedMethods', {'command'},...
          'AddedProperties', props);
        testCase.assignOutputsWhen(get(behaviour.ChannelNames), chanList)
        testCase.assignOutputsWhen(get(behaviour.NumChannels), length(chanList))
        testCase.assignOutputsWhen(get(behaviour.SignalGenerators), 1)
      end
      
      testCase.Mock = stub; testCase.Behaviour = behaviour;
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
  
  methods (TestMethodTeardown)
    function cleanupRegistry(testCase)
      if ~isempty(testCase.Output)
        cleanup(testCase.Output)
      end
      testCase.clearMockHistory(testCase.Mock)
    end
  end
    
  methods (Test)
    function test_entryAdded(testCase)
      % Test for subassign and signal update behaviour
      testCase.Output = sig.Output(testCase.Mock);
      
      % Assign
      field = testCase.ChannelNames{end};
      testCase.Output.(field) = testCase.A;
      
      % Reference
      testCase.verifyEqual(testCase.Output.(field), testCase.A)
      
      % Test for warning on unknown channel
      testCase.verifyWarning(@() assign('non', testCase.B), 'signals:sig:Outputs:channelNotFound')
      
      function assign(field, value)
        testCase.Output.(field) = value;
      end
      
      % Verfy DaqController command called at the right time
      value = 5;
      testCase.B.post(value)
      testCase.verifyNotCalled(withAnyInputs(testCase.Behaviour.command))
      testCase.A.post(value)
      testCase.verifyCalled(testCase.Behaviour.command([0 value]))
      
      % Verify logs
      s = logs(testCase.Output);
      expected = {[field 'Values'], [field 'Times'], 'nonValues', 'nonTimes'};
      testCase.verifyEqual(fieldnames(s), expected')
    end
    
    function test_rewardOut(testCase)
      % Test for assigning to 'reward' output.  This is done by SignalsExp.
      % A virtual channel is created called 'reward'.
      testCase.Output = sig.Output(testCase.Mock);
      testCase.Output.multiplex('reward', 'rewardValve')
      
      % Assign
      testCase.Output.reward = testCase.A;
      
      % Reference
      testCase.verifyEqual(testCase.Output.reward, testCase.A)
      
      % Verfy DaqController command called with correct input
      value = rand;
      testCase.A.post(value)
      testCase.verifyCalled(testCase.Behaviour.command([value 0]))
      
      % Verify output as cell
      value = {rand(1, 3)};
      testCase.A.post(value)
      testCase.verifyCalled(testCase.Behaviour.command([value 0]))
    end
    
    function test_multiplex(testCase)
      % Test for multiplex method
      testCase.Output = sig.Output(testCase.Mock);
      
      % Assign with channel names
      multiplex(testCase.Output, 'both', testCase.ChannelNames(1:2))
      % Assign with ids
      multiplex(testCase.Output, 'together', [1 2])
      testCase.Output.both = testCase.A;
      testCase.Output.together = testCase.B;
      
      value = [rand rand];
      testCase.A.post(value)
      testCase.verifyCalled(testCase.Behaviour.command(value))
      
      % Test input validation
      try
        testCase.Output.multiplex('a/b', [1 2])
        testCase.verifyTrue(false, 'failed to throw error on invalid var name')
      catch
      end
      
      % Test multiple virtual names: should be able to multiplex a virtual
      % channel name if it is already defined
      testCase.Output.multiplex('rename', 'both')
      testCase.Output.rename = testCase.B;
      v = [rand, rand];
      testCase.B.post(v)
      testCase.verifyCalled(testCase.Behaviour.command(v))
    end
    
    function test_empty(testCase)
      % Test for returning upon an empty controller
      testCase.Output = sig.Output([], @now);
      
      testCase.Output.both = testCase.A;
      
      value = rand;
      testCase.A.post(value)
      testCase.verifyNotCalled(withAnyInputs(testCase.Behaviour.command))
      
      % Check still logs
      s = logs(testCase.Output);
      testCase.verifyNotEmpty(s)
    end

  end
end