function print_results(expPath, obj, N, algorithm_name, sufix, types, prop, times, acc, confusion_matrix)
%%% ARGS:
%	expPath	- directory where results will be saved
%	algorithm_name
%	N		- number of experiment repetition
%	sufix	- additional specification of experiment
%	types	- classes names
%	prop	- cell array - {description of an object, detailed description}
%	times	- times of descriptor creating & time of kernel creating
%	acc		- accuracy + accuracy for each class

	if ~strcmp(sufix, '')
		sufix = [sufix, '_'];
	end

	fid = fopen([expPath, 'results_allrepts_', sufix, ...
			algorithm_name, '_', prop{1}, '.txt'], 'a');
	fid_summary = fopen([expPath, 'results_', sufix, ...
			algorithm_name, '_', prop{1}, '.txt'], 'a');

	header = repmat('%s;', [1, 5+length(types)]);
	header = sprintf(header, prop{1}, 'iter', 'descr_time', 'kern_time', 'acc', types{:});
	fprintf(fid, '%s\n', header);

	specs = ''; 
	switch prop{1}
		case {'pw', 'pk1', 'pl'}
			specs = '';
		case {'pk2e', 'pk2a'}
			specs = [num2str(obj.exact), ';', num2str(obj.n)];
		case 'pi'
			% resolution;sigma;weightingFunction
			f = functions(obj.weightingFunction);
			specs = [num2str(obj.resolution), ';', num2str(obj.sigma), ';', f.function];
		case {'pbow', 'pvlad', 'pfv', 'pbow_st', 'svlad'}
			f = functions(obj.weightingFunction);
			if isempty(obj.weightingFunctionPredict)
				% numWords;sampleSize;weightingFunctionFit;weightingFunctionPredict
				specs = [num2str(obj.numWords), ';', num2str(obj.sampleSize), ';', f.function];
			else
				fp = functions(obj.weightingFunctionPredict);
				% numWords;sampleSize;weightingFunction
				specs = [num2str(obj.numWords), ';', num2str(obj.sampleSize), ';', f.function, ';', fp.function];
			end
		case 'pds'
			% resolution;sigma;dim
			specs = [num2str(obj.resolution), ';', num2str(obj.sigma), ';', num2str(obj.dim)];
		otherwise
		  throw(MException('Error', 'Representation is not saved'));
	end

	template_line = ['%s;%d;%f;%f;%f', repmat(';%f',[1,length(types)])];
	for i = 1:N
		% type;repetition;time1;time2;accuracy;preciseAccuracy
		basicLine = sprintf(template_line, ...
			prop{1}, i, times(i,1),times(i,2), acc(i,:));
		
		fprintf(fid, '%s;%s\n', basicLine, specs);
	end
	basicLine = sprintf(['%s;%f;%f;%f;%f', repmat(';%f', [1, length(types)])], ...
	    prop{1}, std(acc(:,1)), mean(times(:,1)), mean(times(:,2)), mean(acc));
	fprintf(fid, '%s\n', basicLine);
	
	fprintf(fid_summary, '%s,%s\n', basicLine, specs);

	fclose(fid);
	fclose(fid_summary);
	
	
	save([expPath, 'conf/confmat_', sufix, algorithm_name, '_', prop{1}, '_', strrep(specs, ';', '_'), '.mat'], 'confusion_matrix');
	
end
