function rpd = rotatePD(pd)
% 	rpd = [pd(:,1) + pd(:,2), pd(:,2) - pd(:,1)];
	rpd = [pd(:,1), pd(:,2) - pd(:,1)];
end