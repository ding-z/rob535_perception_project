function AllTestData =  prepare_data_test(files)
%%
%files = dir('trainval/*/*_image.jpg');
%files = dir('C:\Users\zhding\Desktop\rob535_percention_data\data-2019\trainval/*/*_image.jpg');
%files = dir('C:\Users\PC\Desktop\rob535_perception_data\data-2019\trainval/*/*_image.jpg');
% Total training images: 5561
% Label_1: 2791
% Label_2: 1051
% Label_3: 138
% Label_0: 1581
num_total_file = length(files);



% Initialize data organizer for data coresponding to each label.
% Format:  {file_name_of_label_0, empty}
AllTestData = cell(num_total_file, 2);


            
%% Loop through each file, find 2D box, identify type, put in "AllTrainData".

for i_file = 1:num_total_file
    file_name = [files(i_file).folder, '/', files(i_file).name];

    AllTestData{i_file,1} = file_name;


end

end


%%