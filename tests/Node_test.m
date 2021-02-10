classdef Node_test < matlab.unittest.TestCase
  properties
    net
  end
  
  methods (TestClassSetup)
    function createNetwork(testCase)
      deleteNetwork()
      testCase.net = sig.Net(10);
      testCase.addTeardown(@delete, testCase.net)
    end
  end
  
  methods (Test)
    function test_init(testCase)
      % Test for constructor method
      % Create a simple root node
      node = sig.node.Node(testCase.net);
      testCase.verifyEqual(node.NetId, testCase.net.Id, 'Unexpected network ID')
      testCase.verifyEqual(node.Net, testCase.net, 'Unexpected network')
      netSize = evalc('networkInfo(node.NetId)');
      testCase.verifyMatches(netSize, '1/(\d)+ active nodes')
      nodeInfo = evalc('networkInfo(node.NetId, node.Id)');
      expected = '{#0,value:NULL,inputs:[],targets:[],transferer{funName:@sig.transfer.nop,opCode:0}}';
      testCase.verifyEqual(strip(nodeInfo), expected)
      testCase.verifyEmpty(node.Inputs)

      % Test creating node with input
      node = sig.node.Node(node, 'sig.transfer.identity');
      testCase.verifyNumElements(node.Inputs, 1)
      nodeInfo = evalc('networkInfo(node.NetId, node.Id)');
      expected = '{#1,value:NULL,inputs:[0],targets:[],transferer{funName:@sig.transfer.identity,opCode:0}}';      
      testCase.verifyEqual(strip(nodeInfo), expected)
    end
    
    function test_formatSpec(testCase)
      % Tests Name setter and getter as well as names method
      a = sig.node.Node(testCase.net);
      b = sig.node.Node(testCase.net);
      
      a.Name = 'A';
      b.Name = 'B';
      
      testCase.verifyEqual(a.Name, 'A')
      
      c = sig.node.Node([a b], 'sig.transfer.mapn', @times);
      c.FormatSpec = '%s.*%s';
      
      testCase.verifyEqual(c.Name, 'A.*B', 'Unexpected format specification')
      a.Name = 'AA';
      testCase.verifyEqual(c.Name, 'AA.*B', 'Unexpected format specification')
      actual = names(c.DisplayInputs);
      testCase.verifyEqual(actual, {'AA'; 'B'})
      
      c.Name = 'C';
      testCase.verifyEqual(c.Name, 'C', 'Unexpected format specification')
    end
    
    function test_ids(testCase)
      % Tests for ids method
      a = sig.node.Node(testCase.net);
      b = sig.node.Node(testCase.net);
      ii = ids([a, b]);
      testCase.verifyEqual(ii, [a.Id, b.Id])
    end
      
    function test_setInputs(testCase)
      % Tests for setInputs method
      src = sig.node.Node(testCase.net);
      dst = sig.node.Node(src, 'sig.transfer.map', @sqrt);
      dst.FormatSpec = 'sqrt(%s)';
      
      affected = submit(src.NetId, src.Id, 4);
      applyNodes(src.NetId, affected)
      
      testCase.verifyEqual(affected, ids([src, dst])')
      testCase.verifyEqual(dst.CurrValue, 2)
      
      % Rewire
      src2 = sig.node.Node(testCase.net);
      src2.Name = 'A';
      dst.setInputs(src2)
      
      affected = submit(src.NetId, src2.Id, 25);
      applyNodes(src.NetId, affected)
      testCase.verifyEqual(affected, ids([src2, dst])')
      testCase.verifyEqual(dst.CurrValue, 5)
      testCase.verifyEqual(dst.Inputs, src2)
      testCase.verifyEqual(dst.Name, 'sqrt(A)')
    end
  end
end