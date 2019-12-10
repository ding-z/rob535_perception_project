function [box_2d, vert_2D_fix] = get_2d_box(vert_2D, image_size)
%% convert 2D box (8 points) to matlab box (x,y,width,height) while handling 
% out of image.

% Point indices correspondence. Left-Right.
% [8 6]
% [4 2]
% [7 5]
% [3 1]
% Map from 1 2 3 4 5 6 7 8
idx_lr =  [3 4 1 2 7 8 5 6];

% Up-down.
% [6 5]
% [2 1]
% [8 7]
% [4 3]
% Map from 1 2 3 4 5 6 7 8
idx_ud =  [2 1 4 3 6 5 8 7];


vert_2D_fix = vert_2D;

% Handle out of image box.
% Left side out.
idx_out = find(vert_2D_fix(1,:) < 1 );
for i = idx_out
    j = idx_lr(i);
    x0 = vert_2D_fix(1,i);
    x1 = vert_2D_fix(1,j);
    y0 = vert_2D_fix(2,i);
    y1 = vert_2D_fix(2,j);

    % Compute new x, y.
    x2 = 1;
    y2 = (y1 - y0)*(x2 - x0)/(x1 - x0) + y0;
    % Update x, y.
    vert_2D_fix(1,i) = x2;
    vert_2D_fix(2,i) = y2;
end

% Right side out.
idx_out = find(vert_2D_fix(1,:) > image_size(1));
for i = idx_out
    j = idx_lr(i);
    x0 = vert_2D_fix(1,i);
    x1 = vert_2D_fix(1,j);
    y0 = vert_2D_fix(2,i);
    y1 = vert_2D_fix(2,j);

    % Compute new x, y.
    x2 = image_size(1);
    y2 = (y1 - y0)*(x2 - x0)/(x1 - x0) + y0;
    % Update x, y.
    vert_2D_fix(1,i) = x2;
    vert_2D_fix(2,i) = y2;
end

% Up side out.
idx_out = find(vert_2D_fix(2,:) < 1);
for i = idx_out
    j = idx_ud(i);
    x0 = vert_2D_fix(1,i);
    x1 = vert_2D_fix(1,j);
    y0 = vert_2D_fix(2,i);
    y1 = vert_2D_fix(2,j);

    % Compute new x, y.
    y2 = 1;
    x2 = (x1 - x0)*(y2 - y0)/(y1 - y0) + x0;
    % Update x, y.
    vert_2D_fix(1,i) = x2;
    vert_2D_fix(2,i) = y2;
end

% Down side out.
idx_out = find(vert_2D_fix(2,:) > image_size(2));
for i = idx_out
    j = idx_ud(i);
    x0 = vert_2D_fix(1,i);
    x1 = vert_2D_fix(1,j);
    y0 = vert_2D_fix(2,i);
    y1 = vert_2D_fix(2,j);

    % Compute new x, y.
    y2 = image_size(2);
    x2 = (x1 - x0)*(y2 - y0)/(y1 - y0) + x0;
    % Update x, y.
    vert_2D_fix(1,i) = x2;
    vert_2D_fix(2,i) = y2;
end

% Convert 2D box to matlab box format.
box_x = min(vert_2D_fix(1,:));
box_y = min(vert_2D_fix(2,:));
width_x = max(vert_2D_fix(1,:)) - min(vert_2D_fix(1,:));
height_y = max(vert_2D_fix(2,:)) - min(vert_2D_fix(2,:));
box_2d = [ceil(box_x), ceil(box_y), floor(width_x), floor(height_y)];
end

