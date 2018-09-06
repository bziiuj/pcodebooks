import scipy.io as sio
from pd_wasserstein import wasserstein_dist_mat, wasserstein_dist_mat_parallel

# path = '/home/cybjaz/workspace/pcodebooks/pcodebooks/rawdata/exp03_geomat/';
# filename = 'pds_1_400';
# path = '/home/cybjaz/workspace/pcodebooks/pcodebooks/exp01_svm/';
# filename = 'pd';
path = '/home/lipinski/public_html/pcodebook_data/exp03_geomat/';
cores = 100;

# filename = 'pds_1_400';
filenames  = ['pds_1_400', 'pds_1_100', 'pds_0_200', 'pds_0_100']; 
# filenames  = ['pds_1_200', 'pds_0_400']; 
for filename in filenames:
    fullname = path + filename + '.mat';

    print('#########################################');
    print(fullname);
    data = sio.loadmat(fullname);

    pds = data['pds'];

#    pds = pds.transpose().flatten();
    pds = pds.flatten();
    K = wasserstein_dist_mat_parallel(pds, cores);

    # print(K);

    sio.savemat(path + filename + '_pw.mat', {'K': K });
