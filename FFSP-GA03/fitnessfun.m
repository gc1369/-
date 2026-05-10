%适应度函数，输入种群，输出种群适应值和最大完工时间行向量
function [fitvalue_v,max_finish_v,energySum_v] = fitnessfun(pop)
    global n pop_size % 种群数
    for i=1:pop_size
        [max_finish_v(i),energySum_v(i),~,~,~] = decode(pop((i-1)*n+1:i*n,:));
        %切片处理，解码个体individual
        fitvalue_v(i) = 0.8*max_finish_v(i) + 0.2*energySum_v(1,i); 
        % fitvalue1=1:12, f2=13:24
        % fitvalue_v行向量，储存pop个种群的适应值
    end
end

