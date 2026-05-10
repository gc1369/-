%% 对初始种群开始排序 快速非支配排序
% 使用非支配排序对种群进行排序。该函数返回每个个体对应的排序值和拥挤距离，是一个两列的矩阵。  
% 并将排序值和拥挤距离添加到染色体矩阵中 
%x：决策矩阵  M：优化目标数量 V：决策变量个数
function [p_matrix,m_matrix] = non_domination_sort_mod(pro_matrix,mac_matrix)
    [N, ~] = size(pro_matrix);% N为矩阵x的行数，也是种群的数量
    M=4;%优化目标数量
    V=size(pro_matrix,2)-M;%决策变量个数
    front = 1;
    F(front).f = [];%记录paret  o解集等级为front级的个体集合
    individual = [];%用于存放被某个个体支配的个体集合

    for i = 1 : N
        individual(i).n = 0;%n是个体i被支配的个体数量
        individual(i).p = [];%p是被个体i支配的个体集合
        for j = 1 : N
            dom_less = 0;
            dom_equal = 0;
            dom_more = 0;
            for k = 1 : M        %判断个体i和个体j的支配关系
                if (pro_matrix(i,V + k) < pro_matrix(j,V + k))  
                    dom_less = dom_less + 1;
                elseif (pro_matrix(i,V + k) == pro_matrix(j,V + k))
                    dom_equal = dom_equal + 1;
                else
                    dom_more = dom_more + 1;
                end
            end
            if dom_less == 0 && dom_equal ~= M % 说明i受j支配，相应的n加1
                individual(i).n = individual(i).n + 1;
            elseif dom_more == 0 && dom_equal ~= M % 说明i支配j,把j加入i的支配合集中
                individual(i).p = [individual(i).p j];
            end
        end   
        if individual(i).n == 0 %个体i非支配等级排序最高，属于当前最优解集，相应的染色体中携带代表排序数的信息
            pro_matrix(i,M + V + 1) = 1;
            F(front).f = [F(front).f i];%等级为1的非支配解集
        end
    end
%上面的代码是为了找出等级最高的非支配解集
%下面的代码是为了给其他个体进行分级
    while ~isempty(F(front).f)
       Q = []; %存放下一个front集合
       for i = 1 : length(F(front).f)%循环当前支配解集中的个体
           if ~isempty(individual(F(front).f(i)).p)%个体i有自己所支配的解集
                for j = 1 : length(individual(F(front).f(i)).p)%循环个体i所支配解集中的个体
                    individual(individual(F(front).f(i)).p(j)).n = ...%...表示的是与下一行代码是相连的，这里表示个体j的被支配个数减1
                        individual(individual(F(front).f(i)).p(j)).n - 1;
                     if individual(individual(F(front).f(i)).p(j)).n == 0% 如果q是非支配解集，则放入集合Q中
                        pro_matrix(individual(F(front).f(i)).p(j),M + V + 1) = ...%个体染色体中加入分级信息
                            front + 1;
                        Q = [Q individual(F(front).f(i)).p(j)];
                    end
                end
           end
       end
       front =  front + 1;
       F(front).f = Q;
    end

    [~,index_of_fronts] = sort(pro_matrix(:,M + V + 1));%对个体的代表排序等级的列向量进行升序排序 temp为排序完成的列 index_of_fronts表示排序后的值对应原来的索引
    for i = 1 : length(index_of_fronts)
        sorted_based_on_front(i,:) = pro_matrix(index_of_fronts(i),:);%sorted_based_on_front中存放的是x矩阵按照排序等级升序排序后的矩阵
        m_matrix(i,:)=mac_matrix(index_of_fronts(i),:);
    end
    current_index = 0;

    %% Crowding distance 计算每个个体的拥挤度

    for front = 1:(length(F) - 1)%这里减1是因为代码55行这里，F的最后一个元素为空，这样才能跳出循环。所以一共有length-1个排序等级
        distance = 0;
        y = [];
        previous_index = current_index + 1;
        for i = 1 : length(F(front).f)
            y(i,:) = sorted_based_on_front(current_index + i,:);%y中存放的是排序等级为front的集合矩阵
%           z(i,:) = mac_sorted_based(current_index+i,:);%z中存放是等级为front的对应的加工设备集合矩阵
        end
        current_index = current_index + i;%current_index =i
        sorted_based_on_objective = [];%存放基于拥挤距离排序的矩阵
        for i = 1 : M
            [sorted_based_on_objective, index_of_objectives] = ...
                sort(y(:,V + i));%按照目标函数值排序
            sorted_based_on_objective = [];
            for j = 1 : length(index_of_objectives)
                sorted_based_on_objective(j,:) = y(index_of_objectives(j),:);% sorted_based_on_objective存放按照目标函数值排序后的x矩阵
%                 mac_sorted_matrix(j,:)=z(index_of_objectives(j),:)
            end
            f_max = ...
                sorted_based_on_objective(length(index_of_objectives), V + i);%fmax为目标函数最大值 fmin为目标函数最小值
            f_min = sorted_based_on_objective(1, V + i);
            y(index_of_objectives(length(index_of_objectives)),M + V + 1 + i)...%对排序后的第一个个体和最后一个个体的距离设为无穷大
                = inf;
            y(index_of_objectives(1),M + V + 1 + i) = inf;
             for j = 2 : length(index_of_objectives) - 1%循环集合中除了第一个和最后一个的个体
                next_obj  = sorted_based_on_objective(j + 1,V + i);
                previous_obj  = sorted_based_on_objective(j - 1,V + i);
                if (f_max - f_min == 0)
                    y(index_of_objectives(j),M + V + 1 + i) = inf;
                else
                    y(index_of_objectives(j),M + V + 1 + i) = ...
                         (next_obj - previous_obj)/(f_max - f_min);
                end
             end
        end
        distance = [];
        distance(:,1) = zeros(length(F(front).f),1);
        for i = 1 : M
            distance(:,1) = distance(:,1) + y(:,M + V + 1 + i);
        end
        y(:,M + V + 2) = distance;
        y = y(:,1 : M + V + 2);
        p_matrix(previous_index:current_index,:) = y;
    end
end
