import dionysus as d
import numpy as np

def wasserstein_dist_mat(pds):
    diag = pds2diagrams(pds);
    n = len(pds);
    K = np.zeros((n, n));
    for i in range(n):
        print str(i) + '/' + str(n)
        for j in range(n):
            K[i, j] = d.wasserstein_distance(diag[i], diag[j]);
            K[j, i] = K[i, j];
    return K;

def pds2diagrams(pds):
    print len(pds)
    diagrams = [];
#    print range(0, len(pds))
    for i in range(0, len(pds)):
        #diagrams.append(i)
        diagrams.append(d.Diagram([tuple(x) for x in pds[i]]))
    return diagrams
