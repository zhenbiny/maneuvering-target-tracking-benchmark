function [result, index] = find_algorithm_result(results, scheme_id)
%FIND_ALGORITHM_RESULT Locate one algorithm result by its identifier.

index = [];
result = struct();

for idx = 1:numel(results.algorithms)
    if strcmp(results.algorithms(idx).scheme_id, scheme_id)
        index = idx;
        result = results.algorithms(idx);
        return;
    end
end
end
