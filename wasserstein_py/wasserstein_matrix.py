import scipy.io as sio
from pd_wasserstein import wasserstein_dist_mat, wasserstein_dist_mat_parallel
import time

experiments = ['exp01_synthetic', 'exp02_motion', 'exp03_geomat', 'exp04_petroglyphs', 'exp05_reddit5K', 'exp06_reddit12K'];

datapath = '/home/lipinski/public_html/pcodebook_data/';
path = datapath + experiments[0];
cores = 32;

# filenames  = ['pds_1_400', 'pds_1_100', 'pds_0_200', 'pds_0_100']; 
filenames  = ['pds_reddit12K_sub50']; 
# filenames  = ['pd']; 

for filename in filenames:
    fullname = path + '/' + filename + '.mat';

    print('#########################################');
    print(fullname);
    data = sio.loadmat(fullname);

    pds = data['pds'];

#   pds array should be of shape (C, E), where C is number of classes and E number of examples
#   transpose if needed
#    pds = pds.transpose();
    pds = pds.flatten();
    start = time.time();
    K = wasserstein_dist_mat_parallel(pds, cores);
    elapsed_time = time.time() - start;
    print('Wasserstain matrix generation time: ');
    print(elapsed_time);

    sio.savemat(path + '/' + filename + '_pw.mat', {'K': K });
