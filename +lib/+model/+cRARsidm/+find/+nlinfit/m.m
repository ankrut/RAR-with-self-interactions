function varargout = m(varargin)
% load packages
CONST = lib.ecma.require(@lib.physics.constants);

% define parameter options
parameter = lib.ecma.array();
parameter.push(struct(...
	'path',		'm',...
	'fVector',	@(vm)  log(vm.m),...
	'fUpdate',	@(b)   exp(b),...
	'fModel',	@(SOL) SOL.data.m,...
	'fLog',		@(SOL) SOL.data.m/CONST.keVcc ...
));

parameter.push(struct(...
	'path',		'beta0',...
	'fModel',	@(SOL) SOL.data.beta0,...
	'fLog',		@(SOL) SOL.data.beta0 ...
));

parameter.push(struct(...
	'path',		'theta0',...
	'fModel',	@(SOL) SOL.data.theta0,...
	'fLog',		@(SOL) SOL.data.theta0 ...
));

parameter.push(struct(...
	'path',		'W0',...
	'fModel',	@(SOL) SOL.data.W0,...
	'fLog',		@(SOL) SOL.data.W0 ...
));

[varargout{1:nargout}] = lib.model.cRAR.find.nlinfit(...
	'parameter',		parameter,...
	varargin{:} ...
);