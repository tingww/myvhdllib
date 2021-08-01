import numpy as np
from functools import reduce

def conv_enc(u,g,m) :
    codebits = np.array([])
    mem = np.array([])
    c = np.array([])
    for i in range(m):
        mem = np.append(mem,0)
    for i in range(u.size):
        mem = np.append(mem,u[i])
        if i!=0 : mem = mem[1:]
        for _ in g:
            c = np.append(c,reduce(lambda x,y: x^y, np.logical_and(_,mem) ) )
        codebits = np.append(codebits,c)
        c = np.array([])
    return np.resize(codebits,(u.size,g.shape[0]))
class state_table_class :
    def __init__(self,prev_state,outp,inp):
        self.prev_state=prev_state
        self.outp=outp
        self.inp=inp
def conv_dec_sliding(d_in,state_table,Lc=10,debug=False):
    accumulative_metric = np.zeros(state_table.outp.shape[1],dtype=int)
    accumulative_metric_nxt = np.zeros(state_table.outp.shape[1],dtype=int)
    path_matrix_entry = np.zeros(state_table.outp.shape[1],dtype=int)
    path_matrix = np.array([])
    d_out = np.zeros(d_in.shape[0],dtype=int)
    message_size = d_in.shape[0]

    for k in range(message_size):        
        for j in range(state_table.outp.shape[1]):
            for i in range(state_table.outp.shape[0]):
                branch_metrics = np.logical_xor(d_in[k],state_table.outp[i][j]).sum()   #calculate branch metrics
                if i==0:
                    min_path = state_table.prev_state[0][j]
                    min_bm = branch_metrics + accumulative_metric[min_path] #Add
                else :
                    current_path = state_table.prev_state[i][j]
                    current_bm = branch_metrics+accumulative_metric[current_path]
                    if  current_bm < min_bm :    #Compare
                        min_path = current_path
                        min_bm = current_bm
            accumulative_metric_nxt[j] = min_bm 
            path_matrix_entry[j] = min_path
            
        #update accumulative metric
        accumulative_metric = np.copy(accumulative_metric_nxt)  
        #update path_matrix
        if k == 0 : 
            path_matrix = path_matrix_entry
        else:
            path_matrix = np.vstack([path_matrix,path_matrix_entry])

        #trace back after initialization
        if k >= Lc-1 and k != message_size-1:
            min_index = np.argmin(accumulative_metric)
            for i in range(Lc):
                prev_path = path_matrix[path_matrix.shape[0]-1-i][min_index]
                if i==Lc-1 :        #only output (update) last one d_out
                    if prev_path == state_table.prev_state[0][min_index]:
                        d_out[k-i] = state_table.inp[0][min_index]
                    else:
                        d_out[k-i] = state_table.inp[1][min_index]
                min_index = prev_path
            path_matrix = path_matrix[1:]
        elif k==message_size-1: #termination
            min_index = np.argmin(accumulative_metric)
            for i in range(Lc):
                prev_path = path_matrix[path_matrix.shape[0]-1-i][min_index]
                if prev_path == state_table.prev_state[0][min_index]:
                    d_out[k-i] = state_table.inp[0][min_index]
                else:
                    d_out[k-i] = state_table.inp[1][min_index]
                min_index = prev_path
            
            if debug==True:
                print("path_matrix : \n", path_matrix , "\naccumulative metric : ",accumulative_metric )
    return d_out
def conv_dec_sliding_v2(d_in,state_table,Lc=10,debug=False):    #trace back without compare when not in termination
    accumulative_metric = np.zeros(state_table.outp.shape[1],dtype=int)
    accumulative_metric_nxt = np.zeros(state_table.outp.shape[1],dtype=int)
    path_matrix_entry = np.zeros(state_table.outp.shape[1],dtype=int)
    path_matrix = np.array([])
    d_out = np.zeros(d_in.shape[0],dtype=int)
    message_size = d_in.shape[0]

    for k in range(message_size):        
        for j in range(state_table.outp.shape[1]):
            for i in range(state_table.outp.shape[0]):
                branch_metrics = np.logical_xor(d_in[k],state_table.outp[i][j]).sum()   #calculate branch metrics
                if i==0:
                    min_path = state_table.prev_state[0][j]
                    min_bm = branch_metrics + accumulative_metric[min_path] #Add
                else :
                    current_path = state_table.prev_state[i][j]
                    current_bm = branch_metrics+accumulative_metric[current_path]
                    if  current_bm < min_bm :    #Compare
                        min_path = current_path
                        min_bm = current_bm
            accumulative_metric_nxt[j] = min_bm 
            path_matrix_entry[j] = min_path
            
        #update accumulative metric
        accumulative_metric = np.copy(accumulative_metric_nxt)  
        #update path_matrix
        if k == 0 : 
            path_matrix = path_matrix_entry
        else:
            path_matrix = np.vstack([path_matrix,path_matrix_entry])

        #trace back after initialization
        if k >= Lc-1 and k != message_size-1:
            min_index = 0                            #---------trace back without compare--------------
            for i in range(Lc):
                prev_path = path_matrix[path_matrix.shape[0]-1-i][min_index]
                if i==Lc-1 :        #only output (update) last one d_out
                    if prev_path == state_table.prev_state[0][min_index]:
                        d_out[k-i] = state_table.inp[0][min_index]      #filling d_out from the lower k
                    else:
                        d_out[k-i] = state_table.inp[1][min_index]
                min_index = prev_path
            path_matrix = path_matrix[1:]
        elif k==message_size-1: #termination
            min_index = np.argmin(accumulative_metric)
            for i in range(Lc):
                prev_path = path_matrix[path_matrix.shape[0]-1-i][min_index]
                if prev_path == state_table.prev_state[0][min_index]:
                    d_out[k-i] = state_table.inp[0][min_index]          #filling d_out from the higher k, which is different in hardware
                else:
                    d_out[k-i] = state_table.inp[1][min_index]
                min_index = prev_path
            
            if debug==True:
                print("path_matrix : \n", path_matrix , "\naccumulative metric : ",accumulative_metric )
    return d_out
def BSC(x,Pe=0.15):
    r = np.random.random_sample(x.shape)
    bfm = r<Pe
    return np.mod(x+bfm,2)
def BER(u,u_hat):
    size = u.size
    return np.count_nonzero(u_hat!=u)/(size)


prev_state = np.array(((0,2,0,2),(1,3,1,3)))
outp = np.array( (((0,0),(1,0),(1,1),(0,1)) ,((1,1),(0,1),(0,0),(1,0)) ))
inp = np.array(((0,0,1,1),(0,0,1,1)))
state_table = state_table_class(prev_state,outp,inp)
message_size = 100
u = np.random.randint(0,2,size=message_size)
g = np.array([[1,1,1], [1,0,1]])
m = 2
Lc = 8
d_in = conv_enc(u,g,m)
d_in_hat = BSC(d_in,Pe=0.1)
u_hat = conv_dec_sliding(d_in_hat,state_table,Lc=Lc) #5 times the memory element number
u_hat_ideal = conv_dec_sliding(d_in,state_table,Lc=Lc)

latency = Lc+2
enable = np.append(np.ones(message_size),np.zeros(latency)).astype(int)
valid_out = np.append(np.zeros(latency),np.ones(message_size)).astype(int)

u_hat_ideal_padded = np.append(np.zeros(latency),u_hat_ideal).astype(int)

pad = np.zeros(latency*2).reshape((latency,2))
d_in_padded = np.append(d_in,pad,axis=0).astype(int)

f = open(file="conv_dec_tb.txt",mode='w')
for i in range(len(d_in_padded)):
    f.write(str(enable[i]) + ''.join(str(d_in_padded[i][j]) for j in range(2)) + str(u_hat_ideal_padded[i]) + str(valid_out[i]) + "\n")
f.close()