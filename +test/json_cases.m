function cases = json_cases()
% cases = test.json_cases()
% Shared corpus of MATLAB values used to exercise json.mdumps / json.mloads.
%
% Returns an Nx2 cell array: {name, value}. Used by test.test_json and by the
% v1 golden-fixture generator so both agree on what "the hard cases" are.

cases = {};

    function add(name, val)
        cases(end+1, :) = {name, val};
    end

%% ---- numeric scalars, every class -------------------------------------
add('double_scalar',        pi);
add('double_zero',          0);
add('double_neg_zero',      -0);
add('double_tiny',          realmin);
add('double_huge',          realmax);
add('double_third',         1/3);
add('single_scalar',        single(pi));
add('logical_true',         true);
add('logical_false',        false);
add('int8_scalar',          int8(-128));
add('uint8_scalar',         uint8(255));
add('int16_scalar',         int16(-32768));
add('uint16_scalar',        uint16(65535));
add('int32_scalar',         int32(-2147483648));
add('uint32_scalar',        uint32(4294967295));
add('int64_small',          int64(42));
add('int64_big',            int64(2^62) + int64(12345));
add('int64_min',            intmin('int64'));
add('uint64_big',           intmax('uint64'));

%% ---- non-finite values ------------------------------------------------
add('nan_scalar',           NaN);
add('inf_scalar',           Inf);
add('neginf_scalar',        -Inf);
add('nonfinite_mix',        [1 NaN Inf -Inf 2]);
add('all_nan_vector',       [NaN NaN NaN]);
add('nan_matrix',           [1 NaN; Inf -Inf]);
add('single_nonfinite',     single([NaN Inf -Inf 1.5]));

%% ---- numeric arrays and shapes ---------------------------------------
add('row_vector',           1:10);
add('col_vector',           (1:10)');
add('matrix_2d',            reshape(1:6, 2, 3));
add('matrix_3d',            reshape(1:24, 2, 3, 4));
add('matrix_4d',            reshape(1:16, 2, 2, 2, 2));
add('rand_10x10',           reshape(linspace(0, 1, 100), 10, 10));
add('logical_array',        logical([1 0 1; 0 1 0]));
add('uint8_matrix',         uint8(reshape(1:6, 3, 2)));
add('single_matrix',        single(reshape(1:6, 2, 3)));

%% ---- empties ----------------------------------------------------------
add('empty_double',         []);
add('empty_0x3',            zeros(0, 3));
add('empty_3x0',            zeros(3, 0));
add('empty_char',           '');
add('empty_cell',           {});
add('empty_cell_0x3',       cell(0, 3));
add('empty_logical',        false(0, 0));
add('empty_struct_fields',  struct('a', {}));
add('empty_int8',           int8([]));

%% ---- char -------------------------------------------------------------
add('char_row',             'a char array');
add('char_single',          'x');
add('char_matrix',          ['abc'; 'def']);
add('char_with_quotes',     'he said "hi" and \ backslash');
add('char_with_newline',    sprintf('line1\nline2\ttab'));
add('char_unicode',         'naïve café αβγ 日本語');
add('char_nan_literal',     'the value is NaN and Infinity');
add('char_json_looking',    '{"vals":1,"info":2}');

%% ---- string ----------------------------------------------------------
add('string_scalar',        "hello");
add('string_array',         ["a", "bb", "ccc"]);
add('string_2d',            reshape(["a" "b" "c" "d"], 2, 2));
add('string_empty_elem',    ["", "x"]);
add('string_empty_0x0',     strings(0, 0));
add('string_empty_0x3',     strings(0, 3));

%% ---- simple structs --------------------------------------------------
add('struct_simple',        struct('a', 1, 'b', 2));
add('struct_readme',        readme_example());
add('struct_nested_deep',   nested_deep(6));
add('struct_no_fields',     struct());
add('struct_field_type__',  struct('type__', 'collides with v1 sentinel', 'dim__', [1 2 3]));
add('struct_mixed_fields',  struct('num', pi, 'str', 'text', 'vec', 1:5, ...
                                   'mat', reshape(1:4, 2, 2), 'tf', true, ...
                                   'nothing', [], 'cel', {{1, 'two'}}));

%% ---- struct arrays ---------------------------------------------------
add('struct_arr_1x3',       struct('a', {1, 2, 3}));
add('struct_arr_3x1',       reshape(struct('a', {1, 2, 3}), 3, 1));
add('struct_arr_2x3',       reshape(struct('v', {1, 2, 3, 4, 5, 6}), 2, 3));
add('struct_arr_2fields',   struct('a', {1, 2}, 'b', {'x', 'yy'}));
add('struct_arr_nested',    struct('inner', {struct('q', 1), struct('q', 2)}));
add('struct_arr_ragged',    struct('m', {reshape(1:4, 2, 2), 7, []}));

%% ---- cell arrays ----------------------------------------------------
add('cell_scalars',         {1, 2, 3});
add('cell_strings',         {'one', 'two', 'three'});
add('cell_single',          {42});
add('cell_single_str',      {'only'});
add('cell_matrices',        {reshape(1:4, 2, 2), reshape(1:6, 2, 3)});
add('cell_same_len_mats',   {[1 2], [3 4]});
add('cell_of_cells',        {{1, 2}, {3, 4}});
add('cell_of_cell_cells',   {{{1, 2}, {3, 4}}, {{5, 6}, {7, 8}}});
add('cell_mixed',           {1, 'ab', [1 2 3], {4, 5}, struct('a', 1), true});
add('cell_2d',              {1, 'two'; [3 4], {5}});
add('cell_3d',              reshape({1, 2, 3, 4, 5, 6, 7, 8}, 2, 2, 2));
add('cell_with_empties',    {[], '', {}, 0});
add('cell_of_structs',      {struct('a', 1), struct('b', 2)});
add('cell_struct_same',     {struct('a', 1), struct('a', 2)});
add('cell_of_struct_arr',   {struct('a', {1, 2}), struct('a', {3, 4, 5})});
add('cell_nan',             {NaN, Inf, -Inf});
add('cell_nested_empty',    {{}, {{}}, {{{}}}});

%% ---- siblings that collapse into one N-D block ----------------------
% jsondecode folds a JSON array of equal-length arrays into a single N-D
% block. For arrays of objects that means a struct ARRAY, so a cell whose
% siblings are equal-length struct arrays with matching fields is the shape
% that breaks a reader handling only the numeric case. Unequal lengths or
% differing fields decode to a cell instead and are the easy path.
add('cell_equal_struct_arrs', {struct('a', {1, 2}), struct('a', {3, 4})});
add('cell_equal_struct_3',    {struct('a', {1, 2}), struct('a', {3, 4}), ...
                               struct('a', {5, 6})});
add('cell_equal_struct_2f',   {struct('a', {1, 2}, 'b', {'x', 'y'}), ...
                               struct('a', {3, 4}, 'b', {'p', 'q'})});
add('cell_cells_of_structs',  {{struct('a', 1), struct('a', 2)}, ...
                               {struct('a', 3), struct('a', 4)}});
add('cell_2x2_struct_arrs',   {reshape(struct('v', {1, 2, 3, 4}), 2, 2), ...
                               reshape(struct('v', {5, 6, 7, 8}), 2, 2)});
add('struct_of_equal_arrs',   struct('rows', {{struct('a', {1, 2}), ...
                               struct('a', {3, 4})}}));
add('cell_deep_struct_arrs',  {{struct('a', {1, 2}), struct('a', {3, 4})}, ...
                               {struct('a', {5, 6}), struct('a', {7, 8})}});

%% ---- deep / combined ------------------------------------------------
add('combo_1',              struct('lvl1', struct('lvl2', {{struct('lvl3', ...
                                {{1, 'a', [1 2; 3 4]}}), 'sibling'}})));
add('combo_2',              struct('data', {{reshape(1:6, 2, 3), 'label', ...
                                struct('meta', {{true, NaN}})}}, ...
                                'id', int64(2^55)));
add('combo_3',              struct('trials', reshape(struct('rt', {0.3, NaN, 1.2}, ...
                                'ok', {true, false, true}, ...
                                'tag', {'a', 'bb', ''}), 3, 1)));
add('combo_4',              {struct('a', {{}}), struct('a', {{{}}})});

end

%% ------------------------------------------------------------------------
function A = readme_example()
A.foo = 1;
A.bar.t = reshape(linspace(0, 1, 100), 10, 10);
A.bar.d = 'a char array';
A.nerf = 1:10;
end

function s = nested_deep(n)
s = struct('leaf', 'bottom');
for k = 1:n
    s = struct(sprintf('level%d', k), s);
end
end
