classdef toStr_test < matlab.unittest.TestCase
  methods (Test)
    function test_toStr(testCase)
      % Test string
      str = "Hello my %s";
      actual = toStr(str);
      testCase.verifyTrue(ischar(actual) && strcmp(actual, str), ...
      'Failed for string inputs') 
    
      % Test vector
      vec = [1, 2, 3];
      actual = toStr(vec);
      testCase.verifyTrue(ischar(actual) && strcmp(actual, '1  2  3'), ...
      'Failed for vector inputs') 
    
      n = randi(1000);
      actual = toStr(n);
      testCase.verifyTrue(ischar(actual) && strcmp(actual, num2str(n)), ...
      'Failed for scalar numeric inputs') 
    
      % Test objects
      actual = toStr(testCase);
      testCase.verifyTrue(ischar(actual) && strcmp(actual, class(testCase)), ...
      'Failed for object inputs')
    
      s = sig.node.Signal(sig.node.Node(sig.Net));
      s.Node.FormatSpec = sprintf('%i', n);
      actual = toStr(s);
      testCase.verifyTrue(ischar(actual) && strcmp(actual, num2str(n)), ...
      'Failed for object inputs')
    
      % Test empty
      actual = toStr(nil);
      testCase.verifyTrue(ischar(actual) && strcmp(actual, '[]'), ...
      'Failed for empty inputs') 
    
      % Test logicals
      actual = toStr(true);
      testCase.verifyTrue(ischar(actual) && strcmp(actual, 'true'), ...
      'Failed for scalar logical inputs') 
    
      actual = toStr(zeros(1,2, 'logical'));
      testCase.verifyTrue(ischar(actual) && strcmp(actual, '0  0'), ...
      'Failed for logical inputs') 
    
      % Test function handles
      actual = toStr(@(x,y)plus(y,x));
      testCase.verifyTrue(ischar(actual) && strcmp(actual, '@(x,y)plus(y,x)'), ...
      'Failed for function handle inputs') 
    end
    
    function test_inline(testCase)
      % Test the inline flag.  Should return 1xN char array for all data
      % types
      
      % Test large row vector
      vec = 1:10;
      actual = toStr(vec, 1);
      testCase.verifyEqual(actual, '1x10 double', ...
        'Failed for long row vector numeric inputs')

      % Test numeric column vector
      actual = toStr(vec(1:4)', 1);
      testCase.verifyEqual(actual, '[1; 2; 3; 4]', ...
        'Failed for small column vector numeric inputs')

      % Test string column vector
      actual = toStr(["A "; "KK"; "J"], 1);
      testCase.verifyEqual(actual, '[A ; KK; J]', ...
        'Failed for small column vector string inputs')

    end
  end
end
    
