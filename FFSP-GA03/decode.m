%解码，输入pop,输出max_finish,end_time，start_time
function [max_finish,energySum,end_time,start_time,mac_Jn] = decode(individual) % individual为个体
global time K m n power; 
 % 初始化矩阵和数组
    end_time = zeros(n,m); %储存每个工序结束时间
    start_time = zeros(n,m);  %储存每个工序开始时间  
    mac_Jn = cell(m,max(K)); %储存第i工件第J机器上加工的工件顺序
    energySum = 0; % 累计能耗
    %% 求第一道工序的加工时间
    M = 1; % 共mac_nb台机器   
    for k = 1:K(1) % 第一道工序1到3的机器编号       
        mac_Jn{1,k} = find(floor(individual(:,1))== k ); % 找到第一列使用机器k的索引      
        if mac_Jn{1,k} ~=0  % 如果索引存在     
            
            for i=1:length(mac_Jn{1,k})
                energySum = energySum + power(mac_Jn{1,k}(i),k); % 计算累计能耗
            end            
            
            [~,ind11] = sort(individual(mac_Jn{1,k})- k);% 取小数部分排列，只保留了排列ind11
            mac_Jn{1,k} = mac_Jn{1,k}(ind11);%使用排序后的索引重新排列mac_Jn——ij，以反映排序后的顺序
            end_time(mac_Jn{1,k}(1),1)=time(mac_Jn{1,k}(1),k);
            %根据索引找到时间，将机器1上第一个工序的加工时间赋值给 end_time，end_time为列向量        
            for i=2:length(mac_Jn{1,k}) % 从2到采用了第i工序的第j机器的工件总数 即L_jk
                end_time(mac_Jn{1,k}(i),1) = end_time(mac_Jn{1,k}(i-1),1)+time(mac_Jn{1,k}(i),k);
                %上一个工件的加工时间加上当前工件在当前机器上的加工时间=结束时间，并将结果存储在 end_time 中
                start_time(mac_Jn{1,k}(i),1) = end_time(mac_Jn{1,k}(i),1) - time(mac_Jn{1,k}(i),k); % 开始时间为本工件结束时间-加工时间
            end                     
        end
        M = M+1; % 第几台机器   
    end    
    
    %% 求第二道及以后p2-m工序的加工时间
    %工序P2共有K2个机器pm有km个机器
    for j = 2:m % 第二道及以后p2-m工序
        for k = 1:K(j) % K(m)
            mac_Jn{j,k} = find(floor(individual(:,j))== M);
            if mac_Jn{j,k}~=0              
                
            for i=1:length(mac_Jn{j,k})
                energySum = energySum + power(mac_Jn{j,k}(i),M); % 计算累计能耗
            end               
            
                [~,ind21] = sort(end_time(mac_Jn{j,k},j-1));
                % 取小数部分排列，只保留了排列ind21
                mac_Jn{j,k} = mac_Jn{j,k}(ind21); % 使用ind21对macjnjk排序
                end_time(mac_Jn{j,k}(1),j) = time(mac_Jn{j,k}(1),M)+end_time(mac_Jn{j,k}(1),j-1);
                for i=2:length(mac_Jn{j,k})
                    if end_time(mac_Jn{j,k}(i-1),j)>end_time(mac_Jn{j,k}(i),j-1)%第2工序改为j
                        % 判断前一个工件在第二道工序中的加工结束时间是否大于当前工件在第二道工序中的开始加工时间。 
                        end_time(mac_Jn{j,k}(i),j)= end_time(mac_Jn{j,k}(i-1),j)+time(mac_Jn{j,k}(i),M);
                        %如果前一个工件尚未加工完，则当前工件的加工时间从前一个工件的结束时间开始
                    else
                        end_time(mac_Jn{j,k}(i),j) = end_time(mac_Jn{j,k}(i),j-1) + time(mac_Jn{j,k}(i),M);
                         %如果前一个工件已经加工完，则当前工件的加工时间从当前工件在第一道工序中的加工结束时间开始
                    end            
                end
                for i=1:length(mac_Jn{j,k})
                     start_time(mac_Jn{j,k}(i),j) = end_time(mac_Jn{j,k}(i),j) - time(mac_Jn{j,k}(i),M);%222
                end
            end
            M = M+1;
        end   
    end
    %% 输出
    max_finish = max(end_time(:,end)); % 最大完工时间   
    end_time;%结束时间
    start_time;%开始时间
    mac_Jn;%二维单元数组储存机器上工件加工顺序
    energySum; % 累计能耗
end