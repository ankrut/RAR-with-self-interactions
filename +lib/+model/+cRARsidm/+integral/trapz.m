function f=trapz(EPSILON, func, NN)
% preallocate (speed performance)
f = zeros(size(EPSILON));

% calculate fermi integral for each (beta,alpha,epsilon) set
for ii = 1:length(EPSILON)
	E = linspace(1,EPSILON(ii),NN);
	f(ii) = trapz(E,func(E));
end