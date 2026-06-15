function order = rank_tuning_summaries(summaries)
%RANK_TUNING_SUMMARIES Sort candidate summaries by their score vectors.

score_matrix = zeros(numel(summaries), numel(summaries(1).score_vector));
for idx = 1:numel(summaries)
    score_matrix(idx, :) = summaries(idx).score_vector;
end

[~, order] = sortrows(score_matrix);
end
