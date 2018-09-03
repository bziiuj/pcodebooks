function [ PIs ] = new_make_PIs(interval_data, res, sig, weight_func, params, type, type_params, parallel)
%make_PIs generates the set of persistence images for the PH interval data
%stored in the cell array titled interval_data.
% INPUTS:	-interval_data: is a cell array containing the interval data
%			for all of the point clouds in consideration. Each sheet in
%			the cell array corresponds to a different Betti dimension.
%			Each interval set is assumed to be an nX2 matrix with the
%			first column corresponding to the birth times of features and
%			the second column is the death time of each feature. All death
%			times must be greater than the birth time and there must be a
%			finite death time for each feature. 
%					-COMMENT - I assume, that the third coordinate denotes
% 					dimension, second - the class of items, first - pds of 
%					particular point clouds 
%			-res: the desired resolution of the image
%			-sig: is the desired variance of the Gaussians used to compute
%			the images (set -1 for default sigma)
%			-weight_function: the name of the weighting function to be
%			called to generate the weightings for the bars. ex
%			@linear_ramp. The weight function needs to be a function only
%			of persistence. Needs to be able to accept the
%			birth_persistence coordinates as an input.
%			-params: the set of parameter values needing to be defined fpr
%			the weighting function. 
%			-type: refers to the declaration of a 'soft', 'hard' or 'perc' 
%			with respect to the boundaries. type=1 produces hard bounds, type=2
%			produces soft boundaries on the images, type=3 produces boundaries
%			based on percentiles.
%			-type_params: the set of values that specifies 'type' execution:
%				~ 'hard' - matrix dX2, where d is a number of sheets in
%					interval_data cell array (for each Betti number dimension), 
%					i-th vector iX2 determines the boundaries of PIs for 
%					i-th dimension [min_birth, max_persistence],
%					if not specified (or empty matrix), values are taken
%					from a data
%				~ 'soft' - not applicable
%			-parallel: boolean value, PIs are computed in parallel, parpool has
%				to be set up before starting the function
%OUTPUTS:   -PIs: The set of persistence images generated based on the
%            options specified for the provided interval data.

[ b_p_data, max_b_p_Hk, problems ] = birth_persistence_coordinates(interval_data);

[n_items, n_classes, n_dims]=size(interval_data);
% set default type (hard vs. soft)
if nargin<6
	type=1;
end
% set default params for a type
if nargin<7
	%TODO
	type_params = [];
end

% remove b_p points exceeding new limits
if length(type_params)~=0
	for d=1:n_dims
		for i=1:n_classes
			for j=1:n_items
				points = b_p_data{j,i,d};
				points = points(find(points(:,1) >= type_params(d, 1)),:);
				points = points(find(points(:,2) <= type_params(d, 2)),:);
                points(:,1) = points(:,1) - type_params(d,1);
				b_p_data{j,i,d} = points;
			end
		end
	end
end

% set new limits for PI
disp('Old max birth and persistence values:');
disp(max_b_p_Hk);
if type==1       
	if size(type_params) == [n_dims 2]
		% max_b_p_Hk = type_params;
		% max_b_p_Hk = [max_b_p_Hk(:,1) type_params(:,2)];
		max_b_p_Hk = [max_b_p_Hk(:,1)-type_params(:,1) type_params(:,2)];
% 		max_b_p_Hk = [min([max_b_p_Hk(:,1) type_params(:,2)]) type_params(:,2)];
	elseif length(type_params) ~= 0
		error('type_params argument is of wrong dimension');
	end
end
disp('Updated max birth and persistence values:');
disp(max_b_p_Hk);
disp('Persistence limits');
disp(type_params);
disp('Pixel resolution:')
disp(max_b_p_Hk/res);


%first do a check to make sure all the points (birth,persistence) points
%are viable.
if size(problems,1)>0
    error('Error: Negative Persistences Present')
  
elseif size(problems,1)==0;
    disp('All positive Persistence, continuing');
end

if nargin>9
    error('Error: too many input arguments')
end
% set default resolution
if nargin<2
	res = 25;
	disp(strcat('Default resolution: ', num2str(res)));
end
% set default sigma
if nargin<3 || sig == -1
	sig = default_sigma(res, max_b_p_Hk);
	disp(strcat('Default sigma: ', num2str(sig)));
end
% set default weighten function
if nargin<4
    weight_func=@linear_ramp; %default setting is a linear weighting function
    params=[0, max(max(max_b_p_Hk(:,2)))]; %default setting 0 at 0 and 1 at 
elseif nargin == 4
    error('Error: Incomplete weight function and parameter pair');
end
if nargin<8
	parallel = false;
end

if type==1       
    [ data_images ] = hard_bound_PIs( b_p_data, max_b_p_Hk, weight_func, params, res, sig);
elseif type==2
    [ data_images ] = soft_bound_PIs( b_p_data, max_b_p_Hk, weight_func, params, res, sig);
else
	error('wrong argument');
end
    PIs=data_images;
    
function sigma = default_sigma(res, max_b_p_Hk)
	% the default setting for the variance of the gaussians is equal to one half 
	% the height of a pixel.
	sigma = .5*(max(max(max_b_p_Hk(:,2)))/res);
end

function [ b_p_data, max_b_p_Hk, problems] = birth_persistence_coordinates(interval_data)
%birth_persitence_coordinates takes in the interval data as output by the
%duke TDA code (birth-death coordinates) and changes them into
%birth-persistence coordinates.
%INPUTS:     -interval_data: is a cell array containing the interval data
%            for all of the point clouds in consideration. Each sheet in
%            the cell array corresponds to a different Betti dimension.
%            Each interval set is assumed to be an nX2 matrix with the
%            first column corresponding to the birth times of features and
%            the second column is the death time of each feature. All death
%            times must be greater than the birth time and there must be a
%            finite death time for each feature. 
%OUTPUT:     -b_p_interval_data: This is the modified coordinate data
%            in a cell array. The sheets contain the modified Hk data.
%            -max_b_p_Hk: gives the maximal persistence and maximal
%            birth time across all point clouds for each Hk. 
%            This information is used to create the boundaries for the
%            persistence images.
%         
	[m,n,o]=size(interval_data);
	%allocate space
	max_persistences=zeros(m,n,o);
	max_birth_times=zeros(m,n,o);
	birth_persistence=cell(m,n,o);
	problems=[];
	for k=1:o
		for i=1:n
			for j=1:m
				B=interval_data{j,i,k};
				if isempty(B)
					B = [0, 0];
				end
				%pulls the Hk interval data for the (j,i)th point cloud.
				max_persistences(j,i,k)=max(B(:,2)-B(:,1));
				%computes the Hk persistence(death-birth) for the (j,i)th point cloud
				max_birth_times(j,i,k)=max(B(:,1));
				%determines that maximal birth time for an Hk feature for the
				%(j,i)th point cloud. We will take the maximum over all of point
				%clouds to generate non-normalized Hk PIs. 
				C=B(:,2)-B(:,1);
				birth_persistence{j,i,k}=[B(:,1) C];
				%birth-persistence coordinates for Hk
		%        end
				D=find(C<0);
				if length(D)>0
					problems=[problems; j,i,k];
				elseif length(D)==0
					problems=problems;
				end
			end
		end
		Hk_max_birth(k,1)=max(max(max_birth_times(:,:,k)));
		%determine the maximum birth time of all Hk features across the point
		%clouds
		Hk_max_persistence(k,1)=max(max(max_persistences(:,:,k)));
		%determine the maximum persistence of all Hk features across the point
		%clouds
	end
	max_b_p_Hk=[Hk_max_birth, Hk_max_persistence];
	b_p_data=birth_persistence;
end

function [ data_images ] = hard_bound_PIs( b_p_data, max_b_p_Hk, weight_func, params, res,sig)
%hard_bound_PIs generates the PIs for a set of point clouds with the
%b_p_data. Hard refers to the fact that we cut the boundaries off hard at
%the maximum values. 
%   INPUTS:        -b_p_data: birth-persistence points for each of the
%                  point clouds. Each sheet corresponds to a different
%                  Betti dimension.
%                  -max_b_p_Hk: gives the maximal persistence and maximal
%                  birth time across all point clouds for each Hk. 
%                  This information is used to create the boundaries for 
%                  the persistence images.
%                  -weight_func: the weighting function the user specified
%                  -params: the needed paramteres for the user specified
%                  weight function
%                  -res: the resolution (number of pixels). we create
%                  square images with rectangular pixels.
%                  -sig: the variance of the gaussians. 
%   OUTPUT:        -data_images: the set of persistence images generated
%                  using the selected parameter values. Each sheet
%                  corresponds to the PIs generated for different Hk
%                  interval data.
	[m,n,o]=size(b_p_data);
	%allocate space
	data_images=cell(m,n,o);

	for k=1:o  
		Hk_max_b=max_b_p_Hk(k,1);
		Hk_max_p=max_b_p_Hk(k,2);    
		sigma=[sig,sig]; %duplicate the variance for the PIs      
		%set up gridding for Hk
		birth_stepsize_Hk=Hk_max_b/res; %the x-width of a pixel
		persistence_stepsize_Hk=Hk_max_p/res; %the y-height of a pixel
		grid_values1_Hk=0:birth_stepsize_Hk:Hk_max_b; %must be increasing from zero to max_dist
		grid_values2_Hk=Hk_max_p:-persistence_stepsize_Hk:0; %must be decreasing from max_dist to zero

		if parallel
			parfor p=1:m
				for t=1:n
					Hk=b_p_data{p,t,k}; %Hk birth persistence data
					%CHANGES TO THE WIEGHT FUNCTION INPUTS HAPPEN IN THE ROW
					%BELOW
					[weights]=arrayfun(@(row) weight_func(Hk(row,:), params), 1:size(Hk,1))';
					%call the function that makes the image
					[I_Hk] = grid_gaussian_bump(Hk, grid_values1_Hk, grid_values2_Hk, sigma,weights);  
					data_images{p,t,k}=I_Hk;
				end
			end   
		else
			for p=1:m
				for t=1:n
					Hk=b_p_data{p,t,k}; %Hk birth persistence data
					%CHANGES TO THE WIEGHT FUNCTION INPUTS HAPPEN IN THE ROW
					%BELOW
					[weights]=arrayfun(@(row) weight_func(Hk(row,:), params), 1:size(Hk,1))';
					%call the function that makes the image
					[I_Hk] = grid_gaussian_bump(Hk, grid_values1_Hk, grid_values2_Hk, sigma,weights);  
					data_images{p,t,k}=I_Hk;
				end
			end   
		end
	end
end

function [ data_images ] = soft_bound_PIs( b_p_data, max_b_p_Hk, weight_func, params, res,sig)
%soft_bound_PIs generates the PIs for a set of point clouds with the
%b_p_data. Soft refers to the fact that we add three times the variance
% to the maximal values to determine our boundaries.
%   INPUTS:        -b_p_data: birth-persistence points for each of the
%                  point clouds. Each sheet corresponds to a different
%                  Betti dimension.
%                  -max_b_p_Hk: gives the maximal persistence and maximal
%                  birth time across all point clouds for each Hk. 
%                  This information is used to create the boundaries for 
%                  the persistence images.
%                  -weight_func: the weighting function the user specified
%                  -params: the needed paramteres for the user specified
%                  weight function
%                  -res: the resolution (number of pixels). we create
%                  square images with rectangular pixels.
%                  -sig: the variance of the gaussians. 
%   OUTPUT:        -data_images: the set of persistence images generated
%                  using the selected parameter values. Each sheet
%                  corresponds to the PIs generated for different Hk
%                  interval data.

	[m,n,o]=size(b_p_data);
	%allocate space
	data_images=cell(m,n,o);

	for k=1:o    
		Hk_max_b=max_b_p_Hk(k,1);
		Hk_max_p=max_b_p_Hk(k,2);    
		sigma=[sig,sig]; %duplicate the variance for the PIs      
		%set up gridding for Hk
		birth_stepsize_Hk=(Hk_max_b+3*sig)/res; %the x-width of a pixel
		persistence_stepsize_Hk=(Hk_max_p+3*sig)/res; %the y-height of a pixel
		grid_values1_Hk=0:birth_stepsize_Hk:(Hk_max_b+3*sig); %must be increasing from zero to max_dist
		grid_values2_Hk=(Hk_max_p+3*sig):-persistence_stepsize_Hk:0; %must be decreasing from max_dist to zero

		if parallel
			parfor p=1:m
				for t=1:n
					Hk=b_p_data{p,t,k}; %birth-persistence data
					%CHANGES TO THE WIEGHT FUNCTION INPUTS HAPPEN IN THE ROW
					%BELOW
					[weights]=arrayfun(@(row) weight_func(Hk(row,:), params), 1:size(Hk,1))';
					%call the funciton that makes the image
					[I_Hk] = grid_gaussian_bump(Hk, grid_values1_Hk, grid_values2_Hk, sigma,weights);  
					data_images{p,t,k}=I_Hk;
				end
			end
		else
			for p=1:m
				for t=1:n
					Hk=b_p_data{p,t,k}; %birth-persistence data
					%CHANGES TO THE WIEGHT FUNCTION INPUTS HAPPEN IN THE ROW
					%BELOW
					[weights]=arrayfun(@(row) weight_func(Hk(row,:), params), 1:size(Hk,1))';
					%call the funciton that makes the image
					[I_Hk] = grid_gaussian_bump(Hk, grid_values1_Hk, grid_values2_Hk, sigma,weights);  
					data_images{p,t,k}=I_Hk;
				end
			end
		end
	end
end

end

