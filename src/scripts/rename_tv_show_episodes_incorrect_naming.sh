#!/bin/bash

while IFS= read -r line; do
  old_num=$(echo "$line" | sed -E 's/^([0-9]{2}),.*/\1/')
  new_num=$(echo "$line" | sed -E 's/.*,([0-9]{2})$/\1/')

  file_to_rename=(*$old_num*)
  new_filename="${file_to_rename/E$old_num/E$new_num}"
  mv "$file_to_rename" "${new_filename}_temp"
done <ep_renaming.txt

rename 's/_temp$//' *
rm ep_renaming.txt
