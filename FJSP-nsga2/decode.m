%贪婪解码算法  J为参与调度的工件的所有信息  P为调度方案的基于工序编码的染色体 
% M为调度方案的基于机器编码的染色体  N为所选设备在对应可选设备集中的序列号
%part_t为对应工件各工序加工时间信息  mac_t为对应设备各工序加工时间信息
function [part_t,mac_t,span]= decode(J,P,M,N)
    part_t=cell(size(J,2));%加工零件的加工时间
    mac_t=cell(J(1).num_mac);%对应设备加工时间
    [~,total_n]=size(P);%total_n为总工序数
    part_n=size(J,2);
    k_part=zeros(1,part_n);%记录当前解码过程中工件的工序号（一行工件数的全0数组）
    k_mac=zeros(1,J(1).num_mac);%记录当前解码过程中该到工序在该设备中待加工序号
    t_span=cell(1);%记录该所有设备加工间隙
    tete=zeros(J(1).num_mac,300);
%     k_N=zeros(1,part_n);
    for i=1:total_n
        p_var=P(i);%染色体中第i个基因所对应的工件
        m_var=M(i);%染色体中第i个基因所对应的加工设备
        n_var=N(i);%该基因所选设备在可选设备集中的序号
        k_part(p_var)=k_part(p_var)+1;  %在加工工件0变1、2、3
        k_mac(m_var)=k_mac(m_var)+1;    %在使用机器0变1、2、3
%       m_span{m_var}  %第m_var台设备当前所存在的加工间隙
        pro_time=J(p_var).t{k_part(p_var)}(n_var);%该道工序所需加工时间
        %确定该工序开始的加工时间
        %基于工件的约束
        if k_part(p_var)>1
            start_t_p=part_t{p_var}(k_part(p_var)-1,2);
        else
            start_t_p=0;
        end
        %基于加工设备的约束
        if k_mac(m_var)>1
            start_t_m=max(mac_t{m_var}(:,2));
        else
            start_t_m=0;
        end
        %判断最终约束
        if start_t_p>=start_t_m
            start_t=start_t_p;
            %不发生前插时的，设备间隙矩阵
            if k_mac(m_var)>1
                t_span{m_var}(k_mac(m_var),:)=[mac_t{m_var}(k_mac(m_var)-1,2),start_t];%第m_var个元胞
            else
                t_span{m_var}(k_mac(m_var),:)=[0,start_t];
            end
        else 
              span=t_span{m_var}(:,2)-t_span{m_var}(:,1);%元胞数组对应机器集的2列－1列
            req_span=intersect(find(span>=pro_time),find(t_span{m_var}(:,2)>=start_t_p+pro_time)); %可以进行插入的位置
              if size(req_span,1)>=1&&size(req_span,2)
                var=req_span(1); 
                midd=max(start_t_p,t_span{m_var}(var,1));
                if (tete(m_var,midd+1:midd+1+pro_time)==0)%判断机器加工状态是否
                   start_t=midd;
                   t_span{m_var}(k_mac(m_var),:)=[start_t+pro_time,t_span{m_var}(var,2)];%更新插入产生的新间隙
                   t_span{m_var}(var,2)=start_t;%更新插入后对已有间隙的影响
                   t_span{m_var}=sortrows(t_span{m_var},1);
                else
                     start_t=start_t_m;
                end
             else
                start_t=start_t_m;
                t_span{m_var}(k_mac(m_var),:)=[start_t,start_t];
             end
        end  
        stop_t=start_t+pro_time;
        tete(m_var,start_t+1:stop_t+1)=1;%更新机器上加工状态为1
        part_t{p_var}(k_part(p_var),:)=[start_t,stop_t];
        mac_t{m_var}(k_mac(m_var),:)=[start_t,stop_t];
       % mac_t{m_var}=sortrows(mac_t{m_var},2);%更新机器时间，以机器完工时间升序排列
    end
end



