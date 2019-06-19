function COLOR = colormap(varargin)
Q = lib.ecma.struct(...
	'n',		7,...
	'func',		@lines,...
	'reverse',	false,...
	'array',	false,...
	varargin{:} ...
);

COLOR = num2cell(Q.func(Q.n),2);

if(Q.reverse)
	COLOR = fliplr(COLOR');
end

if(Q.array)
	COLOR = lib.ecma.array(COLOR{:});
end