function options = named_options(default_options, varargin)
%NAMED_OPTIONS - parse arguments passed as a named options
%%% https://stackoverflow.com/questions/2775263/how-to-deal-with-name-value-pairs-of-function-arguments-in-matlab
% struct containing all parameters (and their default values) that 
% can be entered with named argument

% e.g. default_options = struct('n', 10, 'fun', @linear_ramp)
	%# read the acceptable names
	optionNames = fieldnames(default_options);
	options = default_options;

	%# count arguments
	nArgs = length(varargin);
	disp(varargin)
	disp(nArgs)
	if round(nArgs/2)~=nArgs/2
		error('Required propertyName/propertyValue pairs')
	end

	for pair = reshape(varargin, 2, []) %# pair is {propName; propValue}
		inpName = lower(pair{1}); %# make case insensitive
		if any(strcmp(inpName, optionNames))
			%# overwrite options. If you want you can test for the right class here
			%# Also, if you find out that there is an option you keep getting wrong,
			%# you can use "if strcmp(inpName,'problemOption'),testMore,end"-statements
			options.(inpName) = pair{2};
		else
			error('%s is not a recognized parameter name', inpName)
		end
	end
end

