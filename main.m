%==========================================================================
%                       DSGE MODEL ESTIMATION:  
%              Particle Filter Approximation of Likelihood 
%
%
% Author: Minsu Chang        minsuc@sas.upenn.edu
% Last modified: 2/24/2016
%
% Edited: Juan Castellanos Silv�n
% Date: 03/04/2020
%==========================================================================


clear
clc
close all
delete *.asv 

tic

l = path;

path('Mfiles',path);
path('LRE',path);

workpath = pwd;
savepath = [workpath, '/results/'];
chk_dir(savepath);

%=========================================================================
%                            EXPERIMENTS
%=========================================================================

naive = 0;          % 0 => COPF
                    % 1 => BSPF

sample = 1;         % 1 => Old sample 1983:I - 2002:IV
                    % 2 => New sample 1999:IV - 2019:III
                    
accuracy = 1;       % 0 => filters only run once
                    % 1 => filters run multiple times

% load data and consider parameters in Table 8.1.
if sample == 1
    yt = load('us.txt');
else 
    yt = load('us_update.txt');
end

param_m = [2.09 0.98 2.25 0.65 0.34 3.16 0.51 0.81 0.98 0.93 0.19 0.65 0.24];
param_l = [3.26 0.89 1.88 0.53 0.19 3.29 0.73 0.76 0.98 0.89 0.20 0.58 0.29];

% check whether likelihood in Table 8.1. is replicated
% dsgeliki_text(param_m)

[T1, ~, T0, ~, ~, ~] = model_solution(param_m);
[A,B,H,R,S2,Phi] = sysmat(T1,T0,param_m);

% Kalman filter result
[liki, measurepredi, statepredi, varstatepredi] = kalman(A,B,H,R,S2,Phi,yt);

ns      = size(B,2);
T       = size(yt,1);

% initialize
x0 = zeros(ns,1);
P0 = nearestSPD(dlyap(Phi, R*S2*R'));  % to make it positive semidefinite

% number of particles
if naive == 0
    N = 40000; 
else 
    N = 400;
end

% Accuracy of approximation
if accuracy == 0
   
    [lik, all_s_up, Neff] = PF_lik(A, B, H, Phi, R, S2, N, yt, x0, P0, naive);
    % Last input denotes the indicator for bootstrap particle filtering.
    % if == 1, it performs bootstrap particle filtering. otherwise, it does
    % conditionally-optimal particle filtering.

    sum(lik)
    
else
    
    % Pre-allocation
    Nrun = 100;
    mLik = zeros(T,Nrun);
    
    % Monte-Carlo
    for  i=1:Nrun
    
        [lik, all_s_up, Neff] = PF_lik(A, B, H, Phi, R, S2, N, yt, x0, P0, naive);
        mLik(:,i) = lik;
    
         if mod(i,20)==0 || i == 1
            disp([' Likelihood = ', num2str(sum(lik)), ' Iteration  = ',  num2str(i)])
        end
    end
    
    Delta1 = mLik - repmat(liki,1,Nrun);
    
end

% save results
filename = strcat('PF_naive', num2str(naive),'_sample', num2str(sample),'_accuracy', num2str(accuracy),'.mat');
save(strcat(savepath,filename))

path(l);
disp(['         ELAPSED TIME:   ', num2str(toc)]);
elapsedtime=toc;



