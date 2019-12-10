function [vx, vy] = get_vertices(box, scale)
% Return the vertices of a scaled (around the center) matlab format box 
% box           = [x_left_up, y_left_up, width, height]
% scale_box     = (e.g) 0.8

% [vx, vy]      = vertices of the scaled box, one vertex is repeated.

w_half = box(3)/2;
h_half = box(4)/2;

x_center = box(1) + w_half;
y_center = box(2) + h_half;

vx = [x_center - w_half*scale; % Left up.
      x_center - w_half*scale; % Left down.
      x_center + w_half*scale; % Right down.
      x_center + w_half*scale; % Right up.
      x_center - w_half*scale]; % Left up again.
    
vy = [y_center - h_half*scale; % Left up.
      y_center + h_half*scale; % Left down.
      y_center + h_half*scale; % Right down.
      y_center - h_half*scale; % Right up.
      y_center - h_half*scale]; % Left up again.      
      