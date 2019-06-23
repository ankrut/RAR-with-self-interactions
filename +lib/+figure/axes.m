function ax = axes(varargin)
Q = lib.ecma.struct(...
	'axes', {},...
	varargin{:}...
);

ax = axes(...
	'Parent',			[],...
	'NextPlot',			'add',...
	'box',				'on',...
	'Layer',			'top',...
	Q.axes{:}...
);

ax.XLabel.Interpreter = 'latex';
ax.YLabel.Interpreter = 'latex';

if isfield(Q,'x')
	setLabel(ax.XLabel,Q.x);
end

if isfield(Q,'y')
	setLabel(ax.YLabel,Q.y);
end

function setLabel(label,obj)
switch class(obj)
	case 'char'
	label.String = obj;

	case {'lib.profile.mapping', 'lib.profile.axis'}
	label.String = obj.label;
end
