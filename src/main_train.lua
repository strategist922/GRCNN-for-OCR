require('cutorch')
require('nn')
require('cunn')
require('cudnn')
require('optim')
require('paths')
require('nngraph')

require('libcrnn')
require('utilities')
require('training')
require('inference')
require('CtcCriterion')
require('DatasetLmdb')
require('LstmLayer')
require('BiRnnJoin')
require('SharedParallelTable')


-- configurations
cutorch.setDevice(1)
torch.setnumthreads(4)
torch.setdefaulttensortype('torch.FloatTensor')
local modelDir = arg[1]
setupLogger(paths.concat(modelDir, 'log.txt'))
paths.dofile(paths.concat(modelDir, 'GRCL_LSTM_pretrain.lua'))
gConfig = getConfig()
gConfig.modelDir = modelDir

-- `createModel` is defined in config.lua, it returns the network model and the criterion (loss function)
local model, criterion = createModel(gConfig)
logging(string.format('Model configuration:\n%s', model))
local modelSize, nParamsEachLayer = modelSize(model)
logging(string.format('Model size: %d\n%s', modelSize, nParamsEachLayer))

-- load model snapshot
local loadPath = arg[3]
if loadPath then
    local net = torch.load(loadPath)   
    loadModelState(model, net)
    logging(string.format('Model loaded from %s', loadPath))
end

-- load save model path
local savePath = arg[2]
if savePath then
   savePath = arg[2]
else
   savePath = "./"
end

-- load dataset
logging('Loading datasets...')
local trainSet = DatasetLmdb(gConfig.trainSetPath, gConfig.trainBatchSize)
local valSet = DatasetLmdb(gConfig.valSetPath)

-- train and test model
logging('Start training...')
trainModel(model, criterion, trainSet, valSet, savePath)

shutdownLogger()
