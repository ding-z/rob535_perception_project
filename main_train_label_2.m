%% Main Vehicle Detection
clear all
%% Arrage training data.
%files = dir('trainval/*/*_image.jpg');
files = dir('C:\Users\zhding\Desktop\rob535_percention_data\data-2019\trainval/*/*_image.jpg');
%files = dir('C:\Users\PC\Desktop\rob535_perception_data\data-2019\trainval/*/*_image.jpg');
result_detector_name = 'detector_label_2_p9_e6_v1';

% Total training images: 5561
% Label_1: 2791
% Label_2: 1051
% Label_3: 138
% Label_0: 1581
num_file_per_class = [2791; 1051; 138; 1581];
image_size = [1914, 1052];
num_class = 1; % Not including empty type.
AllTrainData =  prepare_data(files, num_file_per_class, image_size);
% Format: {{file_name_of_label_1, box_of_label_1}, 
%          {file_name_of_label_2, box_of_label_2},
%          {file_name_of_label_3, box_of_label_3},
%          {file_name_of_label_0, empty}}
%AllTrainData =  prepare_data_multi_class(files, num_class, image_size);
% Format: {{file_name}, {box_of_label_1}, {box_of_label_2},{box_of_label_3}}


%% Download pretrained detector.
doTrainingAndEval = true;
% if ~doTrainingAndEval && ~exist('fasterRCNNResNet50EndToEndVehicleExample.mat','file')
%     disp('Downloading pretrained detector (118 MB)...');
%     pretrainedURL = 'https://www.mathworks.com/supportfiles/vision/data/fasterRCNNResNet50EndToEndVehicleExample.mat';
%     websave('fasterRCNNResNet50EndToEndVehicleExample.mat',pretrainedURL);
% end

%% Load data set.
%unzip vehicleDatasetImages.zip
%data = load('vehicleDatasetGroundTruth.mat');
%vehicleDataset = data.vehicleDataset;

% Convert data storage into table form.
%imageFilename = AllTrainData{1}(:,1);
imageFilename = AllTrainData{2}(:,1);
%imageFilename = AllTrainData{3}(:,1);

%label_1 = AllTrainData{1}(:,2);
label_2 = AllTrainData{2}(:,2);
%label_3 = AllTrainData{3}(:,2);

%vehicleDataset = table(imageFilename, label_1);
vehicleDataset = table(imageFilename, label_2);
%vehicleDataset = table(imageFilename, label_3);

%vehicleDataset = data.vehicleDataset;



%rng(0)
shuffledIdx = randperm(height(vehicleDataset));
idx = floor(0.95 * height(vehicleDataset));
trainingDataTbl = vehicleDataset(shuffledIdx(1:idx),:);
testDataTbl = vehicleDataset(shuffledIdx(idx+1:end),:);

imdsTrain = imageDatastore(trainingDataTbl{:,'imageFilename'});
%bldsTrain = boxLabelDatastore(trainingDataTbl(:,'label_1'));
bldsTrain = boxLabelDatastore(trainingDataTbl(:,'label_2'));
%bldsTrain = boxLabelDatastore(trainingDataTbl(:,'label_3'));

imdsTest = imageDatastore(testDataTbl{:,'imageFilename'});
%bldsTest = boxLabelDatastore(testDataTbl(:,'label_1'));
bldsTest = boxLabelDatastore(testDataTbl(:,'label_2'));
%bldsTest = boxLabelDatastore(testDataTbl(:,'label_3'));


trainingData = combine(imdsTrain,bldsTrain);
testData = combine(imdsTest,bldsTest);

data = read(trainingData);
I = data{1};
bbox = data{2}; % [upper_left_x, upper_left_y, width_x, height_y]
annotatedImage = insertShape(I,'Rectangle',bbox);
annotatedImage = imresize(annotatedImage,2);
figure
imshow(annotatedImage)

%% Create Faster R-CNN detection network.
inputSize = [224 224 3];%[1052, 1052, 3]; % [399, 224,3] -> [224 224 3], [1914, 1052,3] -> [1052, 1052, 3]
%inputSize = [224 224 3];%[1052, 1052, 3]; % [399, 224,3] -> [224 224 3], [1914, 1052,3] -> [1052, 1052, 3]
%inputSize = [416 416 3];%[1052, 1052, 3]; % [399, 224,3] -> [224 224 3], [1914, 1052,3] -> [1052, 1052, 3]


preprocessedTrainingData = transform(trainingData, @(data)preprocessData(data,inputSize));
numAnchors = 4;
anchorBoxes = estimateAnchorBoxes(preprocessedTrainingData,numAnchors);

featureExtractionNetwork = resnet50;

featureLayer = 'activation_40_relu';

numClasses = width(vehicleDataset)-1;

lgraph = fasterRCNNLayers(inputSize,numClasses,anchorBoxes,featureExtractionNetwork,featureLayer);


%% Data augmentation.
augmentedTrainingData = transform(trainingData,@augmentData);

augmentedData = cell(4,1);
for k = 1:4
    data = read(augmentedTrainingData);
    augmentedData{k} = insertShape(data{1},'Rectangle',data{2});
    reset(augmentedTrainingData);
end
figure
montage(augmentedData,'BorderSize',10)


%% Preprocess training data.
trainingData = transform(augmentedTrainingData,@(data)preprocessData(data,inputSize));

data = read(trainingData);


I = data{1};
bbox = data{2};
annotatedImage = insertShape(I,'Rectangle',bbox);
annotatedImage = imresize(annotatedImage,2);
figure
imshow(annotatedImage)

%% Train Faster R-CNN.
tic
options = trainingOptions('sgdm',...
    'MaxEpochs',10,...
    'MiniBatchSize',1,...
    'InitialLearnRate',1e-3,...
    'CheckpointPath',tempdir);
  
if doTrainingAndEval
    % Train the Faster R-CNN detector.
    % * Adjust NegativeOverlapRange and PositiveOverlapRange to ensure
    %   that training samples tightly overlap with ground truth.
    [detector, info] = trainFasterRCNNObjectDetector(trainingData,lgraph,options, ...
        'NegativeOverlapRange',[0   0.3], ...
        'PositiveOverlapRange',[0.6 1]);
else
    % Load pretrained detector for the example.
    pretrained = load('fasterRCNNResNet50EndToEndVehicleExample.mat');
    detector = pretrained.detector;
end
  


disp('Train Time:')
toc

%% Evaluate Detector using test set.
tic
testData = transform(testData,@(data)preprocessData(data,inputSize));


if doTrainingAndEval
    detectionResults = detect(detector,testData,'MinibatchSize',1);
    detectionResultsTrain = detect(detector,preprocessedTrainingData,'MinibatchSize',1);
    
else
    % Load pretrained detector for the example.
    pretrained = load('fasterRCNNResNet50EndToEndVehicleExample.mat');
    detectionResults = pretrained.detectionResults;
end
    
[ap, recall, precision] = evaluateDetectionPrecision(detectionResults,testData);
[ap_train, recall_train, precision_train] =...
  evaluateDetectionPrecision(detectionResultsTrain,preprocessedTrainingData);


disp('Test Time:')
toc

figure
subplot(1,2,1)
plot(recall,precision)
xlabel('Recall')
ylabel('Precision')
grid on
title(sprintf('Test Average Precision = %.2f', ap))

subplot(1,2,2)
plot(recall_train,precision_train)
xlabel('Recall')
ylabel('Precision')
grid on
title(sprintf('Train Average Precision = %.2f', ap_train))

%% Number of detected images.
num_detected = 0;
for i = 1:size(detectionResults,1)
    if size(detectionResults{i,1}{1},1) > 0
        num_detected = num_detected + 1;
    end
end
detected_ratio = num_detected/size(detectionResults,1)


num_detected_train = 0;
for i = 1:size(detectionResultsTrain,1)
    if size(detectionResultsTrain{i,1}{1},1) > 0
        num_detected_train = num_detected_train + 1;
    end
end
detected_ratio_train = num_detected_train/size(detectionResultsTrain,1)


%% Save the network.
save(result_detector_name, 'detector', 'info', 'detectionResults', ...
     'detected_ratio', 'detectionResultsTrain', 'detected_ratio_train', 'ap', 'ap_train')

