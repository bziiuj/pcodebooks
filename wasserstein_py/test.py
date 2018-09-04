import scipy.io as sio
from pd_wasserstein import wasserstein_dist_mat, wasserstein_dist_mat_parallel

# path = '/home/cybjaz/workspace/pcodebooks/pcodebooks/rawdata/exp03_geomat/';
# filename = 'pds_1_400';
path = '/home/cybjaz/workspace/pcodebooks/pcodebooks/exp01_svm/';
filename = 'pd';

# data = sio.loadmat('/home/cybjaz/workspace/pcodebooks/pcodebooks/exp01/pd.mat');
data = sio.loadmat(path + filename + '.mat');

pds = data['pds'];

pds = pds.transpose().flatten();
K = wasserstein_dist_mat_parallel(pds);
# K = wasserstein_dist_mat_parallel(pds[0:20]);

print(K);

sio.savemat(path + filename + '_pw.mat', {'K': K });
