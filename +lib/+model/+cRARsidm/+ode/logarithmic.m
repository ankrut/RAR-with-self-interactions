function dy=logarithmic(x, y, fbeta, fc, fdcdbeta, fdcdalpha, fdcdepsilon, frho, fp)
dy = zeros(4,1);

% x			ln(r/R)
% y(1)		nu(r) - nu0
% y(2)		ln(M(r)/M * R/r)
% y(3)		alpha(r) = 1 + beta(r)*theta(r)
% y(4)		epsilon(r) = 1 + beta(r)*W(r)

% frho		density function rho(r)/rho
% fp		pressure function P(r)/(rho c²)

R			= exp(x);
NU			= y(1);
PHI			= exp(y(2));

BETA		= fbeta(NU);
ALPHA		= y(3);
EPSILON		= y(4);

RHO			= frho(BETA, ALPHA, EPSILON);		% density rho(r)/rho
P			= fp(BETA, ALPHA, EPSILON);			% pressure P(r)/(rho c²)

C			= fc(BETA,ALPHA,EPSILON);			% coupling C*m*n(r)/rho
dcdbeta		= fdcdbeta(BETA,ALPHA,EPSILON);
dcdalpha	= fdcdalpha(BETA,ALPHA,EPSILON);
dcdepsilon	= fdcdepsilon(BETA,ALPHA,EPSILON);

% calculate derivatives
dy(1) = 0.5*(PHI + R^2*P)/(1 - PHI);	% metric potential
dy(2) = (R^2*RHO/PHI - 1);				% compactness ln(M(r)/M * R/r)
dy(3) = -(ALPHA + C - BETA*dcdbeta - (EPSILON - ALPHA)*dcdepsilon)/(1 + dcdalpha + dcdepsilon)*dy(1);
dy(4) = -(EPSILON + C - BETA*dcdbeta - (ALPHA - EPSILON)*dcdalpha)/(1 + dcdalpha + dcdepsilon)*dy(1);