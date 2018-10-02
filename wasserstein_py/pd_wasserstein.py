import dionysus as d
import numpy as np
import multiprocessing as mp
import time

def wasserstein_dist_mat(pds):
    diag = pds2diagrams(pds);
    n = len(pds);
    K = np.zeros((n, n));
    for i in range(n):
        print(str(i) + '/' + str(n));
        for j in range(i, n):
            # print str(i) + '/' + str(n) + ' (' + str(j) + ')'
            K[i, j] = d.wasserstein_distance(diag[i], diag[j]);
            K[j, i] = K[i, j];
    return K;

def pds2diagrams(pds):
    diagrams = [];
    for i in range(0, len(pds)):
        #diagrams.append(i)
        diagrams.append(d.Diagram([tuple(x) for x in pds[i]]))
    return diagrams

def comp_row(i, p, dic, out):
    n = dic['n'];
    diag = dic['diag'];
    z = int(n/p) + 1;

    I = [x*p+i for x in range(z) if x*p+i < n];
    # print(I);
    start = 0;
    end = 0;
    
    for r in I:
        row = np.zeros(n);
        lb = r*n;
        rb = (r+1)*n;

        print(str(r) + '/' + str(n) + '\t(' + str(end - start) + 's)')
        start = time.time();
        for j in range(r, n):
            # print(str(j) + '\t' + str(r) + '/' + str(n))
            row[j] = d.wasserstein_distance(diag[r], diag[j]);
        out[lb:rb] = row;
        # print(row);
        end = time.time();

def wasserstein_dist_mat_parallel(pds, cores):
    diag = pds2diagrams(pds);
    n = len(pds);
    K = np.zeros((n, n));

    mng = mp.Manager();
    dic = mng.dict();
    dic['diag'] = diag;
    dic['n'] = n;
    out_arr = mp.Array('f', n*n, lock=False);
    
    pool = cores;
    processes = [];
    for i in range(pool):
        p = mp.Process(target=comp_row, args=(i, pool, dic, out_arr));
        processes.append(p);
    [x.start() for x in processes]

    for proc in processes:
        proc.join()
    print('ready');
    K = np.array(out_arr);
    K = K.reshape((n, n));
    for i in range(n):
        for j in range(n):
            K[j, i] = K[i,j];

    return K;
