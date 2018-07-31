function PD_AGGs = make_pd_agg(pds)
%%% PD_AGG (aggregated descriptor of persistence diagrams) consists of:
%	- number of elements of intervals,
%	- minimum and maximum value,
%	- mean, standard deviation,
%	- 1-quartile, median, 3-quartile,
%	- sqrt sum, sum, 2-power sum
%%% ARGS:	-pds; persistence diagrams - cell array of arrays of size (n,2)

	PD_AGGs = {};
	for i = 1:length(pds)
		pd = pds{i};
		% Persistence - length of intervals
		pers = (pd(:,2)-pd(:,1))';
		nint = length(pers);

		% exclude infinite interval from statistics
		pers = pers(1:nint-1);

		pd_agg = [double(nint) minmax(pers) mean(pers) ...
				std(pers) quantile(pers, [0.25 0.5 0.75]) ...
				sum(sqrt(pers)) sum(pers) sum(pers.^2) ];
		PD_AGGs{end+1} = pd_agg';
	end
end
