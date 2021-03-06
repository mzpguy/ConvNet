
close all; clear mex;

kWorkspaceFolder = '..';

kCNNFolder = '..';
addpath(kCNNFolder);
addpath(fullfile(kCNNFolder, 'c++/build/'));
addpath(fullfile(kCNNFolder, 'matlab'));

load(fullfile('./weights', 'allweights.mat'), 'TrainWeights', 'TrainY');
kMaxTrainNum = size(TrainY, 1);
kTrainNum = 1000;
%TrainWeights = Weights(1:kTrainNum, :);
%TrainY = double(TrainY(1:kTrainNum, :));

is_ext = 0;
if (is_ext == 0)
  load(fullfile(kWorkspaceFolder, 'data', 'mnist.mat'), 'TestX', 'TestY');
else
  load(fullfile(kWorkspaceFolder, 'data', 'mnist_ext.mat'), 'TestX', 'TestY');
end;
kTestNum = 10000;
TestX = TestX(:, :, 1:kTestNum);
%load(fullfile(kWorkspaceFolder, 'test_weights.mat'), 'Weights', 'TestY');
%TestWeights = Weights(1:kTestNum, :);
TestY = double(TestY(1:kTestNum, :));
kOutputs = size(TrainY, 2);

params.batchsize = 50;
params.numepochs = 1;
params.momentum = 0.9;  
params.shuffle = 0;
params.verbose = 0;

kXSize = [size(TestX, 1) size(TestX, 2)];
s = kXSize;
if (is_ext == 0)
  ind1 = repmat((1:s(1))', [1 s(2)]) / s(1) - 0.5;
  ind2 = repmat(1:s(2), [s(1) 1]) / s(2) - 0.5;
  TrainX = zeros([1 2 1 prod(s)]);
  TrainX(1, 1, 1, :) = ind1(:);
  TrainX(1, 2, 1, :) = ind2(:);
elseif (is_ext == -1)
  kShift = [2 2];
  ind1 = repmat((1+kShift(1):s(1)+kShift(1))', [1 s(2)]) / (s(1)+2*kShift(1)) - 0.5;
  ind2 = repmat(1+kShift(2):s(2)+kShift(2), [s(1) 1]) / (s(2)+2*kShift(2)) - 0.5;
  TrainX = zeros([1 2 1 prod(s)]);
  TrainX(1, 1, 1, :) = ind1(:);
  TrainX(1, 2, 1, :) = ind2(:);
  params.numepochs = 5 * params.numepochs;
  params.shuffle = 1;
elseif (is_ext == 1)
  kShift = [2 2];
  TrainX = GetMultiCoords(s, kShift);
  TrainX = repmat(TrainX, kTrainNum, 1);
  TrainWeights = expand(TrainWeights, [5 1]);
  TrainY = expand(TrainY, [5 1]);
  kTrainNum = 5 * kTrainNum;
end;
%TestX = TrainX;

layers = cell(1, 2);
layers{1} = {
  struct('type', 'i', 'mapsize', [1 2])
  struct('type', 'f', 'length', 8)
  struct('type', 'f', 'length', 16)
  struct('type', 'f', 'length', 8)
  struct('type', 'f', 'length', 1, 'function', 'sigm') % image
};
layers{2} = {
  %struct('type', 'i', 'mapsize', kXSize, 'outputmaps', 1, ...
  %       'norm', norm_x, 'mean', mean_x, 'stdev', std_x) 
  struct('type', 'i', 'mapsize', kXSize, 'outputmaps', 1)
  struct('type', 'f', 'length', 60)
  struct('type', 'f', 'length', 60)  
  %struct('type', 'c', 'kernelsize', [5 5], 'outputmaps', 12)
  %struct('type', 's', 'scale', [2 2], 'function', 'mean')  
  %struct('type', 'f', 'length', 32)
  struct('type', 'f', 'length', kOutputs, 'function', 'soft')
};

funtype = 'mexfun';
%funtype = 'matlab';

alpha = 0.1;
beta = 0.2;
factor = 0.98;

if (is_ext ~= -1)
  currentfile = ['weights-' num2str(beta) '-cur.mat'];
  weightsfile = ['weights-' num2str(beta) '.mat'];
  resultsfile = ['results-' num2str(beta) '.mat'];  
else
  currentfile = ['weights-s-' num2str(beta) '-cur.mat'];
  weightsfile = ['weights-s-' num2str(beta) '.mat'];
  resultsfile = ['results-s-' num2str(beta) '.mat'];  
  disp('Short database');
end;

is_load = 0;
if (is_load == 0)
  kIterNum = 60;
  kEpochNum = 100;
  errors = zeros(kEpochNum, kIterNum);
  losses = zeros(kEpochNum, kIterNum);
  losses2 = zeros(kEpochNum, kIterNum);
  weights_in = genweights(layers{2}, 'matlab');
  WeightsIn = zeros(length(weights_in), kIterNum);
else
  load(fullfile('./results', resultsfile), 'errors', 'losses', 'losses2');
  kIterNum = size(errors, 2);
  kEpochNum = size(errors, 1);
  load(fullfile('./results', weightsfile), 'WeightsIn');
end;  
first_zero = find(errors(:) == 0, 1);
first_iter = floor((first_zero-1) / kEpochNum) + 1;
first_epoch = mod((first_zero-1), kEpochNum) + 1;

for iter = first_iter : kIterNum

rng(iter);
%perm_ind = randperm(kMaxTrainNum);
%TrainWeights = TrainWeights(perm_ind, :);
%TrainY = TrainY(perm_ind, :);
%[~, train_ind] = crossvalind('LeaveMOut', kMaxTrainNum, kTrainNum);
%train_weights = TrainWeights(train_ind, :);
%train_y = double(TrainY(train_ind, :));
train_weights = TrainWeights((iter-1)*kTrainNum+1 : iter*kTrainNum, :);
train_y = double(TrainY((iter-1)*kTrainNum+1 : iter*kTrainNum, :));

params.alpha = alpha;
params.beta = beta;
disp(['Alpha: ' num2str(params.alpha)]);
disp(['Beta: ' num2str(params.beta)]);

disp(['Iter: ' num2str(iter)])

weights_in = genweights(layers{2}, 'matlab');
if (is_load == 1)
  load(fullfile(kWorkspaceFolder, currentfile), 'weights_in');
end;
weights = cell(1, 2);
weights{2} = weights_in;

%[err, bad, pred] = cnntest(layers{2}, weights{2}, TestX, TestY, funtype);
%errors(epoch, iter) = err;  
%disp([num2str(errors(epoch, iter)*100) '% error']);

for epoch = 1 : first_epoch - 1
  perm_ind = randperm(kTrainNum);    
  params.alpha = params.alpha * factor;
  params.beta = params.beta * factor;  
end;

for epoch = first_epoch : kEpochNum
  
  perm_ind = randperm(kTrainNum);
  if (iscell(TrainX))
    train_x = TrainX(perm_ind);
  else
    train_x = TrainX;
  end;
  train_weights = train_weights(perm_ind, :);
  train_y = train_y(perm_ind, :);
  
  disp(['Epoch: ' num2str(epoch)])
  weights{1} = train_weights';  
  [weights, trainerr] = cnntrain_inv(layers, weights, train_x, train_y, params, funtype);  
  losses(epoch, iter) = mean(trainerr(:, 1));
  losses2(epoch, iter) = mean(trainerr(:, 2));
  disp([num2str(losses(epoch, iter)) ' loss']);
  disp([num2str(losses2(epoch, iter)) ' loss2']);
  %plot(trainerr(:,1));
  
  [err, bad, pred] = cnntest(layers{2}, weights{2}, TestX, TestY, funtype);
  errors(epoch, iter) = err;  
  disp([num2str(errors(epoch, iter)*100) '% error']);
  
  weights_in = weights{2};  
  save(fullfile('./results', currentfile), 'weights_in', 'trainerr');
  save(fullfile('./results', resultsfile), 'errors', 'losses', 'losses2');  
  
  params.alpha = params.alpha * factor;
  params.beta = params.beta * factor;  
  disp(' ');
end;

WeightsIn(:, iter) = weights{2};
save(fullfile('./results', weightsfile), 'WeightsIn', 'trainerr');

end;
