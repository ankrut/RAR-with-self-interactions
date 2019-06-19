classdef responseList < lib.ecma.array
	methods
		function obj = responseList(varargin)
			obj = obj@lib.ecma.array(varargin{:});
		end
		
		function value=chi2(obj,profile)
			fCHI2 = @(elm) elm.chi2(profile);
			
			value = sum(obj.accumulate(...
				'callback', fCHI2,...
				'reshape', false ...
			));
		end
	end
end