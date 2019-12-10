

%%
%files = dir('trainval/*/*_image.jpg');
%files = dir('C:\Users\zhding\Desktop\rob535_percention_data\data-2019\trainval/*/*_image.jpg');
files = dir('C:\Users\PC\Desktop\rob535_perception_data\data-2019\test/*/*_image.jpg');
%files = AllTrainData{1,3};

%idx = randi(numel(files));
idx_start = 1;
idx_end = 20;
for idx = idx_start:idx_end
    %idx = 137;%137;%7;
    snapshot = [files(idx).folder, '/', files(idx).name];
    %snapshot = files{idx};
    image_size = [1914, 1052];

    disp(snapshot)

    img = imread(snapshot);

    xyz = read_bin(strrep(snapshot, '_image.jpg', '_cloud.bin'));
    xyz = reshape(xyz, [], 3)';

    proj = read_bin(strrep(snapshot, '_image.jpg', '_proj.bin'));
    proj = reshape(proj, [4, 3])';

    uv = proj * [xyz; ones(1, size(xyz, 2))];
    uv = uv ./ uv(3, :);

    %%
    dist = vecnorm(xyz);
    idx_in = dist < 50;
    dist = vecnorm(xyz);
    %figure('Position', [10 10 2000 2000])
    figure(1)
    subplot(1,2,1)
    imshow(img)
    title(['image index: ', num2str(idx)])

    subplot(1,2,2)
    %clf()
    imshow(img)
    axis on
    hold on
    scatter(uv(1, idx_in), uv(2, idx_in), 1, 30*ones(size(uv(1, idx_in))), '.')
    scatter(uv(1, ~idx_in), uv(2, ~idx_in), 1, 90*ones(size(uv(1, ~idx_in))), '.')
    hold off

    set(gcf, 'position', [100, 100, 800, 400])
    
    label = waitforbuttonpress;
    
    Data{idx,1} = snapshot;
    Data{idx,2} = label;
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
