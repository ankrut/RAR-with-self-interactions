MAP = lib.ecma.require(@lib.model.cRAR.map);

fScale = @(Y) 1/Y(end);

EXPORT.radius = lib.profile.mapping(...
	'map',		@(obj) fScale(MAP.radius.fmap(obj)),...
	'label',	'r_s'...
);

EXPORT.mass = lib.profile.mapping(...
	'map',		@(obj) fScale(MAP.mass.fmap(obj)),...
	'label',	'M_s'...
);

EXPORT.velocity = lib.profile.mapping(...
	'map',		@(obj) fScale(MAP.velocity.fmap(obj)),...
	'label',	'v_s'...
);