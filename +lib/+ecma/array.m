classdef array < handle
	properties
		data = {}		% cell array
	end
	
	properties(SetAccess = private, Dependent)
		length
	end
	
	methods
		function obj=array(varargin)
			obj.push(varargin{:});
		end
		
		% --- information ---
		
		% DESCRIPTION
		% The number of elements in the array
		%
		% RETURN
		%	<double>
		%
		function n=get.length(obj)
			n = numel(obj.data);
		end
		
		% --- io ---
		
		% DESCRIPTION
		% Loads data from a mat-file located at `path`. The mat-file must
		% contain a variable `elm` of type `cell` containing the array
		% values.
		%
		% NOTE: this method alters the object!
		%
		% INPUT
		%	path		<string>			the path to a mat-file
		%									containing data
		%
		% RETURN
		%	<lib.ecma.array>
		%
		function obj = load(obj,path)
			load(path,'elm');
			obj.data = elm;
		end
		
		% DESCRIPTION
		% Saves data into a mat-file located at 'path. The mat-file will
		% contain a variable `elm` of type `cell` containing the array
		% values.
		%
		% INPUT
		%	path		<string>			the path to a mat-file to be
		%									written or overwritten
		%
		% RETURN
		%	<lib.ecma.array>
		%
		function obj = save(obj,path)
			elm = obj.data;
			save(path,'elm');
		end
		
		% --- intrinsic array manipulation ---
		
		% DESCRIPTION
		% Add new entries at the end of the array.
		%
		% - If no argument is passed, then the array is not affected.
		%
		% - If only one argument is passed and it is either a cell or an
		%	array then that argument is going to be spread.
		%
		% NOTE: this method alters the object!
		%
		% INPUT
		%	*varargin*	*any type*			data to be added
		%
		% RETURN
		%	<lib.ecma.array>
		%
		function obj=push(obj,varargin)
			if numel(varargin) == 1
				value = varargin{1};
				
				switch class(value)
					case 'double'
						for ii = 1:numel(value)
							obj.data{end+1} = value(ii);
						end

					case 'cell'
						for ii = 1:numel(value)
							obj.data{end+1} = value{ii};
						end
						
					otherwise
						obj.data{end+1} = value;
				end
			else
				for ii = 1:numel(varargin)
					obj.data{end+1} = varargin{ii};
				end
			end
		end
		
		% DESCRIPTION
		% Sorts the array according to the return value of `callback`, a
		% mapping function `(obj, id, array) => {...}`. `dim` is an optional
		% parameter and tells along which dimension the array should be
		% sorted if `lib.ecma.array` is a multi-dimensional array then.
		%
		% NOTE: this method alters the object!
		%
		% INPUT
		%	callback		<function_handle>		callback function
		%
		% RETURN
		%	<lib.ecma.array>
		%
		function obj=sort(obj,callback,varargin)
			[~,sx] = sort(obj.accumulate(callback),varargin{:});
			
			obj.data = obj.data(sx);
		end
		
		
		% DESCRIPTION
		% Reverses simply the order of elements stored in the array.
		%
		% NOTE: this method alters the object!
		%
		% INPUT
		%	none
		%
		% RETURN
		%	<lib.ecma.array>
		%
		function obj=reverse(obj)
			obj.data = obj.data(end:-1:1);
		end
		
		% --- element extraction ---
		
		% DESCRIPTION
		% Returns the id of the first match of `element`. In case of a
		% callback function, i.e. `function_handle`, of the type 
		% `(obj, id, array) => {...}` which returns a booloan (`true` or
		% `false`) then `indexOf` returns the id of the first match. It is
		% a match when the given callback function returns `true`.
		%
		% INPUT
		%	callback		<function_handle>		callback function
		%
		% RETURN
		%	<double>
		%
		function id=indexOf(obj,callback)
			id = [];
			switch class(callback)
				case 'char'
					for ii=1:numel(obj.data)
						if strcmp(callback,obj.data{ii})
							id = ii;
							break
						end
					end
					
				case 'double'
					for ii=1:numel(obj.data)
						if callback == obj.data{ii}
							id = ii;
							break
						end
					end
					
				case 'function_handle'
					for ii=1:numel(obj.data)
						if(callback(obj.data{ii}))
							id = ii;
							break
						end
					end
			end
		end
		
		% DESCRIPTION
		% Returns the first match of `element` for a callback function of
		% the type `(obj, id, array) => {...}` which returns a booloan
		% (`true` or `false`). It is a match when the given callback
		% function returns `true`.
		%
		% INPUT
		%	callback		<function_handle>		callback function
		%
		% RETURN
		%	*element*
		%
		function elm=find(obj,callback)
			elm = [];
			fWrap = obj.getFunctionWrapper(callback);
			
			for ii=1:numel(obj.data)
				if(fWrap(obj.data{ii}))
					elm = obj.data{ii};
					break
				end
			end
		end
		
		% DESCRIPTION
		% Returns the element for which `callback`, a mapping function 
		% `(obj, id, array) => {...}`, returns the minimal value.
		%
		% INPUT
		%	callback		<function_handle>		callback function
		%
		% RETURN
		%	*element*
		%	<double>
		%
		function [elm,kk]=min(obj,callback)
			arr = obj.accumulate(callback);
			kk = find(arr == min(arr));
			elm = obj.data{kk};
		end
		
		% --- validation ---
		
		% DESCRIPTION
		% Checks every element with the `callback` function of the type 
		% `(obj, id, array) => logical`. Returns `true` if **all** elements
		% pass the check. Otherwise `false` is returned.
		%
		% INPUT
		%	callback		<function_handle>		callback function
		%
		% RETURN
		%	<logical>
		%
		function b=every(obj,callback)
			fWrap = obj.getFunctionWrapper(callback);
			
			b = true;
			for ii=1:obj.length
				if ~fWrap(obj.data{ii})
					b = false;
					break;
				end
			end
		end
		
		% DESCRIPTION
		% Checks every element with the `callback` function of the type
		% `(obj, id, array) => logical`. Returns `true` if **at least one**
		% element passes the check. Otherwise `false` is returned if no
		% element passes the check.
		%
		% INPUT
		%	callback		<function_handle>		callback function
		%
		% RETURN
		%	<logical>
		%
		function b=some(obj,callback)
			fWrap = obj.getFunctionWrapper(callback);
			
			b = false;
			for ii=1:obj.length
				if fWrap(obj.data{ii})
					b = true;
					break;
				end
			end
		end
		
		% --- extrinsic manipulation ---
		
		% DESCRIPTION
		% Slices the array from `start`-index till the `end`-index and
		% returns a new instance of `lib.ecma.array` which contains the
		% sliced elements.
		%
		% * The optional parameter *end* (default: array length) tells where to stop slicing
		% * The optional parameter *start* (default: 1) tells where to start.
		% * If no arguments are passed a copy of the array is returned
		%
		% INPUT
		%	start		<double>		start of slicing (optional)
		%	end			<double>		end of slicing (optional)
		%
		% RETURN
		%	<lib.ecma.array>
		%
		function arr=slice(obj,varargin)
			Q = lib.ecma.struct(...
				'start',	1, ...
				'end',		obj.length,...
				varargin{:} ...
			);
			
			ch = str2func(class(obj));
			arr = ch(obj.data{Q.start:Q.end});
		end
		
		% DESCRIPTION
		% Picks the elements of given ids (in given order) and return a
		% new array containing these elements.
		%
		% * If no arguments are passed an empty array is returned.
		%
		% INPUT
		%	id1		<double>			(optional)
		%	...
		%	idN		<double>			(optional)
		%
		% RETURN
		%	<lib.ecma.array>
		%
		function arr = pick(obj,varargin)
			ch = str2func(class(obj));
			arr = ch(obj.data{varargin{:}});
		end
		
		% DESCRIPTION
		% Checks every element with the `callback` function of the type
		% `(obj, id, array) => logical` and returns a new instance of
		% `lib.ecma.array` containing all elements which passes the
		% `callback` check.
		%
		% INPUT
		%	callback		<function_handle>		callback function
		%
		% RETURN
		%	<lib.ecma.array>
		%
		function arr=filter(obj,callback)
			ch = str2func(class(obj));
			arr = ch();
			fWrap = obj.getFunctionWrapper(callback);
			
			for ii=1:numel(obj.data)
				if fWrap(obj.data{ii})
					arr.push(obj.data{ii});
				end
			end
		end
		
		% DESCRIPTION
		% Checks every element with the `callback` function of the type
		% `(obj, id, array) => logical` and returns a new instance of
		% `lib.ecma.array` containing all elements of the original array
		% except those which passes the `callback` check.
		%
		% INPUT
		%	callback		<function_handle>		callback function
		%
		% RETURN
		%	<lib.ecma.array>
		%
		function arr=exclude(obj,callback)
			ch = str2func(class(obj));
			arr = ch();
			fWrap = obj.getFunctionWrapper(callback);
			
			for ii=1:numel(obj.data)
				if ~fWrap(obj.data{ii})
					arr.push(obj.data{ii});
				end
			end
		end
		
		% DESCRIPTION
		% Converts every element with the `callback` function of the type
		% `(obj, id, array) => {...}` and returns a new instance of
		% `lib.ecma.array` with the same amount and order of elements
		% containing the mapped elements.
		%
		% INPUT
		%	callback		<function_handle>		callback function
		%
		% RETURN
		%	<lib.ecma.array>
		%
		function arr=map(obj,callback)
			ch = str2func(class(obj));
			fWrap = obj.getFunctionWrapper(callback);

			arr = ch(...
				cellfun(fWrap, obj.data, 'UniformOutput', false)...
			);
		end
		
		% --- loops ---
		
		% DESCRIPTION
		% Loops over the `ids`-array and calls for each element the
		% `callback` function of the type `(obj, id, array) => logical`.
		%
		% INPUT
		%	ids				<double>				ids to loop over
		%	callback		<function_handle>		callback function
		%
		% RETURN
		%	<lib.ecma.array>
		%
		function obj=forIds(obj,ids,callback)
			fWrap = obj.getFunctionWrapperForIds(callback,ids);
			
			for ii=ids
				fWrap(obj.data{ii});
			end
		end
		
		% DESCRIPTION
		% Loops over the whole array and calls for each element the
		% `callback` function of the type `(obj, id, array) => logical`.
		%
		% INPUT
		%	callback		<function_handle>		callback function
		%
		% RETURN
		%	<lib.ecma.array>
		%
		function obj=forEach(obj,callback)
			fWrap = obj.getFunctionWrapperForEach(callback);
			
			for ii=1:obj.length
				fWrap(obj.data{ii});
			end
		end
		
		% --- contraction ---
		
		% DESCRIPTION
		% Converts all elements to a string if possible and joins them
		% with a `delimiter`.
		%
		% INPUT
		%	delimiter		<char>
		%
		% RETURN
		%	<char>
		%
		function s=join(obj,delimiter)
			s = strjoin(obj.data,delimiter);
		end
		
		% DESCRIPTION
		% The `reduce()` method executes a `reducer` function (that you
		% provide) on each member of the array resulting in a single
		% output value.
		%
		% The `reducer` function takes two arguments:
		% 
		% - Accumulator
		% - Current Value
		% 
		% `initialValue` is optional and is the value to use as the first
		% argument to the first call of the callback. If no initial value
		% is supplied, the first element in the array will be used.
		% 
		% Calling reduce() on an empty array without an initial value is
		% an error.
		% 
		% The `reducer` function's returned value is assigned to the
		% accumulator, whose value is remembered across each iteration
		% throughout the array and ultimately becomes the final, single
		% resulting value.
		%
		% INPUT
		%	callback		<function_handle>		callback function
		%	initialValue	*any-type*				first value to be used (optional)
		%
		% RETURN
		%	*any-type*
		%
		function s=reduce(obj,callback,varargin)
			if (obj.length == 0 && nargin == 2)
				error('reduction of an empty array without an initial value')
			end
			
			% set inital values
			if(nargin == 3 && ~lib.bool.isfunc(varargin{1}))
				s = varargin{1};
				i0 = 1;
			else
				s = obj.data{1};
				i0 = 2;
			end
			
			% reduce array
			for ii=i0:numel(obj.data)
				s = callback(s,obj.data{ii});
			end
			
			% furnish
			if(nargin == 3 && lib.bool.isfunc(varargin{1}))
				s = varargin{1}(s);
			end
		end
		
		% DESCRIPTION
		% Like `map` but returns a `native array`. It is supposed to be
		% used in cases where the values are needed directly in stead of
		% an array wrapping them. Hence, `accumulate` is a shorthand for
		% 
		%	mappedArray = Array.map(...);
		%	values = [mappedArray.data{:}];
		% 
		% With `accumulate` it is simply
		% 
		%	values = Array.accumulate(...);
		%
		% INPUT
		%	callback		<function_handle>		callback function
		%
		% RETURN
		%	*any-type*
		%
		function acc = accumulate(obj,varargin)
			if nargin == 2
				Q.callback = varargin{1};
				Q.reshape = 'original';
			else
				Q = lib.ecma.struct(...
					'callback',	@(elm) elm,...
					'reshape',	'original',...
					varargin{:} ...
				);
			end
			
			fWrap = obj.getFunctionWrapper(Q.callback);
			
			acc = obj.reduce(@(acc,elm) [acc;fWrap(elm)],[]);
			
			switch (Q.reshape)
				case 'original'
					acc = reshape(acc,size(obj.data));
					
				case 'column'
					acc = acc(:);
					
				case 'row'
					acc = acc(:)';
			end
		end
		
		function arr = pipe(obj,func)
			arr = func(obj.data);
		end
	end
	
	
	% --- helper ---
	methods (Access = protected)
		function fWrap=getFunctionWrapper(obj,f)
			ii = 1;
			
			function varargout=fWrap2(elm)
				varargout{:} = f(elm,ii);
				ii = ii + 1;
			end
			
			function varargout=fWrap3(elm)
				varargout{:} = f(elm,ii,obj);
				ii = ii + 1;
			end
			
			switch(abs(nargin(f)))
				case 0
					fWrap = @(elm) f();
				case 1
					fWrap = f;
				case 2
					fWrap = @fWrap2;
				case 3
					fWrap = @fWrap3;
			end
		end
		
		% without any output
		function fWrap=getFunctionWrapperForEach(obj,f)
			ii = 1;
			
			function fWrap2(elm)
				f(elm,ii);
				ii = ii + 1;
			end
			
			function fWrap3(elm)
				f(elm,ii,obj);
				ii = ii + 1;
			end
			
			switch(abs(nargin(f)))
				case 0
					fWrap = @(elm) f();
				case 1
					fWrap = f;
				case 2
					fWrap = @fWrap2;
				case 3
					fWrap = @fWrap3;
			end
		end
		
		function fWrap=getFunctionWrapperForIds(obj,f,id)
			ii = 1;
			
			function fWrap2(elm)
				f(elm,id(ii));
				ii = ii + 1;
			end
			
			function fWrap3(elm)
				f(elm,id(ii),obj);
				ii = ii + 1;
			end
			
			switch(abs(nargin(f)))
				case 0
					fWrap = @(elm) f();
				case 1
					fWrap = f;
				case 2
					fWrap = @fWrap2;
				case 3
					fWrap = @fWrap3;
			end
		end
	end
end