function rank_cell=conduct_extrinsic_test_impl(U, id, word, ...
                                               domikolov)
if narg < 4
    domikolov=1;
end
word_map=containers.Map(word, 1:length(word));
asd=1/0;
get_emb=@(wrd) U(word_map(lower(wrd)), :);
% % 1. Find the kendall tau correlation  coefficient 
% tic;
% ppdb_paraphrase_rating=create_ppdb_paraphrase_rating(...
%     getenv('PPDB_PARAPHRASE_RATING_FILENAME'),word);
% C1 = U(ppdb_paraphrase_rating(:,1),:);
% C2 = U(ppdb_paraphrase_rating(:,2),:);
% cosine_sim = sum(C1.*C2, 2);
% kc=corr(cosine_sim, ppdb_paraphrase_rating(:,3), 'type', ...
%              'Kendall');
% fprintf(1, 'Time taken %d\n', toc);

% fprintf(1, 'The Kendall Tau over %s is %f\n', id, kc);

% % 2. Find the swapped pair rate 
% fprintf(1, 'The Swapped Pair rate is %f in percentage\n', ...
%         ((1-kc)/2)*100);

% % 3. Find PEarson Correlation between juri and chris annotation and
% % cosine_sim between embeddings
% for corr_type = {'Pearson', 'Spearman'}
%     corr_type=corr_type{1};
%     fprintf(1, 'The %s Corr over %s is %f\n', corr_type, id, ...
%         corr(cosine_sim, ppdb_paraphrase_rating(:,3), 'type', ...
%              corr_type));
% end

% 4. Find the score on Toefl test
tic;
[n_total, n_attempt, n_correct]=toefl_test_impl(word, get_emb);
fprintf(1, 'The TOEFL score over %s with bare [%d, %d, %d] is %f\n', ...
        id, n_total, n_attempt, n_correct, n_correct/n_total);
fprintf(1, 'The TOEFL dataset over %s took %f minutes\n', id, toc/60);

% 5. Find the score on SCWS, RW, MEN, MC_30, EN_MTURK_287,
% EN_RG_65, EN_WS_353_(ALL/REL/SIM) datasets
for dataset={ 'SCWS', 'RW', 'MEN', 'EN_MC_30', 'EN_MTURK_287', 'EN_RG_65', ...
             'EN_WS_353_ALL', 'EN_WS_353_REL', 'EN_WS_353_SIM', 'SIMLEX' }
    dataset_fn=[dataset{1}, '_FILENAME'];
    disp(['Now working on ', dataset_fn]);
    [n_total, n_attempt, pred_simil, true_simil]=scws_test_impl(...
        word, get_emb, dataset_fn);
    tic;
    for corr_type = {'Pearson', 'Spearman'}
        corr_type=corr_type{1};
        correl=corr(pred_simil, true_simil, 'type', corr_type);
        fprintf(1, ['The %s %s correlation over %s (%d out of %d) ' ...
            'is %f \n'], dataset{1}, corr_type, id, n_attempt, n_total, ...
            correl);
    end
    fprintf(1, 'The %s dataset over %s took %f minutes\n', dataset{1}, ...
            id, toc/60);
end

%% 8. Find score on TOM_ICLR13_SEM and TOM_ICLR_SYN dataset
if domikolov
    for dataset = {'EN_TOM_ICLR13_SYN', 'EN_TOM_ICLR13_SEM'}
    tic;
    dataset_fn=[dataset{1}, '_FILENAME'];
    disp(['Now working on ', dataset_fn]);
    
    [n_total, n_attempt, n_correct_cosadd, n_correct_cosmul]=tom_test_impl(...
        word, word_map, get_emb, dataset_fn, U);
    
    fprintf(1, 'The %s dataset score over %s [%d, %d, %d, %d] is %f, %f \n',...
            dataset{1}, id, n_total, n_attempt, n_correct_cosadd, n_correct_cosmul, ... 
            n_correct_cosadd/n_attempt, n_correct_cosmul/n_attempt);
    fprintf(1, 'The %s dataset over %s took %f minutes\n', dataset{1}, ...
            id, toc/60);
    end
end
% 9. Use wordnet test
tic;
golden_paraphrase_map=create_golden_paraphrase_map(...
    getenv('WORDNET_TEST_FILENAME'),word);
[mrr rank_cell]=find_mrr(U, golden_paraphrase_map, word);
fprintf(1, 'The MRR (1 indexed) over %s is %f\n', id, mrr);
fprintf(1, 'Time taken %d\n', toc);



% for i=1:length(cosine_sim)
%     fprintf(1, '%s\t%s\t%f\t%d\n',...
%             word{ppdb_paraphrase_rating(i,1)}, ...
%             word{ppdb_paraphrase_rating(i,2)}, ...
%             cosine_sim(i), ...
%             ppdb_paraphrase_rating(i,3));
% end
% disp('finished printing the true ratings');
end