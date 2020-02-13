classdef rnd_test < matlab.unittest.TestCase
  
  properties
    % Number of samples to take from distribution
    nSamples = 100000
    % Bounds for continuous distributions under test
    bounds = [0.2 0.5]
    % Expected mean for flat hazard / truncated exponential distributions
    lambda = 0.35
    % Correction factor for testing mean of flat hazard / truncated
    % distribution
    correction = 0.05
  end
  
  methods (TestClassSetup)
    
    function ClassSetup(testCase)
      % Check whether dependencies are installed
      required = 'Statistics and Machine Learning Toolbox';
      A = ver;
      assert(ismember(required, {A.Name}), '%s not installed', required)
      
      % Set default seed for reproducibility
      orig = rng;
      testCase.addTeardown(@rng, orig)
      rng('default')
    end
    
  end
  
  methods (Test)
    function test_exp(testCase)
      sz = [1, testCase.nSamples];
      b = testCase.bounds;
      
      % Test unadjusted
      tolerance = 0.065;
      samples = rnd.exp(testCase.lambda, sz, b) ;
      testCase.verifySize(samples, sz, 'Unexpected size returned')
      testCase.verifyTrue(all(samples >= b(1) & samples <= b(2)), ...
        'Samples outside of distribution')
      testCase.verifyEqual(mean(samples), testCase.lambda, 'RelTol', tolerance)
      
      % Test adjusted
      samples = rnd.exp(testCase.lambda, sz, b, true);
      tolerance = 0.001;
      testCase.verifySize(samples, sz, 'Unexpected size returned')
      testCase.verifyTrue(all(samples >= b(1) & samples <= b(2)), ...
        'Samples outside of distribution')
      testCase.verifyEqual(mean(samples), testCase.lambda, 'RelTol', tolerance)
      
      % Test errors
      fcn = fun.partial(@rnd.exp, testCase.lambda, sz);
      testCase.verifyError(@()fcn([1 0]), 'signals:rnd:nonMonotonicBounds')
      testCase.verifyError(@()fcn([-1 0]), 'signals:rnd:negativeBounds')
      testCase.verifyError(@()rnd.exp(-3), 'signals:rnd:negativeLambda')
    end
    
    function test_uni(testCase)
      b = testCase.bounds;
      sz = [1 testCase.nSamples];
      
      samples = rnd.uni(b, sz);
      tolerance = 0.01;
      testCase.verifySize(samples, sz, 'Unexpected size returned')
      testCase.verifyTrue(all(samples >= b(1) & samples <= b(2)), ...
        'Samples outside of distribution')
      testCase.verifyEqual(mean(samples), mean(b), 'RelTol', tolerance)
    end
    
    function test_sample(testCase)
      b = testCase.bounds;
      % Test input length == 0
      testCase.verifyEqual(rnd.sample, 0, 'Unexpected output on zero inputs')
      % Test input length == 1
      r = rand;
      testCase.verifyEqual(rnd.sample(r), r, 'Unexpected output on input scalar')
      % Test input length == 2
      samples = arrayfun(@(~)rnd.sample(b), 1:testCase.nSamples);
      tolerance = 0.01;
      testCase.verifyTrue(all(samples >= b(1) & samples <= b(2)), ...
        'Samples outside of distribution')
      testCase.verifyEqual(mean(samples), mean(b), 'RelTol', tolerance)
      % Test input length == 3
      pars = [testCase.bounds testCase.lambda];
      samples = arrayfun(@(~)rnd.sample(pars), 1:testCase.nSamples);
      % Due to the distribution being trimmed, the expected value is a
      % little lower than the input. 
      mu = mean(samples) - testCase.correction;
      tolerance = 0.01;
      testCase.verifyTrue(all(samples >= pars(1) & samples <= pars(2)), ...
        'Samples outside of distribution')
      testCase.verifyEqual(mu, pars(3), 'RelTol', tolerance)
      % Test input length > 4
      iMax = 20;
      pars = randi(iMax, 1, 5);
      samples = arrayfun(@(~)rnd.sample(pars), 1:testCase.nSamples);
      testCase.verifyTrue(all(ismember(samples, pars) & samples <= iMax), ...
        'Samples outside of distribution')
    end
  end
  
end