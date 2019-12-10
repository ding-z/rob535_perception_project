function label = class_id2label(id)
% Map a vector of class id to class labels. Relationship is as follow.
% 
% class_id	class_name	label
%     0     Unknown     0
%     1     Compacts	1
%     2     Sedans      1
%     3     SUVs        1
%     4     Coupes      1
%     5     Muscle      1
%     6     SportsClassics	1
%     7     Sports      1
%     8     Super       1

%     9     Motorcycles	3
%     10	OffRoad     3

%     11	Industrial	2
%     12	Utility     2
%     13	Vans        2

%     14	Cycles      3

%     15	Boats       0
%     16	Helicopters	0
%     17	Planes      0      

%     18	Service     2
%     19	Emergency	2
%     20	Military	2
%     21	Commercial	2

%     22	Trains      0

label = id;

label(id == 2) = 1;
label(id == 3) = 1;
label(id == 4) = 1;
label(id == 5) = 1;
label(id == 6) = 1;
label(id == 7) = 1;
label(id == 8) = 1;

label(id == 9) = 3;
label(id == 10) = 3;

label(id == 11) = 2;
label(id == 12) = 2;
label(id == 13) = 2;

label(id == 14) = 3;

label(id == 15) = 0;
label(id == 16) = 0;
label(id == 17) = 0;

label(id == 18) = 2;
label(id == 19) = 2;
label(id == 20) = 2;
label(id == 21) = 2;

label(id == 22) = 0;
