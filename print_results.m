function print_results(expPath, obj, N, algorithm_name, sufix, types, prop, times, acc)
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

	fid = fopen([expPath, 'results_', sufix, ...
			algorithm_name, '_', prop{1}, '.txt'], 'a');

	header = repmat('%s;', [1, 5+length(types)]);
	header = sprintf(header, prop{1}, 'iter', 'descr_time', 'kern_time', 'acc', types{:});
	fprintf(fid, '%s\n', header);

	template_line = ['%s;%d;%f;%f;%f', repmat(';%f',[1,length(types)])];
	for i = 1:N
		% type;repetition;time1;time2;accuracy;preciseAccuracy
		basicLine = sprintf(template_line, ...
			prop{1}, i, times(i,1),times(i,2), acc(i,:));
		
		switch prop{1}
			case {'pw', 'pk1'}
			  % basicLine
			  fprintf(fid, '%s\n', basicLine);
			case {'pk2e', 'pk2a'}
			  % basicLine;exact;n
			  fprintf(fid, '%s;%d;%d\n', basicLine, obj.exact, obj.n);
			case 'pl'
			  % basicLine
			  fprintf(fid, '%s\n', basicLine);
			case 'pi'
			  % basicLine;resolution;sigma;weightingFunction
			  f = functions(obj.weightingFunction);
			  fprintf(fid, '%s;%d;%f;%s\n', basicLine, obj.resolution, obj.sigma, ...
			    f.function);
			case {'pbow', 'pvlad', 'pfv'}
				f = functions(obj.weightingFunction);
				if isempty(obj.weightingFunctionPredict)
					% basicLine;numWords;weightingFunction
					fprintf(fid, '%s;%d;%s\n', basicLine, obj.numWords, ...
						f.function);
				else
					fp = functions(obj.weightingFunctionPredict);
					% basicLine;numWords;weightingFunction
					fprintf(fid, '%s;%d;%s;%s\n', basicLine, obj.numWords, ...
						f.function, fp.function);
				end
			case 'pds'
			  % basicLine;resolution;sigma;dim
			  fprintf(fid, '%s;%d;%f;%d\n', basicLine, obj.resolution, obj.sigma, ...
			    obj.dim);
			otherwise
			  throw(MException('Error', 'Representation is not saved'));
		end
	end
	basicLine = sprintf(['%s;%f;%f;%f;%f', repmat(';%f', [1, length(types)])], ...
	    prop{1}, std(acc(:,1)), mean(times(:,1)), mean(times(:,2)), mean(acc));
	fprintf(fid, '%s\n', basicLine);
	
	fclose(fid);
end
