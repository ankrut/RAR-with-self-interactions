function varargout = Wp(varargin)
% load packages
CONST = lib.ecma.require(@lib.physics.constants);

% define parameter options
parameter = lib.ecma.array();
parameter.push(struct(...
	'path',		'm',...
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

parameter.push(struct(...
	'path',		'Wp',...
	'fVector',	@(vm)  log(vm.Wp),...
	'fUpdate',	@(b)   exp(b),...
	'fModel',	@(SOL) SOL.data.Wp,...
	'fLog',		@(SOL) SOL.data.Wp ...
));

[varargout{1:nargout}] = lib.model.cRAR.find.nlinfit(...
	'parameter',		parameter,...
	'fSolution',		@(vm) lib.model.cRAR.transform.Wp('model', vm, 'Wp', vm.Wp),...
	varargin{:} ...
);