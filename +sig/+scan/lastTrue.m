function n = lastTrue(n, pred)
%SIG.SCAN.LASTTRUE Iterate number while predicate false
%   Function used with scan to count the update on which a predicate was
%   true.
%
%   Example:
%     % While repeatLastTrial is true, repeatNum iterates, otherwise it
%     % resets back to 1
%     repeatNum = repeatLastTrial.scan(@sig.scan.lastTrue, 0) + 1;
%
% See also SIG.SCAN, EXP.TRIALCONDITIONS

if pred
  n = 0;
else
  n = n + 1;
end

end

