-- This script trains different NN models using Torch optim package. It is used
-- to train named entity recognition models.
-- Based on https://github.com/torch/demos/blob/master/train-a-digit-classifier/train-on-mnist.lua
----------------------------------------------------------------------

require 'torch'
require 'nn'
require 'optim'
require 'pl'
require 'paths'
require 'rnn'

----------------------------------------------------------------------
-- parse command-line options
--
local opt = lapp[[
   --save              (default "logs")      subdirectory to save logs
   --network           (default "")          reload pretrained network
   --activation        (default "tanh")      activation function
   --hiddenLayerSize   (default 50)          hidden layer size
   --hiddenLayers      (default 1)           number of hidden layers
   --batchSize         (default 1000)        batch size
   --maxIter           (default 10)          maximum nb of iterations
   --method            (default "sgd")       optimization method ("sgd", "adagrad", "adam")
   --learningRate      (default 0.01)        learning rate
   --learningRateFinal (default 0)           sgd parameter: final learning rate
   --momentum          (default 0)           sgd parameter: momentum
   --alpha             (default 0.99)        rmsprop parameter: alpha
   --l2                (default 0)           L2 penalty on the weights
   --dropout           (default 0)           dropout probability
   --shuffle           (default 0)           shuffle training data
   --cleCharDim        (default 64)          dimension of chars in cle
   --cleDim            (default 128)         dimension of cle
   --cleUnit           (default "LSTM")      network unit used for cle
   --threads           (default 1)           number of threads
   --trainData         (default "trainingData.txt")      training data file
   --testData          (default "testingData.txt")       testing data file
   --outputProbs       (default "outputProbs.txt")       output probs file
   --seed              (default 0)           seed
]]

-- fix seed
torch.manualSeed(1984 + opt.seed)

-- threads
torch.setnumthreads(opt.threads)
print('<torch> set nb of threads to ' .. torch.getnumthreads())

-- use floats
torch.setdefaulttensortype('torch.FloatTensor')

----------------------------------------------------------------------
-- data loading function
function load(filename, batchSize)
  local file = torch.DiskFile(filename, 'r')

  local header = file:readInt(7)
  local inputLayerSize = header[1]
  local clePerInstance = header[2]
  local cleNum = header[3]
  local cleChars = header[4]
  local cleMaxLen = header[5]
  local outputLayerSize = header[6]
  local size = header[7]

  local data = {}
  function data:clePerInstance() return clePerInstance end
  function data:cleChars() return cleChars end
  function data:inputLayerSize() return inputLayerSize end
  function data:outputLayerSize() return outputLayerSize end
  function data:size() return size end

  local cleLens = {}
  local cleSeqs = {}
  for i=1,cleNum do
    local cle = file:readInt(1 + cleMaxLen)
    cleLens[i] = cle[1]
    cleSeqs[i] = torch.IntTensor(cle, 2, cleMaxLen)
  end
  data.cleSeqs = cleSeqs
  data.cleLens = cleLens

  local instances = {}
  for i=1,data:size() do
    local line = file:readFloat(inputLayerSize + clePerInstance + 1)
    instances[i] = {torch.Tensor(line, 2 + clePerInstance, inputLayerSize), torch.Tensor(line, 2, clePerInstance), line[1] + 1}
  end

  local batches = {}
  for t = 0, size-1, batchSize do
    local batch = math.min(batchSize, size - t)
    local inputs = torch.Tensor(batch, inputLayerSize)
    local targets = torch.Tensor(batch)

    for i = 1, batch do
       inputs[i] = instances[i + t][1]
       targets[i] = instances[i + t][3]
    end

    if clePerInstance > 0 and opt.cleDim > 0 then
      local cleIds = torch.LongTensor(batch, clePerInstance)
      local cleNum = 0
      local cleBatchMaxLen = 1
      local cleMap = {}
      for i = 1, batch do
        cleIds[i] = instances[i + t][2]
        for j = 1, clePerInstance do
          if not cleMap[cleIds[i][j]] then
            cleNum = cleNum + 1
            cleMap[cleIds[i][j]] = cleNum
            if cleLens[cleIds[i][j]] > cleBatchMaxLen then
              cleBatchMaxLen = cleLens[cleIds[i][j]]
            end
          end
          cleIds[i][j] = cleMap[cleIds[i][j]]
        end
      end

      local cleFwd = {}
      local cleBwd = {}
      for i = 1, cleBatchMaxLen do
        cleFwd[i] = torch.IntTensor(cleNum):zero()
        cleBwd[i] = torch.IntTensor(cleNum):zero()
      end
      for i, j in pairs(cleMap) do
        for k = 1, cleLens[i] do
          cleFwd[cleBatchMaxLen - cleLens[i] + k][j] = cleSeqs[i][k]
          cleBwd[cleBatchMaxLen - k + 1][j] = cleSeqs[i][k]
        end
      end

      batches[#batches + 1] = {["inputs"] = {{{cleFwd, cleBwd}, cleIds:view(-1)}, inputs}, ["targets"] = targets}
    else
      batches[#batches + 1] = {["inputs"] = inputs, ["targets"] = targets}
    end
  end
  data.batches = batches

  return data
end
----------------------------------------------------------------------
-- load the data
--

print("Loading training data.");
trainData = load(opt.trainData, opt.batchSize)

print("Loading testing data.");
testData = load(opt.testData, 999999999)

----------------------------------------------------------------------
-- define model to train
do
  local Print, parent = torch.class('nn.Print', 'nn.Sequential')

  function Print:__init(module)
    parent.__init(self)
    parent.add(self, module)
  end

  function Print:toTable(what)
    if type(what) == "number" then return what end
    local result = {}
    if what.totable then what = what:totable() end
    for i, v in pairs(what) do
      result[i] = Print:toTable(v)
    end
    return result
  end

  function Print:updateOutput(input)
    print(Print:toTable(input))
    return parent.updateOutput(self, input)
  end
end

if opt.network == '' then
  model = nn.Sequential()
  -- Character-level embeddings
  if trainData:clePerInstance() > 0 and opt.cleDim > 0 then
    if opt.cleUnit == "LSTM" then
      opt.cleUnit = "FastLSTM"
    elseif opt.cleUnit ~= "GRU" then
      error('Unknown cleUnit!')
    end
    model:add(nn.ParallelTable()
      :add(nn.Sequential()
        :add(nn.ParallelTable()
          :add(nn.Sequential()
            :add(nn.ParallelTable()
              :add(nn.Sequential()
                :add(nn.Sequencer(nn.Sequential()
                  :add(nn.LookupTableMaskZero(trainData:cleChars(),opt.cleCharDim))
                  :add(nn[opt.cleUnit](opt.cleCharDim,opt.cleDim):maskZero(1))))
                :add(nn.SelectTable(-1)))
              :add(nn.Sequential()
                :add(nn.Sequencer(nn.Sequential()
                  :add(nn.LookupTableMaskZero(trainData:cleChars(),opt.cleCharDim))
                  :add(nn[opt.cleUnit](opt.cleCharDim,opt.cleDim):maskZero(1))))
                :add(nn.SelectTable(-1))))
            :add(nn.JoinTable(2)))
          :add(nn.Identity()))
        :add(nn.Index(1))
        :add(nn.View(-1, trainData:clePerInstance() * opt.cleDim * 2)))
      :add(nn.Identity()))
    model:add(nn.JoinTable(1, 1))
  end

  -- Final classification
  model:add(nn.Linear(trainData:inputLayerSize() + trainData:clePerInstance() * opt.cleDim * 2, opt.hiddenLayerSize))
  for layer = 1, opt.hiddenLayers do
    if opt.activation == 'tanh' then model:add(nn.Tanh()) end
    if opt.activation == 'relu' then model:add(nn.ReLU()) end
    if opt.activation == 'prelu' then model:add(nn.PReLU()) end
    if opt.dropout > 0 then
      model:add(nn.Dropout(opt.dropout))
    end
    if layer < opt.hiddenLayers then
      model:add(nn.Linear(opt.hiddenLayerSize, opt.hiddenLayerSize))
    end
  end
  model:add(nn.Linear(opt.hiddenLayerSize, trainData:outputLayerSize()))
  model:add(nn.LogSoftMax())
else
   print('<trainer> reloading previously trained network')
   model = torch.load(opt.network)
end

-- retrieve parameters and gradients
parameters,gradParameters = model:getParameters()

----------------------------------------------------------------------
-- loss function: negative log-likelihood
--
criterion = nn.ClassNLLCriterion()

----------------------------------------------------------------------
-- train
--
print("Starting training.")
for iter = 1, opt.maxIter do
  -- do one iteration
  local loss = 0
  model:training()
  local permutation = {}
  for i = 1, #trainData.batches do
    permutation[i] = i
    if opt.shuffle > 0 then
      local j = math.random(i)
      permutation[i], permutation[j] = permutation[j], permutation[i]
    end
  end
  for i = 1, #trainData.batches do
    local batch = trainData.batches[permutation[i]]
    local inputs = batch.inputs
    local targets = batch.targets

    -- create closure to evaluate f(X) and df/dX
    local feval = function(x)
       -- get new parameters
       if x ~= parameters then
          parameters:copy(x)
       end

       -- reset gradients
       gradParameters:zero()

       -- evaluate function for complete mini batch
       local outputs = model:forward(inputs)
       local f = criterion:forward(outputs, targets)

       -- estimate df/dW
       local df_do = criterion:backward(outputs, targets)
       model:backward(inputs, df_do)

       -- L2 regularization, without updating loss
       if opt.l2 ~= 0 then
          gradParameters:add(opt.l2 / #trainData.batches / opt.learningRate, parameters)
--            x:add(-opt.l2 / #trainData.batches, x) -- directly update x
       end

       -- return f and df/dX
       return f,gradParameters
    end

    -- optimize on current mini-batch
    local probs
    if opt.method == "sgd" then
      -- Perform SGD step:
      sgdState = sgdState or {
        learningRate = opt.learningRate,
        momentum = opt.momentum,
        learningRateDecay = opt.learningRateFinal > 0 and (opt.learningRate - opt.learningRateFinal) / (opt.learningRateFinal * opt.maxIter * #trainData.batches) or 0
      }
      _, probs = optim.sgd(feval, parameters, sgdState)
    elseif opt.method == "adagrad" then
      adaGradState = adaGradState or {
        learningRate = opt.learningRate,
        learningRateDecay = opt.learningRateFinal > 0 and (opt.learningRate - opt.learningRateFinal) / (opt.learningRateFinal * opt.maxIter * #trainData.batches) or 0
      }
      _, probs = optim.adagrad(feval, parameters, adaGradState)
    elseif opt.method == "adam" then
      adamState = adamState or {
        learningRate = opt.learningRate
      }
      _, probs = optim.adam(feval, parameters, adamState)
    elseif opt.method == "rmsprop" then
      rmspropState = rmspropState or {
        learningRate = opt.learningRate,
        alpha = opt.alpha
      }
      _, probs = optim.rmsprop(feval, parameters, rmspropState)
    elseif opt.method == "adadelta" then
      adadeltaState = adadeltaState or {
        learningRate = opt.learningRate
      }
      _, probs = optim.adadelta(feval, parameters, adadeltaState)
    else
      print("Unknown optimization method.")
      os.exit()
    end

    -- Update loss
    loss = loss + probs[1]
  end

  -- Evaluate testing data
  if (true) then
    local test_loss = 0
    local test_acc = 0
    model:evaluate()
    for i, batch in pairs(testData.batches) do
      local probs = model:forward(batch.inputs)
      local targets = batch.targets
      for j = 1, probs:size(1) do
        test_loss = test_loss + probs[j][targets[j]]
        test_acc = test_acc + (probs[j][targets[j]] == torch.max(probs[j]) and 1 or 0)
      end
    end
    test_acc = test_acc / testData:size()
    print(string.format("Iteration %d/%d: loss=%.3e, test_loss=%.3e, test_acc=%.2f%%", iter, opt.maxIter, loss, test_loss, 100 * test_acc))
  else
    print(string.format("Iteration %d/%d: loss=%.3e", iter, opt.maxIter, loss))
  end
end

print("Training complete.")

-- save final net
--local filename = paths.concat(opt.save, 'ner.net')
--os.execute('mkdir -p ' .. sys.dirname(filename))
--if paths.filep(filename) then
--    os.execute('mv ' .. filename .. ' ' .. filename .. '.old')
--end
--print('<trainer> saving network to '..filename)
-- torch.save(filename, model)

----------------------------------------------------------------------
-- run on test data
--

outputFile = torch.DiskFile(opt.outputProbs, 'w')

model:evaluate()
for i, batch in pairs(testData.batches) do
  local probs = model:forward(batch.inputs)
  for j = 1, probs:size(1) do
    outputFile:writeFloat(probs[j]:clone():storage())
  end
end
