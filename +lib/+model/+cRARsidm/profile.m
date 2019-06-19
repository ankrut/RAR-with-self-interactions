% REQUIERMENTS
%	lib.ecma.array
%	lib.ecma.struct
%	lib.struct
classdef profile < lib.profile.container
	methods
		function obj=profile(varargin)
			obj = obj@lib.profile.container();

			% get arguments
			Q = lib.ecma.struct(varargin{:});

			% process cases
			if isfield(Q,'model')
				obj.calc(Q.model);
			end
		end

		function obj = calc(obj,model)
			Q = lib.struct.merge(struct(...
				'm',				[],...
				'couplingConstant', 'eV',...				
				'odeSolver',		'logarithmic',...
				'ics',				'auto',...
				'xmin',				'auto',...
				'xmax',				1E20,...	% sufficient for astrophysical cases
				'AbsTol',			1E-16,...	% absolute error for ode solver
				'RelTol',			1E-8,...	% relative error for ode solver
				'numPoints',		500,...		% for trapz integration
				'tol',				1E-15,...	% for ics = auto or xmin = auto
				'odeEventOffset',	1E-12 ...	% for odeSolver = log-alpha2
			), model);

			% destructor
			C			= Q.C;			% coupling parameter
			BETA0		= Q.beta0;		% temperature parameter
			THETA0		= Q.theta0;		% degeneracy parameter
			W0			= Q.W0;			% cutoff parameter
			XMIN		= Q.xmin;		% start of integration
			XMAX		= Q.xmax;		% end of integration
			TOL			= Q.tol;		% how close to singularity (TOL > 0)
			NN			= Q.numPoints;	% number of points for integration
			
			% helper variables
			c			= 299792458;			% m/s
			ALPHA0		= 1 + BETA0*THETA0;
			EPSILON0	= 1 + BETA0*W0;

			% define function handles for temperature, particle density,
			% mass density and pressure
		
			fbeta		= @(nu) BETA0*exp(-nu);
			
			% NOTE: the trapz integration may return imaginary values. We
			% ingore them for performance and stability reason.
			fc			= @(beta,alpha,epsilon) C*4/sqrt(pi)*real(lib.model.cRARsidm.integral.trapz(...
				epsilon,...
				@(E) (1 - exp((E - epsilon)./beta))./(exp((E - alpha)./beta) + 1).*sqrt(E.^2 - 1).*E,...
				NN ...
			));
		
			fdcdbeta	= @(beta,alpha,epsilon) C*4/sqrt(pi)*real(lib.model.cRARsidm.integral.trapz(...
				epsilon,...
				@(E) ((alpha-epsilon).*exp((2*E - alpha - epsilon)./beta) + (E - alpha).*exp((E - alpha)./beta) + (E - epsilon).*exp((E - epsilon)./beta))./(exp((E - alpha)./beta) + 1).^2./beta.^2.*sqrt(E.^2 - 1).*E,...
				NN ...
			));
		
			fdcdalpha	= @(beta,alpha,epsilon) C*4/sqrt(pi)*real(lib.model.cRARsidm.integral.trapz(...
				epsilon,...
				@(E) (1 - exp((E - epsilon)./beta)).*exp((E - alpha)./beta)./(exp((E - alpha)./beta) + 1).^2./beta.*sqrt(E.^2 - 1).*E,...
				NN ...
			));
		
			fdcdepsilon	= @(beta,alpha,epsilon) C*4/sqrt(pi)*real(lib.model.cRARsidm.integral.trapz(...
				epsilon,...
				@(E) exp((E - epsilon)./beta)./(exp((E - alpha)./beta) + 1)./beta.*sqrt(E.^2 - 1).*E,...
				NN ...
			));
			
			frho		= @(beta,alpha,epsilon) 4/sqrt(pi)*real(lib.model.cRARsidm.integral.trapz(...
				epsilon,...
				@(E) (1 - exp((E - epsilon)./beta))./(exp((E - alpha)./beta) + 1).*sqrt(E.^2 - 1).*E.^2,...
				NN ...
			)) + lib.bool.iff(C==0, 0, @() 1/2*fc(beta,alpha,epsilon).^2./C);

			fp			= @(beta,alpha,epsilon) 4/3/sqrt(pi)*real(lib.model.cRARsidm.integral.trapz(...
				epsilon,...
				@(E) (1 - exp((E - epsilon)./beta))./(exp((E - alpha)./beta) + 1).*(E.^2 - 1).^(3/2),...
				NN ...
			)) + lib.bool.iff(C==0, 0, @() 1/2*fc(beta,alpha,epsilon).^2./C);

			% set options for ODE solver
			function [value,isterminal,direction] = fEventNegative(x)
				value      = x;
				isterminal = 1;    % stop the integration
				direction  = -1;   % positive direction only
			end

			options	= odeset(...
				'RelTol',	Q.RelTol,...
				'AbsTol',	Q.AbsTol*ones(1,4),...
				'Events',	@(r,y) fEventNegative((y(4) - 1)) ...
			);

			% set initial conditions
			switch class(Q.ics)
				case 'double'
				ICS = Q.ics;

				case 'char'
				switch Q.ics
					case 'auto'
					XMIN	= sqrt(6*TOL/frho(BETA0,ALPHA0,EPSILON0));
					ICS		= [TOL, 2*TOL, ALPHA0, EPSILON0]; % [nu-nu0, M/R, alpha0, epsilon0]

					otherwise
					error('undefined initial condition')
				end

				otherwise
				error('undefined initial condition')
			end

			% call ode solver
			switch Q.odeSolver
				case 'logarithmic'
				
				% format initial conditions
				ICS(2)		= log(ICS(2));
				
				% solve ode (good luck! I am crossing fingers!!)
				fode		= @(r,y) lib.model.cRARsidm.ode.logarithmic(r,y,fbeta,fc,fdcdbeta,fdcdalpha,fdcdepsilon,frho,fp);
				[X,Y]		= ode45(fode,log([XMIN,XMAX]),ICS,options);

				% increase accuracy only for the tail
				options.RelTol = 1E-15;
				[X2,Y2]		= ode45(fode,[X(end-1),log(XMAX)],Y(end-1,:),options);

				X = [X(1:end-1);X2(2:end)];
				Y = [Y(1:end-1,:);Y2(2:end,:)];

				% format results
				R			= exp(X);
				NU			= Y(:,1);
				M			= exp(Y(:,2)).*R;
				ALPHA		= Y(:,3);
				EPSILON		= Y(:,4);

				otherwise
				error('unknown odeSolver method');
			end
			
			% assign RAR paramaters
			obj.data.m				= Q.m;
			obj.data.beta0			= Q.beta0;
			obj.data.theta0			= Q.theta0;
			obj.data.W0				= Q.W0;
			obj.data.C				= Q.C;

			% cache results
			obj.data.radius			= R;
			obj.data.potential		= NU;
			obj.data.mass			= M;
			obj.data.alpha			= ALPHA;
			obj.data.epsilon		= EPSILON;

			% cache time consuming variables (often needed)
			BETA = fbeta(NU);
			obj.data.coupling		= lib.ecma.array(1:numel(R)).accumulate(@(ii) fc(BETA(ii),ALPHA(ii),EPSILON(ii)))';
			obj.data.density		= lib.ecma.array(1:numel(R)).accumulate(@(ii) frho(BETA(ii),ALPHA(ii),EPSILON(ii)))';
			obj.data.pressure		= lib.ecma.array(1:numel(R)).accumulate(@(ii) fp(BETA(ii),ALPHA(ii),EPSILON(ii)))';
			
			% set coupling constant C0
			switch class(Q.couplingConstant)
				case 'char'
				switch Q.couplingConstant
					case 'eV'
					% constants
					g = 2;					% for fermions;
					obj.data.C0 = C*8*pi^(3/2)/g; % GF^(-1)*[mc²]^(-2)

					otherwise
					error('undefined couplingConstant value')
				end
				
				otherwise
				error('undefined couplingConstant value')
			end
		end
	end
end
