classdef StructRef_test < matlab.unittest.TestCase
  properties
    Struct
  end
  
  methods (TestMethodSetup)
    function createStructRef(testCase)
      testCase.Struct = StructRef;
    end
  end
  
  methods (Test)
    function test_entryAdded(testCase)
      % Test for subassign and subsref
      
      testCase.verifyEmpty(fieldnames(testCase.Struct))
      
      % Assign
      v = rand;
      field = 'A';
      testCase.Struct.(field) = v;
      
      % Reference
      testCase.verifyEqual(testCase.Struct.(field), v)
      
      % Reference non-existent
      try
        testCase.Struct.B
        testCase.verifyTrue(false, 'failed to throw non-existent field error')
      catch ex
        testCase.verifyEqual(ex.identifier, 'MATLAB:nonExistentField');
      end
      
      % Assign multiple levels
      v = rand;
      testCase.Struct.B.one = v;
      testCase.verifyEqual(testCase.Struct.B.one, v)
    end
    
    function test_fieldnames(testCase)
      % Tests the fieldnames method
      fields = {'one', 'two', 'three'};
      for f = fields
        testCase.Struct.(f{:}) = rand;
      end
      testCase.verifyEqual(fieldnames(testCase.Struct)', fields)
    end
    
    function test_reserved(testCase)
      % Test setting and referencing the Name field
      name = 'foobar';
      testCase.Struct.Name = name;
      testCase.verifyEqual(testCase.Struct.Name, name)
    end
      
    function test_struct2cell(testCase)
      % Tests for struct2cell method
      fields = {'one', 'two', 'three'};
      values = [1, 2, 3];
      for i = 1:length(fields)
        testCase.Struct.(fields{i}) = values(i);
      end

      C1 = struct2cell(testCase.Struct);
      C2 = num2cell(values)';
      testCase.verifyEqual(C1, C2)
    end
    
    function test_isfield(testCase)
      field = 'A';
      testCase.Struct.(field) = rand;
      
      testCase.verifyTrue(isfield(testCase.Struct, field))
      testCase.verifyFalse(isfield(testCase.Struct, 'B'))
    end
  end
end