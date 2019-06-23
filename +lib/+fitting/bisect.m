function [SOL,vm] = bisect(varargin)
% contract arguments
S = lib.ecma.struct(varargin{:});

% destructure
Xint		= S.Xint;
imax		= S.options.MaxIter;
tau			= S.options.tau;
XTOL		= eps;
RTAU		= 1E-4;

% left bound
vm			= S.fUpdate(Xint(1),S.model);
SOL			= S.fSolution(vm);
dY(1)		= S.fResponse(SOL);

if isfield(S,'fLog')
	S.fLog(SOL);
end

% right bound
vm			= S.fUpdate(Xint(2),S.model);
SOL			= S.fSolution(vm);
dY(3)		= S.fResponse(SOL);

if isfield(S,'fLog')
	S.fLog(SOL);
end

% init
Y = [];

for ii=1:imax
	% break criteria
	if diff(Xint) < XTOL ...
		|| (numel(Y) > 1 && abs(1 - Y(end-1)/Y(end)) < RTAU)
		break
	end
	
	% next bisection point
	X = mean(Xint);
		
	% update model struct with given new X
	vm = S.fUpdate(X,vm);

	% calculate new solution
	SOL = S.fSolution(vm);
	
	% set model struct for next iteration
	vm = S.fModel(SOL);
	
	% get relative distance
	dY(2) = S.fResponse(SOL);
	
	% cache response
	Y(end+1) = dY(2);
	
	% iteration print
	if isfield(S,'fLog')
		S.fLog(SOL);
	end

	% get new X (if necessary)
	if sum(isnan(dY)) > 0 % if any is NaN consider specific case
		[Xint,dY] = S.onNaN(Xint,dY);
	elseif abs(dY(2)) > tau % when below accuracy
		if sign(dY(1)) == sign(dY(2)) % if same sign as left bound
			% shift left bound
			Xint(1) = X;
			dY(1)	= dY(2);
		else
			% else shift right bound
			Xint(2) = X;
			dY(3)	= dY(2);
		end
	else % when above accuracy exit iteration
		break
	end
end