function [integral_image]=grid_gaussian_bump(Hk, grid_values1_Hk, grid_values2_Hk, sigma,weights)
%grid_gaussian_bump takes in birth-persistence data for a single point cloud, 
%pixel boundary values,the gaussian variance, and values of the bump
%function to linearly interpolate between to get the weighting values for
%each gaussian.
%Inputs:        -BPPairs is the matrix containing the (birth, persistence)
%               pairs for each interval. This comes from calling the
%               birth_persistence_coordinate funtion.
%               -grid_values1_Hk: is a vector containing the boundaries for
%               each pixel: grid_values1 is increasing and grid_values2 is
%               decreasing
%               -sigma is a 1x2 vector with the x and y standard
%               deviations.
%               -weights: vector containing the weighting value for each
%               interval as determined by the user specified weighting
%               function and parameters.
%Outputs:       -Integral image: is the image computed by discreting based
%               on the values contained in grid_values and summing over all
%               thedifferent gaussians centered at each point in the
%               birth-persistence interval data.
	max_bar_length=grid_values2_Hk(1);
	%keyboard
	[X,Y]=meshgrid(grid_values1_Hk,grid_values2_Hk);
	XX=reshape(X,[],1);
	YY=reshape(Y,[],1);
	for l=1:size(Hk,1)
		M=weights(l);
		AA=(M)*mvncdf([XX YY], Hk(l,:), sigma);
		AA=reshape(AA,[],length(grid_values1_Hk));
		ZZ(:,:,l)=(-AA(2:end,2:end)-AA(1:end-1,1:end-1)+AA(2:end, 1:end-1)+AA(1:end-1,2:end));
		% The above line is implementing the procedure explained in https://en.wikipedia.org/wiki/Summed_area_table
	end
	integral_image=sum(ZZ,3);
end
