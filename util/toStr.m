function s = toStr(v, inline)
%TOSTR Returns a char representation of the input
%   Returns a char array representing the input data for printing to the
%   command.  For objects, the output of calling its `str` method is used.
%   If no such method is defined, the Name property is used.  Otherwise the
%   class name is returned.  For structs, the fieldnames and data types are
%   returned.  Cell arrays are not supported.  If the inline flag is true,
%   the input is represented as a 1xN char array.
%
%   Input:
%     v : Data to be represented as a char array
%     inline (logical) : If true, v is represented as 1xN char vector
%
%   Output:
%     s (char) : A string representation of the input data
%
%   Examples:
%     % Represent a matrix as char array
%     toStr(magic(6))
% 
%     ans =
% 
%       6×22 char array
% 
%         '35   1   6  26  19  24'
%         ' 3  32   7  21  23  25'
%         '31   9   2  22  27  20'
%         ' 8  28  33  17  10  15'
%         '30   5  34  12  14  16'
%         ' 4  36  29  13  18  11'
%
%     % Represent a numeric vector as char vector
%     toStr((1:5)', true)
% 
%     ans =
% 
%         '[1; 2; 3; 4; 5]'
% 


if nargin > 1 && inline == true && ~isstruct(v) && ~isscalar(v)
  % Format the string to fit on a single line
  if ~isvector(v) || numel(v) > 5
    s = sprintf('%ix%i %s', size(v,1), size(v,2), class(v));
  else % process small row and column vectors
    if iscolumn(v)
      if isnumeric(v)
        s = sprintf('%.4g; ', v); 
      else % Most likely string or char
        s = cell2mat(mapToCell(@(v) [char(v) '; '], v)');
      end
      s = ['[' s(1:end-2) ']']; 
    elseif isrow(v) && isnumeric(v)
      s = ['[' toStr(v, 0) ']'];
    end
  end
  return
end


if ischar(v)
  s = v;
elseif isempty(v)
  s = '[]';
elseif isstring(v)
  s = char(v);
elseif isobject(v)
  if any(strcmp(methods(v), 'str'))
    s = str(v);
  elseif any(strcmp(properties(v), 'Name'))
    s = v.Name;
  else
    s = class(v);
  end
elseif isnumeric(v)
  s = num2str(v);
elseif islogical(v)
  if numel(v) == 1
    if v
      s = 'true';
    else
      s = 'false';
    end
  else
    s = num2str(v);
  end
elseif isstruct(v)
  % @todo implement toStr on structs
  s = ['<' strJoin(fieldnames(v), ',') '>'];
elseif isa(v, 'function_handle')
  s = func2str(v);
  if s(1) ~= '@'
    s = ['@' s];
  end
end

end

