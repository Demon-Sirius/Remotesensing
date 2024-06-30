clc;clear;
% 读取图像
image = imread('Tlake1.png');

% 提取蓝色连通分量
a = image(:,:,1);
b = image(:,:,2);
Ha = image(:,:,3);
labeled_image = image(:,:,3);
blue_components = image(:,:,3) == 128;
imshow(labeled_image);
% 连通分量标记
labeled_image = bwlabel(blue_components);

% 计算每个连通分量的面积
stats = regionprops(labeled_image, 'Area');

% 找到面积小于50的连通分量的索引
small_areas = find([stats.Area] < 150);
large_areas = find([stats.Area] >= 150);
% 将面积小于50的连通分量置为背景色
labeled_image(labeled_image == 0) = 255;
for i = 1:numel(small_areas)
    
    labeled_image(labeled_image == small_areas(i)) = 0;
    
  
end
for i = 1:numel(large_areas)
  
    labeled_image(labeled_image == large_areas(i)) = 255;
end

rgbImage = cat(3, a, b, labeled_image);
%imshow(rgbImage);
figure
% 找到黑色像素
black_pixels = rgbImage(:,:,1) == 0 & rgbImage(:,:,2) == 0 & rgbImage(:,:,3) == 0;
rgbImage(repmat(black_pixels,[1,1,3])) = 255;
% 将黑色像素转换为白色像素

c = rgbImage(:,:,1);
d = rgbImage(:,:,2);
e = rgbImage(:,:,3);
imshow(rgbImage);
imwrite(rgbImage,'Test.png');
% else
%     disp('图片中没有黑色像素。');
% end
