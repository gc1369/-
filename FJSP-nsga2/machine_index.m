%基于P,M,生成N
function N = machine_index(J,P,M)
    N=zeros(1,size(P,2));
    for i=1:size(J,2)
        pi_index=find(P==i);
        for j=1:size(pi_index,2)
             var=find(J(i).m{j}==M(pi_index(j)));
             N(pi_index(j))=var;
        end
    end
end

