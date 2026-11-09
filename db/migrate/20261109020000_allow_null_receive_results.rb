# Version 1.2 of the consent drops the question about receiving the study's results by email; participants download
# their own progress from Settings instead. Version 1.1 rows keep their answer, version 1.2 rows leave it empty.
class AllowNullReceiveResults < ActiveRecord::Migration[8.1]
  def change
    change_column_null :consents, :receive_results, true
  end
end
