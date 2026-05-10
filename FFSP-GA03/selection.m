%% 输入种群和fitvalue_v适应度向量　　竞标赛选择法，输出ｄａｄ和ｍｏｍ
function [dad,mom] = selection(pop,fitvalue_v)
    tour = 4; % 参赛选手个数popsize的10%-40%之间
    global n pop_size;
    for i=1:pop_size
        r = randi([1 pop_size],tour,1); %随机选择4个进行比较
        [~,bestindex] = min(fitvalue_v(r)); % 找到最小的种群索引
        dad((i-1)*n+1:i*n,:) = pop((r(bestindex)-1)*n+1:r(bestindex)*n,:); % 把最小个体复制给dad
        mom_index = randi([1 pop_size]);
        mom((i-1)*n+1:i*n,:) = pop((mom_index-1)*n+1:mom_index*n,:);%mom随机选择一个
    end
end