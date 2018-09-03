import scipy.io as sio
from pd_wasserstein import wasserstein_dist_mat 

data = sio.loadmat('/home/cybjaz/workspace/pcodebooks/pcodebooks/exp01/pd.mat');

pds = data['pds'];

K = wasserstein_dist_mat(pds.transpose().flatten())

