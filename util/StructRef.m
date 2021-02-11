classdef StructRef < handle
  %UNTITLED2 Summary of this class goes here
  %   Detailed explanation goes here
  %   TODO Add Reserved flag to subassign
  
  properties
    Name = ''
  end

  properties (SetAccess = protected)
    Entries = struct()
    EntryNames = {}
    Reserved = {'Name'}
  end
  
  methods (Sealed)
    function A = subsasgn(this, s, varargin)
      if any(strcmp(this.Reserved, s(1).subs))
        % If subscripted reference is a reserved property, use builtin
        A = builtin('subsasgn', this, s, varargin{:});
      else
        % Otherwise assign to Entries property
        newentry = false;
        if strcmp(s(1).type, '.') && ~any(strcmp(this.EntryNames, s(1).subs))
          newentry = true;
          newentryname = s(1).subs;
        end
        this.Entries = builtin('subsasgn', this.Entries, s, varargin{:});
        A = this;
        if newentry
          this.EntryNames = [this.EntryNames {newentryname}];
          % Reassign with the subclassed method
          this.Entries.(newentryname) = entryAdded(this, newentryname, this.Entries.(newentryname));
        end
      end
    end
    
    function [varargout] = subsref(this, s)
      if any(strcmp(this.Reserved, s(1).subs))
        % If subscripted reference is a reserved property, use builtin
        [varargout{1:nargout}] = builtin('subsref', this, s);
      else % Otherwise return entry value
        [varargout{1:nargout}] = subsref(this.Entries, s);
      end
    end
  end

  methods
    function n = fieldnames(this)
      n = this.EntryNames';
    end
    
    function c = struct2cell(this)
      c = struct2cell(this.Entries);
    end
    
    function tf = isfield(this, varargin)
      tf = isfield(this.Entries, varargin{:});
    end
    
    function value = entryAdded(this, name, value)
%       fprintf('entry %s:%s added\n', name, toStr(value));
    end
  end
end