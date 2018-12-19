% Demo: learn a sinc. Run and compare all algorithms using their default
% parameters.
%
% This file is part of the Kernel Adaptive Filtering Toolbox for Matlab.
% https://github.com/steven2358/kafbox/

close all
clear
rng('default'); rng(1)

%% PARAMETERS

N = 1000; % number of training data
N_test = 500; % number of test data
SNR = 20; % SNR in dB

%% PROGRAM

% generate data
x = randn(N,1);
x_test = linspace(min(x),max(x),N_test)';
y_ref = sinc([x;x_test]);
y = y_ref + sqrt(10^(-SNR/10)*var(y_ref))*randn(N+N_test,1);
y_test = y_ref(N+1:N+N_test);

% get list of kernel adaptive filters in 'lib' folder
fdir = fileparts(which('kafbox_template.m'));
files = dir(fullfile(fdir,'*.m'));
[~,algorithms] = cellfun(@fileparts, {files.name}, 'UniformOutput',0);
for i=length(algorithms):-1:1,
    if ~exist(algorithms{i},'class'),
        algorithms(i) = []; % remove files that do not represent classes
    end
end

% perform online learning for each algorithm
fprintf('\n')
num_alg = length(algorithms);
titles = cell(num_alg,1);
MSE = zeros(num_alg,1);
Y_est = zeros(N_test,num_alg);
for algo_ind=1:num_alg
    t1 = tic;
    algorithm = algorithms{algo_ind};
    fprintf('%2d. %9s: ',algo_ind,upper(algorithm));
    titles{algo_ind} = strrep(upper(algorithm),'_','\_');

    kaf = feval(algorithm);
    for i=1:N,
        if ~mod(i,floor(N/10)), fprintf('.'); end
        kaf.train(x(i),y(i));
    end
    y_est = kaf.evaluate(x_test);
    Y_est(:,algo_ind) = y_est;
    MSE(algo_ind) = mean((y_test-y_est).^2);
    
    fprintf(' %.2fs. MSE=%3.2fdB\n',toc(t1),10*log10(MSE(algo_ind)))
end

%% OUTPUT

% plot results in different "leagues"
[MSE_sorted,ind] = sort(MSE,'descend');
num_fig = ceil(num_alg/5);

remaining = num_alg;
titles{num_alg+1} = 'data';
for fig_ind=num_fig:-1:1
    figure; hold all
    plot(x,y(1:N),'.')
    
    rm = rem(remaining,5);
    num_in_league = (rm==0)*5 + rm;
    % plot the results for the num_in_league worst results
    league_inds = num_alg-remaining+num_in_league:-1:num_alg-remaining+1;
    for i=league_inds,
        plot(x_test,Y_est(:,ind(i)),'LineWidth',2)
    end
    title(sprintf('League %d',fig_ind))
    legend(titles([num_alg+1; ind(league_inds)]))

    axis([min(x)-0.5 max(x)+0.5 min(y)-0.5 max(y)+0.5]);
    remaining = remaining - num_in_league;
end
