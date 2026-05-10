%初始调度种群生成 J工件相关信息，p为基于工序的编码 
% m为对应的机器编码  n为所选设备在对应可选设备集中的序列号
function [p,m,n]= initPop(J)
    p=[];%基于工序的编码
%     m(1:size(p,2))=0;%基于机器编码的染色体
    m=[];
    n=[];
    for i=1:size(J,2)%参与调度的工件数
        for j=1:J(i).a(1)%该工序的工序
            p(size(p,2)+1)=i;
        end
    end
    r=randperm(size(p,2));
    p=p(1,r);%生产有效的随机的基于工序编码
%-------------基于工序编码生成对应的基于机器的编码-------------%
    for i=1:size(J,2)
        f{i}=find(p==i);%找出工件i在工序染色体中所对应的序号
        for j=1:J(i).a(1)   %第i个工件的工序数
            k=f{i}(j);
            s=size(J(i).m{j},2);  %第i个工件第j道工序的可选机器数
            num=randperm(s,1);   %从1—s中随机选择一个数
            n(k)=num;   
            m(k)=J(i).m{j}(num);
%             m(f{i}(j))=J(i).m{j}(randperm(size(J(i).m{j},2),1));
        end
    end
end
