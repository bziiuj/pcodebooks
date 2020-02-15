function print_results(expPath, obj, N, algorithm_name, sufix, types, ...
	prop, times, accTest, confMatTest, accTrain, confMatTrain, Cs)
%%% ARGS:
%	expPath	- directory where results will be saved
%	algorithm_name
%	N		- number of experiment repetition
%	sufix	- additional specification of experiment
%	types	- classes names
%	prop	- cell array - {description of an object, detailed description}
%	times	- 
%	acc		- accuracy + accuracy for each class

	if ~strcmp(sufix, '')
		sufix = [sufix, '_'];
	end

	fid = fopen([expPath, 'results_allrepts_', sufix, ...
			algorithm_name, '_', prop{1}, '.txt'], 'a');
	fid_train = fopen([expPath, 'results_allrepts_train_', sufix, ...
			algorithm_name, '_', prop{1}, '.txt'], 'a');
	fid_summary = fopen([expPath, 'results_', sufix, ...
			algorithm_name, '_', prop{1}, '.txt'], 'a');
	fid_summary_train = fopen([expPath, 'results_train_', sufix, ...
			algorithm_name, '_', prop{1}, '.txt'], 'a');

	header = repmat('%s;', [1, 5+length(types)]);
	header = sprintf(header, prop{1}, 'iter', 'descr_time', 'feature_time', 'cval_time', 'svm_time', 'acc', types{:});
	fprintf(fid, '%s\n', header);

% 	specs = ''; 
	switch prop{1}
		case {'pw', 'pl'}
			specs = '';
		case {'pk1'}
			specs = num2str(obj.sigma);
		case {'pk2e', 'pk2a'}
			specs = [num2str(obj.exact), ';', num2str(obj.n)];
		case 'pi'
			% resolution;sigma;weightingFunction
% 			f = functions(obj.weightingFunction);
% 			specs = [num2str(obj.resolution), ';', num2str(obj.sigma), ';', f.function];
			specs = [num2str(obj.resolution), ';', num2str(obj.sigma), ';', ...
				obj.options.weightingfunction, ';', num2str(obj.options.norm)];
		case {'pfv', 'pbow_st'}
			f = functions(obj.weightingFunction);
			% numWords;sampleSize;weightingFunctionFit;weightingFunctionPredict
			specs = [num2str(obj.numWords), ';', num2str(obj.sampleSize), ';', f.function, ';',num2str(obj.option)];
		case {'pbow', 'pvlad', 'svlad'}
			f = functions(obj.weightingFunction);
			if isempty(obj.weightingFunctionPredict)
				% numWords;sampleSize;weightingFunctionFit;weightingFunctionPredict
				specs = [num2str(obj.numWords), ';', num2str(obj.sampleSize), ';', f.function];
			else
				fp = functions(obj.weightingFunctionPredict);
				% numWords;sampleSize;weightingFunction
				specs = [num2str(obj.numWords), ';', num2str(obj.sampleSize), ';', f.function, ';', fp.function];
			end
		case {'npbow'}
			specs = [num2str(obj.numWords), ';', num2str(obj.options.samplesize), ';', ...
				obj.options.method, ';', obj.options.samplingweight, ';', ...
				obj.options.predictweight, ';', num2str(obj.options.norm), ';', ...
				iif(obj.options.norm, [num2str(obj.options.scale(1)), 'x', num2str(obj.options.scale(2))], 'NA'), ';', ...
				iif(strcmp(obj.options.method, 'wkmeans'), obj.options.kmeansweight, 'NA'), ';', ...
				num2str(obj.options.gridsize), ';'
				];
		case {'nspbow'}
			specs = [num2str(obj.numWords), ';', num2str(obj.options.samplesize), ';', ...
				obj.options.method, ';', obj.options.samplingweight, ';', ...
				num2str(obj.options.norm), ';', ...
				iif(obj.options.norm, [num2str(obj.options.scale(1)), 'x', num2str(obj.options.scale(2))], 'NA'), ';', ...
				iif(strcmp(obj.options.method, 'wkmeans'), obj.options.kmeansweight, 'NA'), ';', ...
				num2str(obj.options.gridsize)
				];
		case 'pds'
			% resolution;sigma;dim
			specs = [num2str(obj.resolution), ';', num2str(obj.sigma), ';', num2str(obj.dim)];
		otherwise
		  throw(MException('Error', 'Representation is not saved'));
	end

	disp(['specs: ', specs]);
	% type;repetition;time1;time2;time3;time4;accuracy;preciseAccuracy
	template_line_test = ['%s;%d;%f;%f;%f;%f;%f', repmat(';%f',[1,length(types)])];
	% type;repetition;accuracy;preciseAccuracy
	template_line_train = ['%s;%d;%f', repmat(';%f',[1,length(types)])];

	for i = 1:N
		% type;repetition;time1;time2;time3;time4;accuracy;preciseAccuracy
		basicLine = sprintf(template_line_test, ...
			prop{1}, i, times(i,1), times(i,2), times(i,3), times(i,4), accTest(i,:));
		fprintf(fid, '%s;%s;%f\n', basicLine, specs, Cs(i));
		% type;repetition;accuracy;preciseAccuracy
		basicLine = sprintf(template_line_train, prop{1}, i, accTrain(i,:));
		fprintf(fid_train, '%s;%s\n', basicLine, specs);
	end

	% Summary test
	% type;std;time1;time2;time3;time4;accuracy;preciseAccuracy
	basicLine = sprintf(['%s;%f;%f;%f;%f;%f;%f', repmat(';%f', [1, length(types)])], ...
	    prop{1}, std(accTest(:,1)), mean(times(:,1)), mean(times(:,2)), ...
		mean(times(:,3)), mean(times(:,4)), mean(accTest));
	fprintf(fid, '%s\n', basicLine);
	fprintf(fid_summary, '%s;%s\n', basicLine, specs);

	% Summary train
	% type;std;accuracy;preciseAccuracy
	basicLine = sprintf(['%s;%f;%f', repmat(';%f', [1, length(types)])], ...
	    prop{1}, std(accTrain(:,1)), mean(accTrain));
	fprintf(fid_train, '%s\n', basicLine);
	fprintf(fid_summary_train, '%s;%s\n', basicLine, specs);

	fclose(fid);
	fclose(fid_train);
	fclose(fid_summary);
	fclose(fid_summary_train);

	save([expPath, 'conf/confmattest_', sufix, algorithm_name, '_', prop{1}, '_', strrep(specs, ';', '_'), '.mat'], 'confMatTest');
	save([expPath, 'conf/confmattrain_', sufix, algorithm_name, '_', prop{1}, '_', strrep(specs, ';', '_'), '.mat'], 'confMatTrain');
	
end
