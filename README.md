# index_toolkit
Some tools for work with indexes in Oracle DB

## Demo
```sql
declare
  -- Input data
  v_schema all_tables.owner%type := 'myschema'; -- Schema name
  v_table all_tables.table_name%type :=  'temp_table'; -- Table object name
  v_columns varchar2(4000) := 'col1, col2, col5'; -- Columns list separated by commas

  v_index_list varchar2(4000);
begin
  /**
   * Return list of index names separated by commas
   *
   * @param v_schema Schema name
   * @param v_table Table name
   * @param v_columns List of column names separated by commas
   * @return List of index names separated by commas
   */  
  v_index_list := index_toolkit.get_index_list(v_schema, v_table, v_columns);
  dbms_output.put_line(v_index_list);
  
  /**
   * Make indexes unused
   *
   * @param v_schema Schema name
   * @param v_index_list List of index names separated by commas
   */  
  index_toolkit.make_unused(v_schema, v_index_list);
  
  /**
   * Rebuild indexes
   *
   * @param v_schema Schema name
   * @param v_index_list List of index names separated by commas
   * @param v_flag_parallel Use parallel rebuild
   */  
  index_toolkit.make_rebuild(v_schema, v_index_list, TRUE);
exception
  when others then
    dbms_output.put_line('error: ' || dbms_utility.format_error_stack);
    dbms_output.put_line('stack: ' || dbms_utility.format_error_backtrace);
end;
```
