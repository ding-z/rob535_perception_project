function AllTrainData =  prepare_data(files, num_file_per_class, image_size)
%%
%files = dir('trainval/*/*_image.jpg');
%files = dir('C:\Users\zhding\Desktop\rob535_percention_data\data-2019\trainval/*/*_image.jpg');
%files = dir('C:\Users\PC\Desktop\rob535_perception_data\data-2019\trainval/*/*_image.jpg');
% Total training images: 5561
% Label_1: 2791
% Label_2: 1051
% Label_3: 138
% Label_0: 1581
%num_file_per_class = [1581; 2791; 1051; 138];
num_class = length(num_file_per_class);
num_total_file = sum(num_file_per_class);

% Use index "num_class" (last entry, 4 in the project) for the class 0.
i_label_0 = num_class;

% Initialize data organizer for data coresponding to each label.
% Format: {{file_name_of_label_1, box_of_label_1}, 
%          {file_name_of_label_2, box_of_label_2},
%          {file_name_of_label_3, box_of_label_3},
%          {file_name_of_label_0, empty}}
AllTrainData = {};
for i_cell = 1:num_class
    AllTrainData{i_cell} = cell(num_file_per_class(i_cell), 2);
end

            
%% Loop through each file, find 2D box, identify type, put in "AllTrainData".
i_class = [1, 1, 1, 1]; % Initialize index for file for each class.

for i_file = 1:num_total_file
    file_name = [files(i_file).folder, '/', files(i_file).name];
    xyz = read_bin(strrep(file_name, '_image.jpg', '_cloud.bin'));
    xyz = reshape(xyz, [], 3)';

    proj = read_bin(strrep(file_name, '_image.jpg', '_proj.bin'));
    proj = reshape(proj, [4, 3])';

    
    try
        bbox = read_bin(strrep(file_name, '_image.jpg', '_bbox.bin'));
    catch
        disp('[*] no bbox found.')
        bbox = single([]);

    end
    bbox = reshape(bbox, 11, [])';

    %uv = proj * [xyz; ones(1, size(xyz, 2))];
    %uv = uv ./ uv(3, :);
    
    has_valid_box = false;
    
    for k = 1:size(bbox, 1)
        ignore_in_eval = logical(bbox(k, 11));
        % If this is a good box (not ignore), then process.
        if ~ignore_in_eval
            has_valid_box = true;
            
            R = rot(bbox(k, 1:3));
            t = reshape(bbox(k, 4:6), [3, 1]);
            % Read 3D box.
            sz = bbox(k, 7:9);
            [vert_3D, ~] = get_bbox(-sz / 2, sz / 2);
            vert_3D = R * vert_3D + t;
            % 3D box in 2D.
            vert_2D = proj * [vert_3D; ones(1, size(vert_3D, 2))];
            vert_2D = vert_2D ./ vert_2D(3, :);
            % Handle out of image box and convert to matlab box format.
            [box_2d, vert_2D_fix] = get_2d_box(vert_2D, image_size);
            assert( sum(box_2d<=0) == 0)

            % Check the lable of the this box.
            c = int64(bbox(k, 10));
            label = class_id2label(c);
            
            
            % Store file name and the one box.
            AllTrainData{label}{i_class(label),1} = file_name;
            AllTrainData{label}{i_class(label),2} = box_2d;
            i_class(label) = i_class(label) + 1;
        end
    end
    
    % If no good box has been found, this image if of class 0.
    if ~has_valid_box
        AllTrainData{i_label_0}{i_class(i_label_0),1} = file_name;
        i_class(i_label_0) = i_class(4) + 1;
    end
    

end

end

%%
function [v, e] = get_bbox(p1, p2)
v = [p1(1), p1(1), p1(1), p1(1), p2(1), p2(1), p2(1), p2(1)
    p1(2), p1(2), p2(2), p2(2), p1(2), p1(2), p2(2), p2(2)
    p1(3), p2(3), p1(3), p2(3), p1(3), p2(3), p1(3), p2(3)];
e = [3, 4, 1, 1, 4, 4, 1, 2, 3, 4, 5, 5, 8, 8
    8, 7, 2, 3, 2, 3, 5, 6, 7, 8, 6, 7, 6, 7];
end

%%
function R = rot(n)
theta = norm(n, 2);
if theta
    n = n / theta;
    K = [0, -n(3), n(2); n(3), 0, -n(1); -n(2), n(1), 0];
    R = eye(3) + sin(theta) * K + (1 - cos(theta)) * K^2;
else
    R = eye(3);
end
end

%%
function data = read_bin(file_name)
id = fopen(file_name, 'r');
data = fread(id, inf, 'single');
fclose(id);
end

%%