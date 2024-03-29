function demo()
classes = {'Unknown', 'Compacts', 'Sedans', 'SUVs', 'Coupes', ...
    'Muscle', 'SportsClassics', 'Sports', 'Super', 'Motorcycles', ...
    'OffRoad', 'Industrial', 'Utility', 'Vans', 'Cycles', ...
    'Boats', 'Helicopters', 'Planes', 'Service', 'Emergency', ...
    'Military', 'Commercial', 'Trains'};

%%
%files = dir('trainval/*/*_image.jpg');
%files = dir('C:\Users\zhding\Desktop\rob535_percention_data\data-2019\trainval/*/*_image.jpg');
files = dir('C:\Users\PC\Desktop\rob535_perception_data\data-2019\trainval/*/*_image.jpg');
idx = randi(numel(files));
snapshot = [files(idx).folder, '/', files(idx).name];
disp(snapshot)

img = imread(snapshot);

xyz = read_bin(strrep(snapshot, '_image.jpg', '_cloud.bin'));
xyz = reshape(xyz, [], 3)';

proj = read_bin(strrep(snapshot, '_image.jpg', '_proj.bin'));
proj = reshape(proj, [4, 3])';

try
    bbox = read_bin(strrep(snapshot, '_image.jpg', '_bbox.bin'));
catch
    disp('[*] no bbox found.')
    bbox = single([]);
end
bbox = reshape(bbox, 11, [])';

uv = proj * [xyz; ones(1, size(xyz, 2))];
uv = uv ./ uv(3, :);

%%
dist = vecnorm(xyz);
figure(1)
clf()
imshow(img)
axis on
hold on
scatter(uv(1, :), uv(2, :), 1, dist, '.')

set(gcf, 'position', [100, 100, 800, 400])

%%
figure(2)
clf()
pcshow(xyz.', dist)
hold on
axis equal
axis([-50, 50. -40, 10, -10, 90])
xlabel('x')
ylabel('y')
zlabel('z')
view(gca, [-30, 15])

colors = [
    0, 0.4470, 0.7410
    0.8500, 0.3250, 0.0980
    0.9290, 0.6940, 0.1250
    0.4940, 0.1840, 0.5560
    0.4660, 0.6740, 0.1880
    0.3010, 0.7450, 0.9330
    0.6350, 0.0780, 0.1840
];

for k = 1:size(bbox, 1)
    R = rot(bbox(k, 1:3));
    t = reshape(bbox(k, 4:6), [3, 1]);

    sz = bbox(k, 7:9);
    [vert_3D, edges] = get_bbox(-sz / 2, sz / 2);
    vert_3D = R * vert_3D + t;

    vert_2D = proj * [vert_3D; ones(1, size(vert_3D, 2))];
    vert_2D = vert_2D ./ vert_2D(3, :);

    clr = colors(mod(k - 1, size(colors, 1)) + 1, :);
    for i = 1:size(edges, 2)
        e = edges(:, i);

        figure(1)
        plot(vert_2D(1, e), vert_2D(2, e), 'color', clr)

        figure(2)
        plot3(vert_3D(1, e), vert_3D(2, e), vert_3D(3, e), 'color', clr)
    end

    t = double(t);  % only needed for `text()`
    c = classes{int64(bbox(k, 10)) + 1};
    ignore_in_eval = logical(bbox(k, 11));
    if ignore_in_eval
        text(t(1), t(2), t(3), c, 'color', 'r')
    else
        text(t(1), t(2), t(3), c)
    end
end

%%
figure(2)
I = eye(3);
for k = 1:3
    plot3([0, I(1, k)], [0, I(2, k)], [0, I(3, k)], 'color', I(:, k))
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
