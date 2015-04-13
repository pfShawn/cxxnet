train_cfg = [
'iter = mnist\n'...
'    path_img = "./data/train-images-idx3-ubyte"\n'...
'    path_label = "./data/train-labels-idx1-ubyte"\n'...
'    input_flat = 0\n'...
'    shuffle = 1\n'...
'iter = end\n'...
'input_shape = 1,28,28\n'...
'batch_size = 100\n'];
train_cfg = sprintf(train_cfg);

eval_cfg = [
'iter = mnist\n'...
'    input_flat = 0\n'...
'    path_img = "./data/t10k-images-idx3-ubyte"\n'...
'    path_label = "./data/t10k-labels-idx1-ubyte"\n'...
'iter = end\n'...
'input_shape = 1,28,28\n'...
'batch_size = 100\n'
];
eval_cfg = sprintf(eval_cfg);

cfg = [
'netconfig=start\n'...
'layer[0->1] = conv:cv1\n'...
'  kernel_size = 5\n'...
'  pad = 1\n'...
'  stride = 2\n'...
'  nchannel = 32\n'...
'  random_type = xavier\n'...
'  no_bias=0\n'...
'layer[1->2] = max_pooling\n'...
'  kernel_size = 3\n'...
'  stride = 2\n'...
'layer[2->3] = flatten\n'...
'layer[3->3] = dropout\n'...
'  threshold = 0.5\n'...
'layer[3->4] = fullc:fc1\n'...
'  nhidden = 100\n'...
'  init_sigma = 0.01\n'...
'layer[4->5] = sigmoid:se1\n'...
'layer[5->6] = fullc:fc2\n'...
'  nhidden = 10\n'...
'  init_sigma = 0.01\n'...
'layer[6->6] = softmax\n'...
'netconfig=end\n'...
'# input shape not including batch\n'...
'input_shape = 1,28,28\n'...
'batch_size = 100\n'...
'train_eval = 1\n'...
'random_type = gaussian\n'...
'eta = 0.1\n'...
'momentum = 0.9\n'...
'wd  = 0.0\n'...
'metric = error\n'...
];

cfg = sprintf(cfg);

train = DataIter(train_cfg);
eval = DataIter(eval_cfg);

net = Net('gpu', cfg);
net.init_model();

% train 1 epoch
train.before_first();
while train.next() == 1
    net.update(train);
end
net.evaluate(eval, 'eval');
train.before_first();
eval.before_first();
w1 = net.get_weight('cv1', 'wmat');
b1 = net.get_weight('cv1', 'bias');
w2 = net.get_weight('fc1', 'wmat');
b2 = net.get_weight('fc1', 'bias');
w3 = net.get_weight('fc2', 'wmat');
b3 = net.get_weight('fc2', 'bias');
% train second epoch

while train.next() == 1,
  d = train.get_data();
  l = train.get_label();
  net.update(d, l);
end
net.evaluate(eval, 'eval');
eval.before_first();

% reset weight
net.set_weight(w1, 'cv1', 'wmat');
net.set_weight(b1, 'cv1', 'bias');
net.set_weight(w2, 'fc1', 'wmat');
net.set_weight(b2, 'fc1', 'bias');
net.set_weight(w3, 'fc2', 'wmat');
net.set_weight(b3, 'fc2', 'bias');
net.evaluate(eval, 'eval');

% train more and show weight
for i = 1 : 15
    train.before_first();
    while train.next() == 1
        net.update(train);
    end
    eval.before_first();
    net.evaluate(eval, 'eval');
end
w1 = net.get_weight('cv1', 'wmat');
b1 = net.get_weight('cv1', 'bias');
w = [];
for i = 1 : 32
    w = [w ones(5, 1) reshape(w1(1, i, :), [5, 5])];
end
figure; imshow(w, []);
% get prediction
eval.before_first();
pred = [];
while eval.next() == 1
    pred = [pred; net.predict(eval.get_data())];
end

% get the prediction using extract features
eval.before_first();
pred_prob = [];
while eval.next() == 1
    pred_prob = [pred_prob; net.extract(eval, 'top[-1]')];
end

% assert the results are correct
[~, id] = max(pred_prob, [], 4);
assert(sum(pred + 1 == id) == 10000);

delete(net);
delete(train);
delete(eval);