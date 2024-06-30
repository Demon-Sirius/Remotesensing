clc;
clear;
tic
%% 算法输入 
N = 500;
lake_data = imread("Blue.png");

med_length_width=17;%输入滤波核的长宽



med_length = med_length_width;
med_width = med_length_width;



% neighborSize = 10;
%% 对带有湖泊的影像进行超像素分隔
[L,numLabels] = superpixels(lake_data,N);
BW = boundarymask(L);
%获取各超像素间的邻接关系，这段跑得比较慢，可不用
% [Neighbors_SP,boundaries,neighbors_edge] = superpixelNeighbor(L,numLabels,neighborSize);  %获得各超像素相邻关系,用numLabels*neighborSize大小的矩阵表示
superpixel_types = zeros(numLabels,1); % 创建矩阵储存分类结果
se = strel('disk',3); %设置形态学算子

%% 由于所有分类均是以湖泊为参照物，因此在对超像素进行分类前，需先对湖泊进行分类。
% 对于一般问题可通过NDWI进行计算以提取水体，而在本数据中直接根据数据提取出水体
lake = lake_data(:,:,1) ~= 255; 
lakeNeighborSize = 20;
% % 使用bwlabel函数执行标签分析,这一段需要改
[label_lake, num_labels] = bwlabel(lake);
lakeNeighbors = lakeNeighbor(label_lake,L,num_labels,lakeNeighborSize);  %获得lake和超像素的相邻关系


%% 
lake_area = lake.*L;   
lake_label = unique(lake_area); 
superpixel_types(lake_label(2:end)) = 1;%用1表示A
%%
B_uni = unique (lakeNeighbors);
superpixel_types(B_uni(2:end)) = 2;%用2表示B
tabulated_B = tabulate(lakeNeighbors(lakeNeighbors ~= 0));
C_uni = tabulated_B(tabulated_B(:, 2) >= 2, 1);
superpixel_types(C_uni(2:end)) = 3;%用3表示C



%% 进行第二轮遍历，在该层遍历中先找出F
lake_ABC_all = zeros(size(lake),'like',lake); %首先需要对ABC的边界进行扩展，因此先生成一个逻辑矩阵
%创建一个逻辑数组，表示superpixel_types中是否等于'B'或'C'或'A'
is_ABC = find(ismember(superpixel_types, [1,2,3]));
%使用逻辑数组来获取所有'B'或'C'或'A'对应的point
index_ABC_all = ismember(L(:), is_ABC);

lake_ABC_all(index_ABC_all) = 1;
mask_ABC = imfill(lake_ABC_all,'holes'); %制作该掩膜用于将ABC内部区域扣除
%由于ABCDE五类元素均在ABC形成的缓冲区域中,因此可认为mask_ABC外的所有元素均可标记为F
mask_F = ~mask_ABC;
F_area = mask_F.*L;
F_uni = unique(F_area);
superpixel_types(F_uni(2:end)) = 6;%用6表示F

%% 进行第三轮遍历，由于D类标签在本题算法中是由B类标签转变而来，因此此时未被标记的超像素均为E类标签，同时对E类标签进行边界扩充
superpixel_types(find(superpixel_types == 0)) = 5;%用5表示E

% 若计算了superpixel，可尝试如下方法
% E_index = find(superpixel_types == 5);
% E_uni = Neighbors_SP(E_index);

% 若单纯只是为出图，可考虑如下算法
lake_E_all = zeros(size(lake),'like',lake);
is_E = find(ismember(superpixel_types, 5));
index_E_all = ismember(L,is_E);
lake_E_all(index_E_all) = 1;
lake_E_all = imfill(lake_E_all,'holes');
mask_E = imdilate(lake_E_all,se);
mask_E(index_E_all) = 0;
E_uni = mask_E.*L;

E_uni = unique(E_uni); %得到所有E类超像素周边的超像素序号
% is_B = find(superpixel_types) == 2; %找出属于B的点
% is_D = intersect(is_B,E_uni);  %寻找是B同时在D超像素周边的序号，即为D
% superpixel_types(is_D) = 4;  %用4表示D，即将在E周边的原本为B的超像素转化为D类超像素
superpixel_types(E_uni(2:end)) = 4;  %用4表示D，即将在E周边的原本为B的超像素转化为D类超像素

%% 对ABCD四类超像素进行边缘中值滤波平滑以生成合并区域T
lake_ABCD_all = zeros(size(lake),'like',lake); %首先需要对ABCD的边界进行扩展，因此先生成一个逻辑矩阵
%创建一个逻辑数组，表示superpixel_types中是否等于'B'或'C'或'A'或'D'
is_ABCD = find(ismember(superpixel_types, [1,2,3,4]));
%使用逻辑数组来获取所有'B'或'C'或'A'或'D'对应的point
index_ABCD_all = ismember(L,is_ABCD);
lake_ABCD_all(index_ABCD_all) = 1;
mask_ABCD = imfill(lake_ABCD_all,'holes'); %ABCD区域内所有超像素的二值化掩膜
T = medfilt2(mask_ABCD,[med_length med_width]);      %对其进行medfilt2操作，最终获得我们所需要的T区域
T_bw = bwmorph(T,'remove');         %获得其边界二值化图像

%% 遍历完全，展示分类结果


% 创建一个空白的 uint8 图像，用于存储填充后的结果
filled_image = uint8(zeros(size(lake_data)));

% 定义不同类型超像素的颜色映射
color_map = [
    uint8([150, 218, 241]);  % 类型1的颜色
    uint8([148, 148, 148]);  % 类型2的颜色
    uint8([1, 153, 67]);     % 类型3的颜色
    uint8([251, 254, 0]);    % 类型4的颜色
    uint8([1, 0, 250]);      % 类型5的颜色
    uint8([255, 255, 255])   % 类型6的颜色
];

% 根据超像素类型创建颜色矩阵
color_matrix = color_map(superpixel_types, :);

% 填充图像
filled_image = reshape(color_matrix(L(:), :), size(L, 1), size(L, 2), 3);
filled_image(BW) = 0; % 给超像素边界设置颜色

% 显示填充后的图像
figure
subplot(1, 2, 1)

% 创建图例的颜色示例
for label = 1:6
    color = color_map(label, :); % 获取对应标签的颜色
    plot(0, 0, 's', 'MarkerSize', 20, 'MarkerFaceColor', color, 'MarkerEdgeColor', color, 'DisplayName', char('A' + label - 1));
    hold on;
end

% 显示图例
lgd = legend('show');
set(lgd, 'NumColumns', 2); % 设置图例为2列

% 设置图例背景透明
set(lgd, 'Color', 'none');

% 调整图例中颜色块的长宽比为2:1
legend_color_boxes = findobj(lgd, 'Type', 'patch');
for i = 1:length(legend_color_boxes)
    set(legend_color_boxes(i), 'Position', get(legend_color_boxes(i), 'Position') + [0, 0, 0, -0.5]);
end

% 关闭坐标轴
axis off;
imshow(filled_image);
title("超像素分类结果图")

subplot(1, 2, 2)
T_lake = lake_data;
T_lake(T_bw) = 0;
imshow(T_lake);
imwrite(T_lake,'Tlake.png');
title("T边界图");
t1 = toc;
fprintf('计算时间：%f 秒\n',t1);
% t = [t;t1];
% end
% t_mean = mean(t);
% fprintf('平均计算时间为：%f 秒\n',t_mean);

