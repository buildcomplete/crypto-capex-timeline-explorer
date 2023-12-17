% Function to save
function table = save_table (x, y, filename, header1, header2)

  % Output the cell array as a markdown table to a file
  file_id = fopen (filename, 'w');
  fprintf(file_id, '|%s|%s|\n', header1, header2);
  fprintf(file_id, '|---|---|\n');

  for i = 1:size(x(:),1)
    fprintf (file_id, '|%s|%f|\n', datestr(x(i)), y(i));
  endfor

  fclose (file_id);

endfunction

