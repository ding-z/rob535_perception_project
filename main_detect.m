%% Main Vehicle Classification
clear all
%% Arrage training data.
%files = dir('trainval/*/*_image.jpg');
files = dir('C:\Users\zhding\Desktop\rob535_percention_data\data-2019\test/*/*_image.jpg');
%files = dir('C:\Users\PC\Desktop\rob535_perception_data\data-2019\test/*/*_image.jpg');
detector_1_file = 'detector_label_1_p95_e20_na5_v2.mat';
detector_2_file = 'detector_label_2_p9_e6_v1.mat';
detector_3_file = 'detector_label_3_p9_e50_na6_v1.mat';
detection_result_file = 'detection_results_all_v1';
task_1_result_name = 'result_task_1_v1.csv';
task_2_result_name = 'result_task_2_v1.csv';
task_2_template_name = 'task_2_temp.csv';
do_detection = 1;

% Total training images: 5561
% Label_1: 2791
% Label_2: 1051
% Label_3: 138
% Label_0: 1581

% Total testing images: 1799
% Label_1: 0.45969
% Label_2: 0.19566
% Label_3: 0.02001
% Label_0: 0.32462

num_file_per_class = [2791; 1051; 138; 1581];
image_size = [1914, 1052];
num_class = 3; % Not including empty type.
%AllTrainData =  prepare_data(files, num_file_per_class, image_size);
AllTestData =  prepare_data_test(files);
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
imageFilename = AllTestData(:,1);

label = AllTestData(:,2);


vehicleDataset = table(imageFilename, label);


testDataTbl = vehicleDataset;

imdsTest = imageDatastore(testDataTbl{:,'imageFilename'});
bldsTest = boxLabelDatastore(testDataTbl(:,'label'));

testData = combine(imdsTest,bldsTest);



%% Evaluate Detector using test set.
tic
if do_detection
  inputSize = [224 224 3];%[1052, 1052, 3]; % [399, 224,3] -> [224 224 3], [1914, 1052,3] -> [1052, 1052, 3]
  testData = transform(testData,@(data)preprocessData(data,inputSize));

  % Load pretrained detector for the example.
  %pretrained = load('fasterRCNNResNet50EndToEndVehicleExample.mat');
  result_1 = load(detector_1_file);
  detector_1 = result_1.detector;
  result_2 = load(detector_2_file);
  detector_2 = result_2.detector;
  result_3 = load(detector_3_file);
  detector_3 = result_3.detector;

  disp('Detection of label 1...')
  detectionResults_1 = detect(detector_1,testData,'MinibatchSize',1);
  detectionResults{1} = detectionResults_1;
  disp('Detection of label 2...')
  detectionResults_2 = detect(detector_2,testData,'MinibatchSize',1);
  detectionResults{2} = detectionResults_2;
  disp('Detection of label 3...')
  detectionResults_3 = detect(detector_3,testData,'MinibatchSize',1);
  detectionResults{3} = detectionResults_3;

  %detectionResultsTrain = detect(detector,preprocessedTrainingData,'MinibatchSize',1);
  save(detection_result_file)
else
  load(detection_result_file)
end

disp('Test Time:')
toc



%% Number of detected images for each label.
num_files = length(files);
detected_label_1 = zeros(num_files,1);
detected_label_2 = zeros(num_files,1);
detected_label_3 = zeros(num_files,1);
num_detected_1 = 0;
num_detected_2 = 0;
num_detected_3 = 0;

for i = 1:num_files
    if size(detectionResults_1{i,1}{1},1) > 0
        num_detected_1 = num_detected_1 + 1;
        detected_label_1(i,1) = 1;
    end
    if size(detectionResults_2{i,1}{1},1) > 0
        num_detected_2 = num_detected_2 + 1;
        detected_label_2(i,1) = 1;
    end
    if size(detectionResults_3{i,1}{1},1) > 0
        num_detected_3 = num_detected_3 + 1;
        detected_label_3(i,1) = 1;
    end
end
detected_label_all = detected_label_1 | detected_label_2 | detected_label_3;

detected_ratio_1 = num_detected_1/num_files
detected_ratio_2 = num_detected_2/num_files
detected_ratio_3 = num_detected_3/num_files
detected_ratio_all = sum(detected_label_all)/num_files


%% Load point clouds and classify each image.
scale_x = inputSize(1)/image_size(1);
scale_y = inputSize(2)/image_size(2);
% Use a smaller box (than detected) to check points distance.
scale_box = 0.8;
% Only detections within dist_thrs are considered.
dist_thrs = 50;
% Save results.
result_label = zeros(num_files,1);
result_table = cell(num_files+1,2);
result_table{1,1} = 'guid/image';
result_table{1,2} = 'label';
% Find partial string name.
snapshot = [files(1).folder, '/', files(1).name];
k_str = strfind(snapshot, 'test\') + 5;

% Results for task two.
result_table_task_2 = cell(num_files+1,3);
result_table_task_2{1,1} = 'guid/image';
result_table_task_2{1,2} = 'value r';
result_table_task_2{1,3} = 'value theta';


for i = 1:num_files
  if mod(i,100) == 0
    disp([num2str(i), ' / ', num2str(num_files)])
  end
  %i = 130;%137;%7;
  snapshot = [files(i).folder, '/', files(i).name];
  result_table{i+1,1} = snapshot(k_str:end-10);
  result_table_task_2{i+1,1} = snapshot(k_str:end-10);
  
  img = imread(snapshot);
  
  % Read point cloud.
  xyz = read_bin(strrep(snapshot, '_image.jpg', '_cloud.bin'));
  xyz = reshape(xyz, [], 3)';
  proj = read_bin(strrep(snapshot, '_image.jpg', '_proj.bin'));
  proj = reshape(proj, [4, 3])';
  uv = proj * [xyz; ones(1, size(xyz, 2))];
  uv = uv ./ uv(3, :);
  % Compute distance to each point.
  dist = vecnorm(xyz);
  % Lidar points in scaled image.
  uv_s = uv(1:2,:)'.*[scale_x, scale_y];
  
  % Check boxs of each label.
  % Label 1 through 3.
  boxs_label = cell(3,1);
  scores_label = cell(3,1);
  dists_label = cell(3,1);
  best_score = 0;
  best_label = 0;
  % Task 2.
  best_r = 0;
  best_theta = 0;
  for label = 1:3
    boxs_label{label,1} = detectionResults{label}{i,1}{1};
    scores_label{label,1} = detectionResults{label}{i,2}{1};
    n_box = size(boxs_label{label,1},1);
    dists_label{label,1} = inf(n_box,1);
    for ib = 1:n_box
      [box_vx, box_vy] = get_vertices(boxs_label{label,1}(ib,:), scale_box);
      % Find lidar points that are within the scaled detection box.
      idx_in = inpolygon(uv_s(:,1), uv_s(:,2), box_vx, box_vy);
      % Compute median distance of the points within.
      dist_in = median(dist(idx_in));
      dists_label{label,1}(ib,1) = nanmin(dist_in, dists_label{label,1}(ib,1));
      % For task 2, real world position.
      xyz_in = xyz(:,idx_in);
      xyz_median = median(xyz_in');
      r = sqrt(sum(xyz_median.^2));
      theta = rad2deg(atan(xyz_median(1)/xyz_median(3)));
      
      % Check if the detection is within 50 meters.
      if dists_label{label,1}(ib,1) < dist_thrs
        % Check if the detection has best score.
        if scores_label{label,1}(ib,1) > best_score
          best_score = scores_label{label,1}(ib,1);
          best_label = label;
          % Task 2.
          best_r = r;
          best_theta = theta;
          
        end
      end
    end
  end
  result_label(i) = best_label;
  result_table{i+1,2} = best_label;
  % Task 2.
  result_table_task_2{i+1,2} = best_r;
  result_table_task_2{i+1,3} = best_theta;  

end


%%
label_ratio_1 = sum(result_label == 1)/num_files
label_ratio_2 = sum(result_label == 2)/num_files
label_ratio_3 = sum(result_label == 3)/num_files
label_ratio_0 = sum(result_label == 0)/num_files

%% Find a good r.
r_list = zeros(num_files,1);
theta_list = zeros(num_files,1);
for i = 1:num_files
  r_list(i) = result_table_task_2{i+1,2};
  theta_list(i) = result_table_task_2{i+1,3};
end
idx_not_zero = r_list ~= 0;
r_mean = mean(r_list(idx_not_zero));
theta_mean = mean(theta_list(idx_not_zero));



%% Convert task 2 results to desired form.
template_task_2 = readtable(task_2_template_name, 'Format','%s%d');
n_2 = size(template_task_2,1);
d_car = 0.8; % Distance from the surface of the car to the center of it.

task_2 = cell(n_2+1,2);
task_2{1,1} = 'guid/image/axis';
task_2{1,2} = 'value';

none_list = zeros(n_2/2,1);

for i = 1:n_2/2
  if mod(i,100) == 0
    disp([num2str(i), ' / ', num2str(n_2/2)])
  end
  i_r = 2*i-1;
  i_t = 2*i;
  % File name entries.
  task_2{i_r+1,1} = template_task_2{i_r,1}{1};
  task_2{i_t+1,1} = template_task_2{i_t,1}{1};
  text_que = template_task_2{i_r,1}{1};
  text_que = text_que(1:end-2);
  % Find the results for this file.
  for j = 2:size(result_table_task_2,1)
    file_name = result_table_task_2{j,1};
    % Find by comparing file name.
    if contains(file_name, text_que)
      r = result_table_task_2{j, 2};
      theta = result_table_task_2{j, 3};
      if r ~= 0
        task_2{i_r+1,2} = r + d_car;
        task_2{i_t+1,2} = theta;
      else
        task_2{i_r+1,2} = 35; % mean 17.156;
        task_2{i_t+1,2} = theta_mean;
        none_list(i) = 1;
      end
      continue;
    end
  end
end

%% Write results to file.
writecell(result_table, task_1_result_name)
writecell(task_2, task_2_result_name)

