% 继续使用你的K均值聚类结果
pixel_labels = imsegkmeans(ab,numColors,NumAttempts=3);

% 初始化一个新的RGB图像，默认所有像素为白色
segmentedImage = 255 * ones(size(he, 1), size(he, 2), 3, 'uint8');

% 假设聚类1代表陆地，将其设为蓝色
% 蓝色在RGB中表示为[0, 255, 0]
segmentedImage(repmat(pixel_labels==1, [1, 1, 3])) = repmat(uint8([0, 0, 255]), sum(pixel_labels==1), 1);

% 假设聚类2代表海水，保持为白色，无需更改
% 如果需要明确设置（例如，如果初始图像不是全白色的），可以取消注释下面的代码
% segmentedImage(repmat(pixel_labels==2, [1, 1, 3])) = repmat(uint8([255, 255, 255]), sum(pixel_labels==2), 1);

% 显示着色后的图像
figure;
imshow(segmentedImage);
title('Segmented Image with Land in Blue and Water in White');

% 保存着色后的图像
imwrite(segmentedImage, 'segmented_image_colored.png');

