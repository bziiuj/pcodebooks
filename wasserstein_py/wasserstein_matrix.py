import scipy.io as sio
from pd_wasserstein import wasserstein_dist_mat, wasserstein_dist_mat_parallel
import time

# path = '/home/cybjaz/workspace/pcodebooks/pcodebooks/rawdata/exp03_geomat';
# filename = 'pds_1_400';
# path = '/home/cybjaz/workspace/pcodebooks/pcodebooks/exp01_svm';
# filename = 'pd';
# path = '/home/lipinski/public_html/pcodebook_data/exp03_geomat';
path = '/home/lipinski/public_html/pcodebook_data/exp06_reddit12K';
cores = 64;

# filename = 'pds_1_400';
# filenames  = ['pds_1_400', 'pds_1_100', 'pds_0_200', 'pds_0_100']; 
filenames  = ['pds_reddit12K_sub50']; 
for filename in filenames:
    fullname = path + '/' + filename + '.mat';

    print('#########################################');
    print(fullname);
    data = sio.loadmat(fullname);

    pds = data['pds'];

#    pds = pds.transpose().flatten();
    pds = pds.flatten();
    start = time.time();
    K = wasserstein_dist_mat_parallel(pds, cores);
    elapsed_time = time.time() - start;
    print('Wasserstain matrix generation time: ');
    print(elapsed_time);

    sio.savemat(path + '/' + filename + '_pw.mat', {'K': K });
